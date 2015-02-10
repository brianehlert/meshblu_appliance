This project contains scripts and configurations for running Meshblu as a standalone VM appliance.

All development / testing was performed using Ubuntu Server 14.04 / 14.10 - some features used may be specific to Ubuntu / automatically installed.
Modifications were made to handle Debian.

<Linux_distro>_meshblu.conf - this is the configuration to enable Meshblu with Uptime / sysvinit / Forever so that it runs properly as a service.
meshbluConfig.js - this is the configuration file for the Meshblu server and defines the connections to a locally installed Redis and MongoDB instance.  This works with all distros.
* All build scripts requires these two files for proper configuration.

gitAppliance.sh

This uses a base OS and pulls all requirements, including Meshblu, from repositories or GitHub.

Usage: 

* copy gitAppliance.sh and meshbluConfig.js to your home directory.  
* Also copy the <Linux_distro>_meshblu.conf of your flavor and rename it to 'meshblu.conf'
* Set executable permissions:  ```$ chmod +x gitAppliance.sh```
* Run the script:  ```$ ./gitAppliance.sh```

the su password will be prompted for and the script should handle the rest.

ubuntu_meshblu.sh

This functions just like the git script except that it assumes that you have already downloaded the Meshblu source to a Meshblu folder in your home directory.

Usage: 

* copy ubuntu_meshblu.sh, ubuntu_meshblu.conf, and meshbluConfig.js to your home directory.
* Set executable permissions:  ```$ chmod +x ubuntu_meshblu.sh```
* download the Meshblu source / mount the source at ~/meshblu
* Run the script:  ```$ ./ubuntu_meshblu.sh```

the su password will be prompted for and the script should handle the rest.

debian_meshblu.sh

This functions like ubuntu_meshblu.sh - in fact, take the instructions for ubuntu_meshblu.sh and replace 'ubuntu_meshblu.sh' with 'debian_meshblu.sh' and you will be golden.

This is specific to Debian.

The scripts reboot the VM at the end.

Once the VM is running again, you can verify that Meshblu is running using the REST command:

```Invoke-RestMethod -URI http://<your VM ip>:3000/status -ContentType "application/json" -Method Get```

You should get the return:
```meshblu                                                                                                                                                                           
-------                                                                                                                                                                           
online                                                                                                                                                                            
```
If not, verify the script path dependencies, and that the Meshblu service is running:
```sudo service meshblu status```

Forever will log to:  /var/log/meshblu

