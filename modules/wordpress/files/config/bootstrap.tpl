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
sudo chmod +x /usr/local/bin/docker-compose
sleep 5

# sudo docker-compose -f https://raw.githubusercontent.com/docker-library/docs/456252a739783650c79bd1f6a7a19101fbecfc65/wordpress/stack.yml up
# sudo docker-compose -f /files/config/wp/stack.yml up -d
# sudo docker run -d -e WORDPRESS_DB_HOST=${dbhost}:3306 -e WORDPRESS_DB_PASSWORD=wpdbwpdb -e WORDPRESS_DB_USER=wpdb -e WORDPRESS_DB_NAME=wpdb -p 80:80 wordpress:latest

cd ~
cat >> ~/stack.yml <<EOF
version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_ROOT_PASSWORD: password
      # MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:

EOF

sudo docker-compose -f ~/stack.yml up 
