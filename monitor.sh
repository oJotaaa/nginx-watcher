#!/bin/bash

# Configurações
URL="http://localhost/"
WEBHOOK_URL="COLOQUE_SEU_TOKEN_AQUI"
LOG_FILE="/var/log/monitoramento.log"

# Checar o status HTTP
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)

# Data e hora atual
TIME=$(date "+%d-%m-%Y %H:%M:%S")

# Registrar log
echo "$TIME - Status HTTP: $STATUS" >> "$LOG_FILE"

# Verificar se não é 200 (OK)
if [ "$STATUS" != "200" ]; then
    curl -H "Content-Type: application/json" \
    -X POST \
    -d "{\"content\": \"🚨 O site está fora do ar! Código HTTP: $STATUS\"}" \
    $WEBHOOK_URL
fi