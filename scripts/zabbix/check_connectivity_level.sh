#!/bin/bash

# Script de monitoramento de conectividade para Zabbix
# Versão: 2.0
# Verifica diferentes níveis de conectividade de rede e reporta para o Zabbix

# Configurações
ZBX_HOST="Link - Internet"
ZBX_SERVER="172.18.0.3"
LOG_FILE="/var/log/connectivity_check.log"

# Parâmetros de configuração
PING_COUNT=3             # Número de pacotes para enviar no ping
PING_TIMEOUT=2           # Timeout do ping em segundos
CURL_TIMEOUT=5           # Timeout do curl em segundos
MAX_RETRIES=2            # Número máximo de tentativas por teste

# Servidores de teste (para redundância)
GATEWAYS=$(ip route | awk '/default/ {print $3}')
DNS_SERVERS=("8.8.8.8" "1.1.1.1")
TEST_URLS=("https://www.google.com" "https://www.cloudflare.com" "https://www.microsoft.com")

# Função para logging
log_msg() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message"
}

# Função para enviar dados para o Zabbix
send_to_zabbix() {
    local level=$1
    local description=$2
    
    log_msg "INFO" "Enviando status para o Zabbix: Nível $level - $description"
    
    zabbix_sender -z "$ZBX_SERVER" -s "$ZBX_HOST" -k check.connectivity.level -o "$level"
    
    if [ $? -ne 0 ]; then
        log_msg "ERROR" "Falha ao enviar dados para o servidor Zabbix $ZBX_SERVER"
        return 1
    else
        log_msg "INFO" "Dados enviados com sucesso para o Zabbix"
        return 0
    fi
}

# Testa conectividade com o gateway
test_gateway() {
    log_msg "INFO" "Testando conectividade com o gateway..."
    
    for gateway in $GATEWAYS; do
        log_msg "INFO" "Testando gateway: $gateway"
        
        for ((retry=0; retry<MAX_RETRIES; retry++)); do
            if ping -c$PING_COUNT -W$PING_TIMEOUT "$gateway" > /dev/null 2>&1; then
                log_msg "INFO" "Gateway $gateway está acessível"
                return 0
            else
                log_msg "WARN" "Falha na tentativa $((retry+1)) de $MAX_RETRIES para gateway $gateway"
            fi
        done
    done
    
    log_msg "ERROR" "Nenhum gateway respondeu"
    send_to_zabbix 0 "Sem conexão com o gateway - Link caiu"
    exit 0
}

# Testa conectividade com servidores DNS
test_dns_servers() {
    log_msg "INFO" "Testando conectividade com servidores DNS..."
    
    for dns in "${DNS_SERVERS[@]}"; do
        log_msg "INFO" "Testando servidor DNS: $dns"
        
        for ((retry=0; retry<MAX_RETRIES; retry++)); do
            if ping -c$PING_COUNT -W$PING_TIMEOUT "$dns" > /dev/null 2>&1; then
                log_msg "INFO" "Servidor DNS $dns está acessível"
                return 0
            else
                log_msg "WARN" "Falha na tentativa $((retry+1)) de $MAX_RETRIES para DNS $dns"
            fi
        done
    done
    
    log_msg "ERROR" "Nenhum servidor DNS respondeu"
    send_to_zabbix 1 "Gateway responde, mas sem acesso a DNS externos"
    exit 0
}

# Testa resolução de DNS
test_dns_resolution() {
    log_msg "INFO" "Testando resolução de DNS..."
    
    for ((retry=0; retry<MAX_RETRIES; retry++)); do
        if nslookup google.com > /dev/null 2>&1; then
            log_msg "INFO" "Resolução de DNS funcionando corretamente"
            return 0
        else
            log_msg "WARN" "Falha na tentativa $((retry+1)) de $MAX_RETRIES para resolução DNS"
        fi
    done
    
    log_msg "ERROR" "Resolução de DNS falhou"
    send_to_zabbix 2 "Servidores DNS acessíveis, mas resolução falha"
    exit 0
}

# Testa acesso HTTP
test_http_access() {
    log_msg "INFO" "Testando acesso HTTP..."
    
    for url in "${TEST_URLS[@]}"; do
        log_msg "INFO" "Testando URL: $url"
        
        for ((retry=0; retry<MAX_RETRIES; retry++)); do
            # Verifica código de resposta HTTP e conteúdo
            http_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $CURL_TIMEOUT "$url")
            
            if [ "$http_response" == "200" ] || [ "$http_response" == "301" ] || [ "$http_response" == "302" ]; then
                log_msg "INFO" "URL $url respondeu com código HTTP $http_response"
                return 0
            else
                log_msg "WARN" "Falha na tentativa $((retry+1)) de $MAX_RETRIES para URL $url (código: $http_response)"
            fi
        done
    done
    
    log_msg "ERROR" "Nenhuma URL respondeu corretamente"
    send_to_zabbix 2 "DNS responde, mas sem navegação HTTP"
    exit 0
}

# Função principal
main() {
    log_msg "INFO" "Iniciando verificação de conectividade..."
    
    # Verifica ferramentas disponíveis
    check_tools
    
    # Executa cada teste em sequência
    test_gateway
    test_dns_servers
    test_dns_resolution
    test_http_access
    
    # Se chegou até aqui, tudo está funcionando
    log_msg "INFO" "Todos os testes passaram, conectividade total verificada"
    send_to_zabbix 3 "Internet 100% funcional"
    exit 0
}

# Inicia o script
main

# Explicação dos códigos de retorno:
# 0 - Sem conexão nem com gateway       - Link caiu mesmo
# 1 - Gateway responde, Rede local ok   - Sem internet
# 2 - DNS responde, mas sem navegação   - Problema com acesso a sites
# 3 - Internet 100% funcional           - Tudo OK