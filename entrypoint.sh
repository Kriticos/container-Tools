#!/bin/bash

CONFIG_PATH="/root/.config/ookla/speedtest-cli.json"

# Garante que a pasta existe
mkdir -p "$(dirname "$CONFIG_PATH")"

# Se o arquivo ainda não existir, cria com licença aceita
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Registrando aceite da licença do speedtest..."
  cat <<EOF > "$CONFIG_PATH"
{
  "LicenseAccepted": true,
  "Settings": {
    "LicenseAccepted": "604ec27f828456331ebf441826292c49276bd3c1bee1a2f65a6452f505c4061c",
    "GDPRTimeStamp": $(date +%s)
  }
}
EOF
fi

# Executa o que foi passado ao container
exec "$@"
