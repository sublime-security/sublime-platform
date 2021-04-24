#!/bin/bash

set -e

cd /home/ubuntu/Sublime-Security

echo "Commencing docker-compose update `date`" | sudo tee -a docker-compose-update.log

echo "Fetching latest docker-compose.yml file" | sudo tee -a docker-compose-update.log
sudo curl -s https://raw.githubusercontent.com/sublime-security/sublime-platform/main/aws/docker-compose-latest.yml -o /home/ubuntu/Sublime-Security/docker-compose.yml

# Do a pull then an update
echo "Pulling and updating the docker-compose" | sudo tee -a docker-compose-update.log
sudo docker-compose -f docker-compose.yml pull --no-parallel | sudo tee -a docker-compose-update.log 2>&1
sudo docker-compose -f docker-compose.yml up -d | sudo tee -a docker-compose-update.log 2>&1
echo "Sleeping 10 seconds." | sudo tee -a docker-compose-update.log
sleep 10
sudo docker-compose -f docker-compose.yml restart | sudo tee -a docker-compose-update.log 2>&1
echo "Finishing docker-compose update `date`" | sudo tee -a docker-compose-update.log
