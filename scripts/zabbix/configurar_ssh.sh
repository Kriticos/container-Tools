#!/bin/bash

# =======================
# CONFIGURAR SSH COM CHAVE PÚBLICA
# =======================

# VARIÁVEIS
USUARIO="$1"
CHAVE_PUBLICA="$2"
SSH_DIR="/home/$USUARIO/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# VALIDAR ENTRADAS
if [ -z "$USUARIO" ] || [ -z "$CHAVE_PUBLICA" ]; then
  echo "Uso: sudo ./configurar_ssh.sh <usuario> '<chave_publica>'"
  exit 1
fi

# VERIFICA SE USUÁRIO EXISTE
if ! id "$USUARIO" &>/dev/null; then
  echo "Erro: usuário '$USUARIO' não existe."
  exit 1
fi

# CRIAR DIRETÓRIO .ssh
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$USUARIO:$USUARIO" "$SSH_DIR"

# ADICIONAR CHAVE
echo "$CHAVE_PUBLICA" >> "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"
chown "$USUARIO:$USUARIO" "$AUTHORIZED_KEYS"

# GARANTIR QUE SSH ESTÁ ATIVO
systemctl enable ssh
systemctl start ssh

echo "✅ Chave adicionada com sucesso para o usuário $USUARIO"

