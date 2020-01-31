#!/bin/bash

# sudo apt-get -y update
# sudo apt-get -y install unattended-upgrades
# sudo apt-get -y install \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     software-properties-common


# Install on Linux Ubuntu
sudo wget -qO- https://get.docker.com/ | sh


# Using Docker without Root Permission on Linux
# sudo groupadd docker

# Add your user to the docker group:
sudo gpasswd -a $USER docker
echo "Added your user to the docker group"
echo ""


# You can login again to have your groups updated by entering:
sudo newgrp docker
echo "You can login again to have your groups updated by entering"
exit 1

    # Now you will have docker in your list of groups if you enter groups.
    # Note: It is convenient to not have to terminate your current ssh session by using newgrp, but terminating the ssh session and logging in again will work just as well.


# # Install Docker-compose
# # We’ll check the current release and if necessary, update it in the command below:
# sudo curl -L https://github.com/docker/compose/releases/download/1.25.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# sleep 10

# # Next we’ll set the permissions:
# sudo chmod +x /usr/local/bin/docker-compose


# # Installing Wordpress
# sudo docker run -d \
#     -e WORDPRESS_DB_HOST=${dbhost}:3306 \
#     -e WORDPRESS_DB_PASSWORD=wpdbwpdb \
#     -e WORDPRESS_DB_USER=wpdb \
#     -e WORDPRESS_DB_NAME=wpdb \
#     -p 80:80 \
#     wordpress:latest
