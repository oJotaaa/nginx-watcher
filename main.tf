variable "subnets" {
  default = {
    public_1 = { cidr = "10.0.1.0/24", az = "us-east-1a", public = true }
    public_2 = { cidr = "10.0.2.0/24", az = "us-east-1b", public = true }
    private_3 = { cidr = "10.0.3.0/24", az = "us-east-1a", public = false }
    private_4 = { cidr = "10.0.4.0/24", az = "us-east-1b", public = false }
  }
}

# Criar a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# Criar o Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Criar a route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table-project"
  }
}

# Criar as Subnets
resource "aws_subnet" "sub-nets" {
    for_each = var.subnets
    vpc_id = aws_vpc.main.id
    cidr_block = each.value.cidr
    availability_zone = each.value.az

    tags = {
      Name = "${each.key}"
    }
}

# Associar subnet com a route table
resource "aws_route_table_association" "public_associations" {
    for_each = {
      for key, subnet in var.subnets :
       key => subnet
       if subnet.public == true
    }

    subnet_id = aws_subnet.sub-nets[each.key].id
    route_table_id = aws_route_table.prod-route-table.id
}

# Criar um Security Group com as portas 80, 22
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-project"
  description = "Permite acesso HTTP e SSH para os servidores web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # --- Regra de Saída (Egress) ---
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-webserver-project"
  }
}

# Criar uma key-pair pro usuário
resource "aws_key_pair" "meu_par_de_chaves_tf" {
  # O nome que a chave terá dentro da AWS
  key_name   = "Key-pair-monitor" 
  public_key = file("~/.ssh/id_rsa.pub") 
}

# Criar o Ubuntu server
resource "aws_instance" "web-server-instance" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = aws_key_pair.meu_par_de_chaves_tf.key_name

  subnet_id = aws_subnet.sub-nets["public_1"].id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  # User Data com todas as configurações implantadas para a instalação
  user_data = templatefile("${path.module}/user_data.sh", {
    TOKEN = var.webhook_token
    })
}

# Cria um elastic IP
resource "aws_eip" "one" {
  instance = aws_instance.web-server-instance.id
  domain                    = "vpc"
  depends_on = [ aws_internet_gateway.gw ]
}
