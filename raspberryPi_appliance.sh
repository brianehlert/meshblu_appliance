#!/bin/bash
# Raspian (Noobs) on pi B
# download this script to your home folder
# set the permissions:  chmod +x install.sh
# run the script (without sudo):  ./install.sh
# This requires an internet connection to pull source.
# this builds Meshblu and Gateblu in place on a RaspberryPi and sets them to start as background processes.

# Install node for ARM
echo "deb http://node-arm.herokuapp.com/ /" | sudo tee --append /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y node --force-yes
# node -v
# Update npm
sudo npm -g update npm

# set git to use https instead: of git: - not always necessary, but solves port blocking problems
sudo git config --global url.https://.insteadOf git://

# install forever to run the blu servers as services
sudo npm install -y -g forever

# install of node-gyp for building
# sudo npm install -y -g node-gyp

# Install Upstart - used due to process forking and sysvinit losing track of the fork
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! Everything will stop here.  You must respond to this !!!"
echo "!!! yes, you want to respond:  Yes, do as I say!         !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
sudo apt-get install upstart

# Install uuid-runtime for configuration
sudo apt-get install -y uuid-runtime

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
sudo wget --output-document /etc/init/meshblu.conf https://raw.githubusercontent.com/brianehlert/meshblu_appliance/master/raspberryPi_meshblu.conf 

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
echo "  mqtt: {" >> /opt/blu/meshblu/config.js
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

### Adding Gateblu to the already installed Meshblu:

# Create the directory
sudo mkdir -p /opt/blu/gateblu-forever

# Clone Gateblu from GitHub
sudo git clone https://github.com/octoblu/gateblu-forever.git /opt/blu/gateblu-forever

# Remove folders unnecessary for production
sudo rm -r /opt/blu/gateblu-forever/test

# Remove unnecessary files
sudo rm /opt/blu/gateblu-forever/*.sublime*

# Set the permissions
sudo chmod -R ugo+rw /opt/blu/gateblu-forever

# Install Gateblu with npm
cd /opt/blu/gateblu-forever
sudo npm install --production --unsafe-perm

# Add the Upstart script from meshblu_appliance
sudo wget --output-document /etc/init/gateblu.conf https://raw.githubusercontent.com/brianehlert/meshblu_appliance/master/raspberryPi_gateblu.conf 

# Build a unique configuration for this Gateblu instance
uuid=$(uuidgen)
token=$(uuidgen)

echo > /opt/blu/gateblu-forever/meshblu.json
echo "{" >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"port\" : \"3000\"," >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"server\" : \"localhost\"," >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"uuid\" : \"$uuid\"," >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"token\" : \"${token//-/}\"," >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"tmpPath\" : \"tmp\"," >> /opt/blu/gateblu-forever/meshblu.json
echo "  \"nodePath\" : \"/usr/local/bin/node\"" >> /opt/blu/gateblu-forever/meshblu.json
echo "}" >> /opt/blu/gateblu-forever/meshblu.json

echo "Starting meshblu"
/usr/local/bin/node /opt/blu/meshblu/server.js --http > /dev/null &
meshblu_pid=$!
echo "giving time for start-up to complete.."
sleep 90

echo "Registering the gateway"
curl -XPOST http://localhost:3000/devices --data \
    "uuid=$uuid&token=${token//-/}&type=device:gateblu"
sleep 2
kill $meshblu_pid
	
# Start Gateblu from the directory
# npm start

# reboot the VM
sudo shutdown now -r

# On reboot the VM will be working.
# PowerShell verify it is running: Invoke-RestMethod -URI http://<IP address>:3000/status -ContentType "application/json" -Method Get
# The --unsafe-perm option is used as a workaround to npm and sudo and node-gyp: https://github.com/TooTallNate/node-gyp/issues/115

# there will be build errors with mosca, and then npm will retry and it should succeed on the retry.
