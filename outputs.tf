output "vpc-id" {
    value = aws_vpc.my_vpc.id
  
}
output "IGW-ID" {
  value = aws_internet_gateway.igw.id
}
output "Subnet-1-id" {
  value = aws_subnet.subnet1.id
}
output "webserver1-instance-id" {
  value = aws_instance.webserver1.id
}
output "Webserver2-instance-id" {
  value = aws_instance.webserver2.id
}
output "webserver1-public-ip" {
  value = aws_instance.webserver1.public_ip
}
output "Webserver2-public-ip" {
  value = aws_instance.webserver2.public_ip
}
output "Webserver-private-ip" {
  value = aws_instance.webserver1.private_ip
}
output "Webserver2-private-ip" {
  value = aws_instance.webserver2.private_ip
}
output "LoadbalancerDNS" {
    value = aws_lb.frontend-alb.dns_name
}