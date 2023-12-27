#1. create a vpc

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Demo_vpc"
  }
}
#2. create 1 public subnet and 1 private subnet under the created vpc
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet2"
  }
}

#3. create IGW and attach to vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MY_IGW"
  }
}

#4. create RouteTable for public subnet to IGW
resource "aws_route_table" "routetable1" {
    vpc_id = aws_vpc.my_vpc.id

    route {        
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
      Name = "Rt1-subnet1"
    }
}
resource "aws_route_table" "routetable2" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "RT2-Subnet2"
  }

}
#5. Associate RouteTable with subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable1.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable2.id
}

#6. create security group for EC2-instance which allows 
# trafic only from ALB (Security group of ALB)

resource "aws_security_group" "ec2-sg-alb-http" {
  description = "Allow HTTP inbound traffic only from ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    #cidr_blocks      = [] #instead of cidr Security-Group of ALB
    security_groups = ["${aws_security_group.alb-sg.id}"]
  }
  ingress {
    description = "Allow traffic from anywhere to do SSH on port 22"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ec2-sg-alb"
  }
}
#7. create security group for ALB
resource "aws_security_group" "alb-sg" {
  description = "Allow HTTP inbound traffic only from ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "HTTP traffic from any where to ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]     
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb-sg-http"
  }
}

#8. create 2 ec2 instances in public subnet

resource "aws_instance" "webserver1" {
  ami = "ami-0c7217cdde317cfec" # ubuntu for webserver us-east-1
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-sg-alb-http.id]
  subnet_id = aws_subnet.subnet1.id
  user_data = "${file("install_apache_webserver1.sh")}"
  tags = {
    Name = "Webserver1"
  }
}
resource "aws_instance" "webserver2" {
  ami = "ami-079db87dc4c10ac91" # AmazonLinux for webserver us-east-1
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2-sg-alb-http.id]
  subnet_id = aws_subnet.subnet2.id
  user_data = "${file("install_apache_AWSLinux.sh")}"
  tags = {
    Name = "Webserver2"
  }
}

#9. create Loadbalancer in public subnet add those 2 ec2 instances as listener to it
resource "aws_lb" "frontend-alb" {
  internal = "false"
  load_balancer_type = "application"
  subnets = [ aws_subnet.subnet1.id, aws_subnet.subnet2.id ]
  security_groups = [ aws_security_group.alb-sg.id ]
  tags = {
    Name = "Web-Loadbalancer"
  }
}

# create Target-Group for ALB
resource "aws_lb_target_group" "web-tg" {
  name = "Instance-Targetgroup"
  port = 80
  protocol = "HTTP"
  # by default target_type = "instance" 
  vpc_id = aws_vpc.my_vpc.id #ignore this if target_type is lambda

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Target group attachment- attaching instances/ip-add/lambda functions/or ther LoadBalancers

resource "aws_lb_target_group_attachment" "attach-instance1" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "attach-instance2" {
  target_group_arn = aws_lb_target_group.web-tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

# ALB Listeners
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.frontend-alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }
}
