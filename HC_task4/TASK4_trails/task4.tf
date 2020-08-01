provider  "aws" {
   region  = "ap-south-1"
   profile = "newpradeep"
}

resource "tls_private_key" "my_key" {             
  algorithm = "RSA"
}

output "key" {
   value = tls_private_key.my_key
}
resource "aws_key_pair" "my_key"{               
	key_name = "task3key"
	public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "my_privatekey" {
    content = tls_private_key.my_key.private_key_pem
    filename = "task3key"
    file_permission = 0400                             
}

resource "aws_eip" "lb" {
  instance = aws_instance.website.id
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  depends_on = [aws_subnet.alphanet2]
  allocation_id = aws_eip.lb.id
  subnet_id     = "${aws_subnet.alphanet1.id}"
  tags = {
	name = "MyNAT"
   }
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "alphanet1" {
  vpc_id            = aws_vpc.myvpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.1.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "main-1a"
  }
}


resource "aws_subnet" "alphanet2" {
  vpc_id            = aws_vpc.myvpc.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.1.1.0/16"
  map_public_ip_on_launch = false
  tags = {
    Name = "main-1b"
  }
}

resource "aws_internet_gateway" "public_gateway" {
  depends_on = [aws_vpc.myvpc]
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "mygateway1"
  }
}
resource "aws_route_table" "routetable" {
  depends_on = [ aws_vpc.myvpc, aws_internet_gateway.public_gateway]
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gateway.id
  }
  tags = {
    Name = "myroutingtale1"
  }
}

resource "aws_route_table_association" "associate" {
  subnet_id = aws_subnet.alphanet.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "wordpress_security"{
     name = "wordpress_security"
     description = "Web-server httpd port is allowed to connect" 
      vpc_id      = aws_vpc.myvpc.id     
      
      ingress{
             from_port = 80
             to_port = 80
             protocol = "tcp"
             cidr_blocks = ["0.0.0.0/0"]
      }
      ingress{
             from_port = 22
             to_port = 22
             protocol = "tcp"
             cidr_blocks = ["0.0.0.0/0"]
      }
      ingress {
    	description = "HTTPS"
    	from_port   = 443
    	to_port     = 443
    	protocol    = "tcp"
    	cidr_blocks = [ "0.0.0.0/0" ]
      }
      egress {
             from_port       = 0
             to_port         = 0
             protocol        = "-1"
             cidr_blocks     = ["0.0.0.0/0"]
      }
      tags = {
              Name = "wordpress"
      }
}

resource "aws_security_group" "mysql_security"{
     name = "mysql_security"
     description = "MySql security group is in private subnet"         
     vpc_id      = aws_vpc.myvpc.id   
     ingress{
             from_port = 3306
             to_port = 3306
             protocol = "tcp"
             cidr_blocks = ["0.0.0.0/0"]
      }
      ingress{
             from_port = 22
             to_port = 22
             protocol = "tcp"
             cidr_blocks = ["0.0.0.0/0"]
      }
      ingress {
    	description = "HTTPS"
    	from_port   = 443
    	to_port     = 443
    	protocol    = "tcp"
    	cidr_blocks = [ "0.0.0.0/0" ]
      }
      egress {
             from_port       = 0
             to_port         = 0
             protocol        = "-1"
             cidr_blocks     = ["0.0.0.0/0"]
      }
      tags = {
              Name = "mysql"
      }
}

resource "aws_instance" "website"{
 depends_on = [ aws_security_group.wordpress_security, aws_key_pair.my_key]
  ami = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.alphanet.id
  security_groups   = ["${aws_security_group.wordpress_security.id}"] 
   key_name	= aws_key_pair.my_key.key_name
   tags = {
    Name = "MyWebsite"
  }
}

resource "aws_instance" "mysql"{
  depends_on = [ aws_security_group.mysql_security,]
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  
  subnet_id     = aws_subnet.alphanet.id
  
  security_groups = ["${aws_security_group.mysql_security.id}" ]
  tags = {
    Name = "MySql"
  }
}
