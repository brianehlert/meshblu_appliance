#!/bin/bash 
# Ubuntu 14.10
# download this script to your home directory.
# set the permissions:  chmod +x install.sh
# run the script (without sudo):  ./install.sh
# This requires an internet connection to pull source.
# this builds the meshblu application in place as well as adds mongodb and redis-server

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
sudo add-apt-repository -y ppa:rwky/redis

# Node from NodeSource  (this runs 'apt-get update' that is why we add the repos prior)
sudo curl -sL https://deb.nodesource.com/setup | sudo bash -

### install servers / services
# install node -  from NodeSource automatically installs legacy pointers (Ubuntu package does not)
sudo apt-get install -y nodejs

# make sure that NPM is at the latest
sudo npm -g update npm

# install MongoDB - automatically sets is as a service
sudo apt-get install -y mongodb-org

# install Redis server - automatically sets it as an Upstart service
# this pulls the latest from Redis.io per: https://launchpad.net/~rwky/+archive/ubuntu/redis
sudo apt-get install -y redis-server

# global install of bcrypt
# sudo npm install -g node-gyp
# sudo npm install --unsafe-perm -g bcrypt

# install forever to run the servers as services
sudo npm install -g forever

# Install uuid-runtime for configuration
sudo apt-get install -y uuid-runtime

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

# add Git
sudo apt-get install -y git-core

# set git to use https instead: of git: - not always necessary, but solves port blocking problems
sudo git config --global url.https://.insteadOf git://

### Install Meshblu the messaging platform
# Make the meshblu directories
sudo mkdir -p /opt/blu/meshblu
sudo mkdir -p /opt/blu/log

# Clone Meshblu from GitHub
sudo git clone https://github.com/octoblu/meshblu.git /opt/blu/meshblu

# Remove folders unnecessary for production
sudo rm -r /opt/blu/meshblu/test
sudo rm -r /opt/blu/meshblu/docker

# Remove unnecessary files
sudo rm /opt/blu/meshblu/config.js
sudo rm /opt/blu/meshblu/Dockerfile

# Set permissions so things will work properly
sudo chmod -R ugo+rw /opt/blu

# Install Meshblu using npm
cd /opt/blu/meshblu
sudo npm install --production --unsafe-perm

# Add the Upstart script from meshblu_appliance
sudo wget --output-document /etc/init/meshblu.conf https://raw.githubusercontent.com/brianehlert/meshblu_appliance/master/ubuntu_meshblu.conf 

# Build a unique configuration for this Meshblu instance
uuid=$(uuidgen)
token=$(uuidgen)
deviceUuid=$(uuidgen)
deviceToken=$(uuidgen)

echo > /opt/blu/meshblu/config.js
echo "module.exports = {" >> /opt/blu/meshblu/config.js
echo "  port: 3000," >> /opt/blu/meshblu/config.js
echo "  log: true," >> /opt/blu/meshblu/config.js
echo "  uuid: '$uuid'," >> /opt/blu/meshblu/config.js
echo "  token: '${token//-/}'," >> /opt/blu/meshblu/config.js
echo "  mongo: {" >> /opt/blu/meshblu/config.js
echo "    databaseUrl: 'mongodb://localhost:27017/meshblu'" >> /opt/blu/meshblu/config.js
echo "  }," >> /opt/blu/meshblu/config.js
echo "  redis: {" >> /opt/blu/meshblu/config.js
echo "    host: 'localhost'," >> /opt/blu/meshblu/config.js
echo "    port: '6379'" >> /opt/blu/meshblu/config.js
echo "  }," >> /opt/blu/meshblu/config.js
echo "  coap: {" >> /opt/blu/meshblu/config.js
echo "    port: 5683," >> /opt/blu/meshblu/config.js
echo "    host: 'localhost'" >> /opt/blu/meshblu/config.js
echo "  }," >> /opt/blu/meshblu/config.js
echo "  mqtt: {" >> /opt/blu/meshblu/config.js
echo "    databaseUrl: 'mongodb://localhost:27017/mqtt',"  >> /opt/blu/meshblu/config.js
echo "    port: 1883," >> /opt/blu/meshblu/config.js
echo "    skynetPass: '${token//-/}${deviceToken//-/}'" >> /opt/blu/meshblu/config.js
echo "  }," >> /opt/blu/meshblu/config.js
echo "  parentConnection: {" >> /opt/blu/meshblu/config.js
echo "    // uuid: '$deviceUuid'," >> /opt/blu/meshblu/config.js
echo "    // token: '${deviceToken//-/}'," >> /opt/blu/meshblu/config.js
echo "    // server: 'meshblu.octoblu.com'," >> /opt/blu/meshblu/config.js
echo "    // port: 80" >> /opt/blu/meshblu/config.js
echo "  }" >> /opt/blu/meshblu/config.js
echo "};" >> /opt/blu/meshblu/config.js
	
# To configure this Meshblu instance to call home to Octoblu (the cloud service):
#		a. stop the service if it is running
#          sudo service meshblu stop
#		b. Uncomment the parent connection section and note the UUID in the section
#		   This UUID and Token is the device identity in the Octoblu database.
#		c. Start the service
#          sudo service meshblu start
#		d. Claim the device in Octoblu using the parent connection UUID

#	For testing the Service can be started and stopped manually by:
#	sudo service meshblu start
#	sudo service meshblu stop
#	Logs at:  /opt/blu/log

# Meshblu listener ports: 3000 (Meshblu) 5683 (CoAP) 1883 (MQTT) 
# Services listener ports:  6379 (redis) 27017 (MongoDB)

# set Ubuntu Uncomplicated Firewall incoming rules
sudo ufw allow 80/tcp   # http
sudo ufw allow 443/tcp   # https
sudo ufw allow 3000/tcp   # meshblu api
sudo ufw allow 1883/tcp   # mqtt
sudo ufw allow 5683/tcp    # coap
sudo ufw allow 22/tcp    # ssh
sudo ufw allow 9337/tcp   # sdx
sudo ufw --force enable

# reboot the VM
sudo shutdown now -r

# On reboot the VM will be working.
# PowerShell verify it is running: Invoke-RestMethod -URI http://<IP address>:3000/status -ContentType "application/json" -Method Get
