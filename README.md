# Nginx Watcher

### Descrição

Este projeto provisiona uma instância EC2 na AWS configurada para monitorar um site, enviando uma notificação para um canal do Discord via Webhook caso o site esteja fora do ar.

### Tecnologias usadas

- **Terraform** – Infraestrutura como código (IaC)
- **VPC** – Rede privada virtual
- **EC2** – Instância para hospedagem do servidor
- **SSH** – Conexão com a EC2
- **Nginx** – Servidor web
- **Bash** – Script de monitoramento
- **Discord Webhook** – Notificações de alerta
- **Cron** – Agendamento de execução do script
- **User Data** – Configuração automática da instância

### Arquitetura e Recursos criados

- **Instância EC2**: Servidor principal
- **VPC**: Rede privada
- **Internet Gateway**: Acesso à internet
- **Route Table**: Direcionamento do tráfego
- **Subnets**: Sub-redes públicas e privadas
- **Security Group**: Permissões de acesso (portas 80 e 22)
- **Key Pair**: Autenticação SSH
- **Elastic IP**: IP fixo atribuído à instância

### Pré-requisitos

- Conta na AWS
- Terraform instalado
- AWS CLI configurado (com credenciais)
- Token do seu Webhook
- Um par de chaves SSH gerado em `~/.ssh/` (O projeto gera uma chave automaticamente para você)

### Como usar (implantação)

1. Clone o repositório:

```bash
git clone https://github.com/oJotaaa/nginx-watcher.git
```

2. Crie um arquivo `secrets.auto.tfvars` na raiz do projeto:

Copie o conteúdo do arquivo `secrets.auto.tfvars.example` e cole no arquivo criado substituindo pelos seus valores.

<div align="left">
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1400155899951317023/image.png?ex=688b9c4c&is=688a4acc&hm=380d015ce6cb2430a57418675855bd94191c96dfe4d2b8e98b9c3f962d8eae35&" width="300px" />
</div>

3. Inicie o Terraform:

```bash
terraform init 
terraform plan # para visualizar o que será criado
terraform apply # para a criação da infraestrutura
```

4. Após a criação, o Terraform mostrará o IP público da instância. Acesse via navegador ou SSH:

```bash
ssh -i "~/.ssh/id_rsa" ubuntu@<SEU_IP_PUBLICO>
```

### Dentro da instância:

- O script de monitoramento está em `/var/opt/aws-monitor/monitor.sh`
- Os logs estão em `/var/log/monitoramento.log`
- Cron configurado em `/etc/cron.d/system-monitor` (execução a cada 1 min)
- Verifique o status do Nginx:

```bash
sudo systemctl status nginx
```

Se estiver indicando Active (Running), está tudo certo.
<div align="left">
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1399486160648278016/image.png?ex=68892c8d&is=6887db0d&hm=2746b4af3f030f550751382bb6926dba652f844ebd26b79228f9cdc2f970895e&" width="400px" />
</div>

## Desativar reinício automático do Nginx antes do teste de notificação

Antes de iniciar o teste de notificação, é necessário desativar o reinício automático do servidor Nginx em caso de falha para evitar interferências.

Siga os passos abaixo:

1. Edite o arquivo do serviço do Nginx:

   ```bash
   sudo vim /usr/lib/systemd/system/nginx.service
   ```

2. Localize a seção `[Service]` e comente as duas primeiras linhas referentes ao reinício automático, adicionando o caractere `#` no início de cada uma. Por exemplo:

   ```ini
   [Service]
   #Restart=always
   #RestartSec=10
   ```

3. Salve e feche o arquivo.

4. Recarregue as configurações do systemd para aplicar as alterações:

   ```bash
   sudo systemctl daemon-reload
   ```

Após isso, o reinício automático do Nginx estará desativado para que você possa realizar o teste de notificação corretamente.

### Testando a notificação:

1. Encontre o processo principal do Nginx:

```bash
sudo ps aux | grep nginx
```
O PID correto será o processo que terá o root como owner
<div align="left">
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1399485319241535609/image.png?ex=68892bc5&is=6887da45&hm=83bc944f6cc00765ecae68b845eef56ee780443be4eb7e6835883675e1b5b095&" width="400px" />
</div>

2. Mate o processo principal (com root como owner):

```bash
sudo kill -9 <PID>
```

3. Confirme que o Nginx caiu:

```bash
sudo systemctl status nginx
```

Se estiver indicando Active (failed), significa que o servidor está fora do ar.
<div align="left">
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1399487031326937280/image.png?ex=68892d5d&is=6887dbdd&hm=784ded282217b09deadbfc244136ef8b557b84df27e79ebde92e8737a420609c&" width="400px" />
</div>

4. Aguarde a próxima execução do script. A mensagem será enviada ao Discord e registrada no log.
<div align="left">
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1399488339773624441/image.png?ex=68892e95&is=6887dd15&hm=18c3d1840d4c265dc3b73ce8f8d380718e7a01206218c3f465602a47b6b994f2&" width="400px style="border-radius: 10px;" />
<img src="https://cdn.discordapp.com/attachments/749695145598779392/1399489117867343955/image.png?ex=68892f4e&is=6887ddce&hm=99fce80aad4119ff8dedf8ad9c5e35f7a8d8ddfcb0f7535587c2ffe409a8a106&" width="400px" />
</div>

5. Para restaurar o Nginx:

```bash
sudo systemctl start nginx
```

### Explicando o Script `monitor.sh`

- Faz uma requisição HTTP para uma URL especificada.
- Verifica se o código de resposta é diferente de 200 OK.
- Em caso de falha, envia uma notificação para um Webhook do Discord com o código de erro.
- Registra data, hora e status da verificação em um arquivo de log local.

#### Tecnologias e comandos utilizados:
- `curl`: para testar a disponibilidade da URL e para enviar notificações via Webhook.
- `date`: para registrar data e hora da checagem.
- `echo`: para salvar os logs.
- Webhook do Discord para alertas automáticos.
  
### Limpeza dos recursos:
Para remover todos os recursos criados por este projeto, no terminal onde o Terraform está configurado, execute:

```bash
terraform destroy
```
---

### Autor
[João Felipe Fernandes Pimentel](https://www.linkedin.com/in/joaofelipefernandes/)
