#!/bin/bash

# Garante que a lista de pacotes está atualizada antes de instalar algo
apt-get update -y
apt-get install -y nginx curl

# Iniciar e habilitar o NGINX
systemctl start nginx
systemctl enable nginx

# Criar a página HTML
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Meu Projeto AWS</title>
</head>
<body>
    <h1>✅ Site em funcionamento via EC2 + Nginx!</h1>
</body>
</html>
EOF

# Altera o fuso horário para America/Sao Paulo
sudo timedatectl set-timezone America/Sao_Paulo

# Cria o diretório aws-monitor
mkdir -p /var/opt/aws-monitor

# Cria o script de monitoramento no diretório /var/opt/aws-monitor
cat <<EOF > /var/opt/aws-monitor/monitor.sh
#!/bin/bash

# Configurações
URL="http://localhost/"
WEBHOOK_URL="${TOKEN}"
LOG_FILE="/var/log/monitoramento.log"

# Checar o status HTTP
STATUS=\$(curl -s -o /dev/null -w "%%{http_code}" \$URL)

# Data e hora atual
TIME=\$(date "+%d-%m-%Y %H:%M:%S")

# Registrar log
echo "\$TIME - Status HTTP: \$STATUS" >> "\$LOG_FILE"

# Verificar se não é 200 (OK)
if [ "\$STATUS" != "200" ]; then
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"🚨 O site está fora do ar! Código HTTP: \$STATUS\"}" \
         \$WEBHOOK_URL
fi
EOF

# Torna o script de monitoramento executável
chmod +x /var/opt/aws-monitor/monitor.sh

# Configura o Cron para executar o script a cada 1 minuto
echo "*/1 * * * * root /var/opt/aws-monitor/monitor.sh" > /etc/cron.d/system-monitor
