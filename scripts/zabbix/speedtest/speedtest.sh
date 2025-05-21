#!/bin/bash

HOST="Link - Internet"
ZABBIX_SERVER="172.18.0.3"

# Roda o speedtest e captura saída JSON
RESULT=$(speedtest --format=json)

# Garante que tenha saída válida
[ -z "$RESULT" ] && echo "Erro: speedtest não retornou nada." && exit 1

# Extrai dados com jq
DOWNLOAD=$(echo "$RESULT" | jq '.download.bandwidth' )
UPLOAD=$(echo "$RESULT" | jq '.upload.bandwidth' )
LATENCY=$(echo "$RESULT" | jq '.ping.latency')
LATENCY_JITTER=$(echo "$RESULT" | jq '.ping.jitter')
PACKET_LOSS=$(echo "$RESULT" | jq '.packetLoss // 0') # Se não houver, assume 0
DOWNLOAD_PING=$(echo "$RESULT" | jq '.download.latency.iqm')
UPLOAD_PING=$(echo "$RESULT" | jq '.upload.latency.iqm')
SERVER_NAME=$(echo "$RESULT" | jq -r '.server.name')
RESULT_URL=$(echo "$RESULT" | jq -r '.result.url')

# Convertendo de Bytes para Mbps
DOWNLOAD_MBPS=$(awk "BEGIN {print $DOWNLOAD * 8 / 1000000}")
UPLOAD_MBPS=$(awk "BEGIN {print $UPLOAD * 8 / 1000000}")

# Envia os dados pro Zabbix
echo "Download: $DOWNLOAD_MBPS, Upload: $UPLOAD_MBPS, Latência: $LATENCY"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.download -o "$DOWNLOAD_MBPS"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.upload -o "$UPLOAD_MBPS"
#zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.latency -o "$LATENCY"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.latency_jitter -o "$LATENCY_JITTER"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.packet_loss -o "$PACKET_LOSS"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.download_ping -o "$DOWNLOAD_PING"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.upload_ping -o "$UPLOAD_PING"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.server_name -o "$SERVER_NAME"
zabbix_sender -z "$ZABBIX_SERVER" -s "$HOST" -k speedtest.result_url -o "$RESULT_URL"
