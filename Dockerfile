FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Pacotes essenciais + speedtest
RUN apt update && apt install -y \
    jq \
    gnupg \
    curl \
    wget \
    rsync \
    cron \
    bash \
    unzip \
    nano \
    zip \
    iproute2 \
    dnsutils \
    iputils-ping

# Speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash \
 && apt install -y speedtest

# Zabbix sender
RUN wget https://repo.zabbix.com/zabbix/7.2/stable/debian/pool/main/z/zabbix/zabbix-agent2_7.2.4-1%2Bdebian12_amd64.deb \
 && dpkg -i zabbix-agent2_7.2.4-1+debian12_amd64.deb \
 && apt update \
 && apt install -y zabbix-sender \
 && rm -f zabbix-agent_7.2.4-1+debian12_amd64.deb

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-f"]