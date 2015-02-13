#!/bin/sh 
# Ubuntu 14.10
# Copy the Meshblu tarball
# copy this script
# set the permissions:  chmod +x install.sh
# run the script (without sudo):  ./install.sh
# This requires an internet connection to pull source.

# verify that Meshblu exists
if [ ! -f /var/blu/meshblu/server.js ] ; then
    echo "Meshblu server.js does not exist"
fi

# add permissions so things will work properly
sudo chmod -R ugo+rw /var/blu

# kill the meshblu service


# Extract the meshblu build to /var/blu
cd /var/www
tar -xzvf ~/*.tgz --overwrite
mv package meshblu

# copy the forever configuration  "forever start server.js --http"
sudo cp ~/ubuntu_meshblu.conf /etc/init/meshblu.conf

# set the appliance specific server.js config
sudo cp ~/meshbluConfig.js /var/blu/meshblu/config.js

# install Meshblu
cd /var/blu/meshblu
sudo npm install --production --loglevel warn

# Meshblu listener ports: 3000 (Meshblu) 5683 (CoAP) 1883 (MQTT) 
# Services listener ports:  6379 (redis) 27017 (MongoDB)

# reboot the VM
sudo shutdown now -r

# On reboot the VM will be working.
# PowerShell verify it is running: Invoke-RestMethod -URI http://<IP address>:3000/status -ContentType "application/json" -Method Get
