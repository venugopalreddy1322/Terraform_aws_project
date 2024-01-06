#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>Deployed via Terraform <h2>from $(hostname -f)</h2></h1>" | sudo tee /var/www/html/index.html
# echo ${ aws_instance.webserver1.public_ip }