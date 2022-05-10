provider "aws" {
  region = "us-east-2"
  profile = "default"
}

resource "aws_security_group" "WPSG" {
  
  name = "wpsgtf"
  ingress{
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "allow ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"  
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "allow http"
    from_port = 0
    to_port = 80
    protocol = "tcp"
  } 
   ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "allow ftp"
    from_port = 1024
    to_port = 1048
    protocol = "tcp"
  } 
  egress{
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "permit all"
    from_port = 0
    to_port = 0
    protocol = "-1"
  } 
  
}

resource "aws_instance" "wordpressfrontend" {
  ami           = "ami-0fa49cc9dc8d62c84"
  instance_type = "t2.medium"
  key_name = "WPTFkey"
  security_groups = [ "wpsgtf" ]
  tags = {
    app = "wordpress"
    role = "frontend"
   user_data= "${data.cloudinit_config.wordpress.rendered}"
  }
}
resource "aws_eip" "wpip" {
  instance = aws_instance.wordpressfrontend.id
  vpc      = true
  tags = {
    app = "wordpress"
  }
}


variable "dbpassword" {
  type = string
  default = "terraform"
}

resource "aws_db_instance" "wordpressbackend" {
  
  instance_class = "db.t2.medium"
  engine = "mysql"
  publicly_accessible = false
  allocated_storage = 20
  db_name = "wordpress"
  username = "admin"
  password = var.dbpassword
  skip_final_snapshot  = true
  tags = {
    app = "mysql"
  }  
}

data "cloudinit_config" "wordpress" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
                    #!/bin/bash
                    sudo yum install httpd -y
                    sudo systemctl start httpd
                    sudo systemctl enable httpd
                    sudo wget https://wordpress.org/wordpress-5.7.2.tar.gz
                    sudo tar -xzf wordpress-5.7.2.tar.gz
                    sudo cp -r wordpress/* /var/www/html/
                    EOF
    }

  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
                    #!/bin/bash
                    sudo yum install -y amazon-linux-extras
                    sudo amazon-linux-extras enable php7.2
                    sudo yum clean metadata -y
                    sudo yum install php-cli php-pdo php-fpm php-json php-mysqlnd -y
                    sudo systemctl restart httpd
                     EOF
  }
}

output "WebServerIP" {

    value = aws_instance.wordpressfrontend.public_ip
    description = "Web Server IP Address"
}
output "DatabaseName" {

    value = aws_db_instance.wordpressbackend.name
    description = "The Database Name!"
}
output "DatabaseUserName" {

    value = aws_db_instance.wordpressbackend.username
    description = "The Database Name!"
}
output "DBConnectionString" {

    value = aws_db_instance.wordpressbackend.endpoint
    description = "The Database connection String!"
}