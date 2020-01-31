#!/bin/bash

# Install Docker-compose
# We’ll check the current release and if necessary, update it in the command below:
sudo curl -L https://github.com/docker/compose/releases/download/1.25.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sleep 10

# Next we’ll set the permissions:
sudo chmod +x /usr/local/bin/docker-compose
exit 1
