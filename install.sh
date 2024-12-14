#!/bin/bash

#########################################################################################################################
#                                                                                                                       #
#                                                   QUICKSTART                                                          #
#                                                                                                                       #
#########################################################################################################################
#                                                                                                                       #
#   git clone https://github.com/4086449/docker-install.git                                                             #
#   cd docker-install                                                                                                   #              
#   git checkout dev                                                                                                    #              
#   ./install.sh                                                                                                        #
#                                                                                                                       #
#   OR                                                                                                                  #
#                                                                                                                       #
#   git clone https://github.com/4086449/docker-install.git && cd docker-install && git checkout dev && ./install.sh    #
#                                                                                                                       #
#########################################################################################################################

LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/install.log

### Stop on error
set -e
### Logfile
mkdir -p $LOGFOLDER
exec > >(tee -a $LOGFILE) 2>&1

./installPi.sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
source /home/$USER/.bashrc
./installDocker.sh

# Try first method
# (./installCompose.sh)
# (./installPortainer.sh)

# If that fails, try this method
newgrp docker << END
(./installCompose.sh)
(./installPortainer.sh)
END

exit 0
