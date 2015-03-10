#!/bin/bash 
# Debian 7
# run this script outside of the /meshblu folder as it deletes the folder
# Copy the Meshblu folder
# copy this script
# set the permissions:  chmod +x install.sh
# run the script (without sudo):  ./install.sh
# This requires an internet connection to pull source.

# install core system services
apt-get install -y build-essential supervisor ufw

# install for node_mdns compat - specific to debianesque systems https://github.com/agnat/node_mdns
apt-get install -y libavahi-compat-libdnssd-dev

# install for mosca
apt-get install -y libzmq-dev

### add custom sources
# MongoDB (current instructions: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/ )
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list

# Node from NodeSource  (this runs 'apt-get update')
wget -O node-setup.sh https://deb.nodesource.com/setup --no-check-certificate
chmod +x node-setup.sh
./node-setup.sh

### install servers / services
# install node -  from NodeSource automatically installs legacy pointers (Ubuntu package does not)
apt-get install -y nodejs

# make sure that NPM is at the latest
npm -g update npm

# install MongoDB - automatically sets is as a service
apt-get install -y mongodb-org

# install Redis server - automatically sets it as a service
apt-get install -y redis-server

# global install of bcrypt
npm install --unsafe-perm -g bcrypt

# install forever to run the servers as services
npm install -g forever

# python scripting support
sudo apt-get install -y python-psutil python3-psutil

# architecture support
if [ `getconf LONG_BIT` = "64" ]
	then
		echo "64-bit system. Adding 32-bit library support."
		sudo apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386
	else
		echo "Assuming 32-bit system. Nothing more to see here. Move along."
fi

# directories
mkdir /opt/blu
mkdir /opt/blu/log
mkdir /opt/blu/meshblu

# copy the meshblu build to the VM, or mount the image or source.

# copy the meshblu pull to /var/www
cp ~/meshblu/* /opt/blu/meshblu
cp -r ~/meshblu/public /opt/blu/meshblu/public
cp -r ~/meshblu/lib /opt/blu/meshblu/lib

# copy the sysvinit configuration for forever  "forever start server.js --http"
# http://labs.telasocial.com/nodejs-forever-daemon/
cp ~/debian_meshblu.conf /etc/init.d/meshblu
chmod 755 /etc/init.d/meshblu
update-rc.d meshblu defaults

# set the appliance specific server.js config
cp ~/meshbluConfig.js /opt/blu/meshblu/config.js

# add permissions so things will work properly
chmod -R ugo+rw /opt/blu

# install Meshblu
cd /opt/blu/meshblu
npm install --production --loglevel warn

# Meshblu listener ports: 3000 (Meshblu) 5683 (CoAP) 1883 (MQTT) 
# Services listener ports:  6379 (redis) 27017 (MongoDB)

# set Ubuntu Uncomplicated Firewall incoming rules
ufw allow 80/tcp   # http
ufw allow 443/tcp   # https
ufw allow 3000/tcp   # meshblu api
ufw allow 1883/tcp   # mqtt
ufw allow 5683/tcp    # coap
ufw allow 22/tcp    # ssh
ufw allow 9337/tcp   # sdx
ufw --force enable

# reboot the VM
shutdown now -r

# On reboot the VM will be working.
# PowerShell verify it is running: Invoke-RestMethod -URI http://<IP address>:3000/status -ContentType "application/json" -Method Get
