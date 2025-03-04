This project creates required AWS infrastrucure: vpc, private and public subnets, InternetGateway, RouteTable, Application Loadbalancer, Instances, Security groups, etc.

2 Ec2 instances(webservers) created in public public subnet and assigned as Target group to Internet facing LoadBalancer.
 Loadbalancer accepts traffic from anywhere on the internet.

Webservers i.e. Ec2 instances receives traffic only from Loadbalancer.

Installed Apache webserver on Ec2 instances using user_data while creating instances using Terraform.
