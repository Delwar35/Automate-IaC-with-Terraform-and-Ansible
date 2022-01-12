#!/bin/bash

#update
sudo apt-get update -y

#upgrade
sudo apt-get upgrade -y

#install nginx
sudo apt-get install nginx -y

#install  git
sudo apt-get install git -y

#install nodejs v6
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install nodejs -y

#install pm2
sudo npm install pm2 -g

# 192.168.10.100:3000 to access on browser
