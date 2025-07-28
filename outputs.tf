# Mostra o IP para acesso
output "instance_public_ip" {
  description = "O Public Elastic IP da instância EC2"
  value = aws_eip.one.public_ip
}