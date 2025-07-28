variable "webhook_token" {
  description = "URL do webhook (Discord, etc)"
  type = string
  sensitive = true
  nullable = false
}

variable "default_tags" {
  description = "Tags padrões para os serviços"
  type = map(string)
  default = {}
}

variable "aws_profile" {
  description = "Nome do perfil AWS no ~/.aws/credentials"
  type = string
  default = ""
}
