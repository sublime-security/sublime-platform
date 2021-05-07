#!/bin/bash

set -e

cd /home/ubuntu/Sublime-Security

echo "Commencing docker-compose update `date`" | sudo tee -a docker-compose-update.log

echo "Fetching latest docker-compose.yml file" | sudo tee -a docker-compose-update.log
sudo curl -s https://raw.githubusercontent.com/sublime-security/sublime-platform/latest-staging/aws/docker-compose-latest.yml -o /home/ubuntu/Sublime-Security/docker-compose.yml

# Do a pull then an update
echo "Pulling and updating services" | sudo tee -a docker-compose-update.log

sudo docker-compose -f docker-compose.yml pull --no-parallel | sudo tee -a docker-compose-update.log 2>&1
sudo docker-compose -f docker-compose.yml up -d | sudo tee -a docker-compose-update.log 2>&1

echo "Finishing docker-compose update `date`" | sudo tee -a docker-compose-update.log
