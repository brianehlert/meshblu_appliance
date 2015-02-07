#!/bin/sh 
# Ubuntu 14.10
# run this script outside of the /meshblu folder as it deletes the folder
# Copy the Meshblu folder
# copy this script
# set the permissions:  chmod +x install.sh
# run the script (without sudo):  ./install.sh
# This requires an internet connection to pull source.

# install core system services
sudo apt-get install -y build-essential supervisor 

# install for node_mdns compat - specific to debianesque systems https://github.com/agnat/node_mdns
sudo apt-get install -y libavahi-compat-libdnssd-dev

# install for mosca
sudo apt-get install -y libzmq-dev

### add custom sources
# MongoDB (current instructions: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/ )
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

# Node from NodeSource  (this runs 'apt-get update')
sudo curl -sL https://deb.nodesource.com/setup | sudo bash -

### install servers / services
# install node -  from NodeSource automatically installs legacy pointers (Ubuntu package does not)
sudo apt-get install -y nodejs

# make sure that NPM is at the latest
sudo npm -g update npm

# install MongoDB - automatically sets is as a service
sudo apt-get install -y mongodb-org

# install Redis server - automatically sets it as a service
sudo apt-get install -y redis-server

# global install of bcrypt
sudo npm install --unsafe-perm -g bcrypt

# install forever to run the servers as services
sudo npm install -g forever

# directories
sudo mkdir /var/log/meshblu
sudo mkdir /var/www

# add permissions so things will work properly
sudo chmod -R ugo+rw /var/log/meshblu
sudo chmod -R ugo+rw /var/www

# Extract the meshblu build to /var/www
cd /var/www
tar -xzvf ~/*.tgz
mv package meshblu

# copy the forever configuration  "forever start server.js --http"
sudo cp ~/ubuntu_meshblu.conf /etc/init/meshblu.conf

# set the appliance specific server.js config
sudo cp ~/meshbluConfig.js /var/www/meshblu/config.js

# install Meshblu
cd /var/www/meshblu
sudo npm install --production --loglevel warn

# Meshblu listener ports: 3000 (Meshblu) 5683 (CoAP) 1883 (MQTT) 
# Services listener ports:  6379 (redis) 27017 (MongoDB)

# set Ubuntu Uncomplicated Firewall incoming rules
sudo ufw allow 80/tcp   # http
sudo ufw allow 443/tcp   # https
sudo ufw allow 3000/tcp   # meshblu api
sudo ufw allow 1883/tcp   # mqtt
sudo ufw allow 5683/tcp    # coap
sudo ufw allow 22/tcp    # ssh
sudo ufw --force enable

# reboot the VM
sudo shutdown now -r

# On reboot the VM will be working.
# PowerShell verify it is running: Invoke-RestMethod -URI http://<IP address>:3000/status -ContentType "application/json" -Method Get
