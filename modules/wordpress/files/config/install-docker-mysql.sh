#!/bin/bash -xe
sudo apt-get -y update
sudo apt-get -y install unattended-upgrades
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get -y update
sudo apt-get -y install docker-ce
sudo curl -L https://github.com/docker/compose/releases/download/1.25.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

# Next we’ll set the permissions:
sudo chmod +x /usr/local/bin/docker-compose
# exit 1

cat >> ~/docker-compose.yml <<EOF
version: '3.3'

services:
   db:
     image: mysql:5.7
     volumes:
       - db_data:/var/lib/mysql
     restart: always
     command: "--default-authentication-plugin=mysql_native_password"
     environment:
       MYSQL_ROOT_PASSWORD: password
       MYSQL_DATABASE: wpdb
       MYSQL_USER: user
       MYSQL_PASSWORD: password
volumes:
    db_data: {}

EOF

sudo docker-compose up -d
# sudo docker pull mysql/mysql-server:5.7
# sudo docker run --name=mysqlCon -p 3306:3306 -d mysql/mysql-server:5.7