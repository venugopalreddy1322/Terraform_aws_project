#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Deployed via Terraform from $(hostname -f)</h1>" | sudo tee /var/www/html/index.html
# we can use diff commands to add to index.html file