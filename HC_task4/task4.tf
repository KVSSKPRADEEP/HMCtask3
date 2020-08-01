provider  "aws" {
   region  = "ap-south-1"
   profile = "newpradeep"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "alphanet1" {
 depends_on = [aws_vpc.myvpc]
  vpc_id            = aws_vpc.myvpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "192.168.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "wordpress"
  }
}


resource "aws_subnet" "alphanet2" {
  depends_on = [aws_vpc.myvpc]
  vpc_id            = aws_vpc.myvpc.id
  availability_zone = "ap-south-1b"
  cidr_block        = "192.168.1.0/24"
  tags = {
    Name = "mysql"
  }
}

resource "aws_internet_gateway" "public_gateway" {
  depends_on = [aws_subnet.alphanet1]
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "mygateway1"
  }
}

resource "aws_route_table" "routetable" {
  depends_on = [aws_internet_gateway.public_gateway]
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
  depends_on = [ aws_route_table.routetable]
  subnet_id = aws_subnet.alphanet1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_eip" "lb" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  depends_on = [aws_vpc.myvpc,aws_subnet.alphanet1,aws_eip.lb,aws_internet_gateway.public_gateway]
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.alphanet1.id
  tags = {
	name = "MyNAT"
   }
}
resource "aws_route_table" "routetableprivate" {
  depends_on = [aws_vpc.myvpc]
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    Name = "myroutingtale2"
  }
}

resource "aws_route_table_association" "associateprivate" {
  depends_on = [ aws_route_table.routetable]
  subnet_id = aws_subnet.alphanet2.id
  route_table_id = aws_route_table.routetableprivate.id
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
 depends_on = [ aws_internet_gateway.public_gateway,aws_security_group.wordpress_security,aws_subnet.alphanet1,aws_instance.mysql]
  ami = "ami-0c3d500b591de7dd9"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.alphanet1.id
  security_groups   = ["${aws_security_group.wordpress_security.id}"] 
   key_name	= "mykey111222"
   tags = {
    Name = "WordpressWebsite"
  }
}

resource "aws_instance" "mysql"{
  depends_on = [aws_security_group.mysql_security,aws_subnet.alphanet2]
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = "mykey111222"
  subnet_id     = aws_subnet.alphanet2.id
  security_groups = ["${aws_security_group.mysql_security.id}" ]
  tags = {
    Name = "MySql"
  }
}




 

 