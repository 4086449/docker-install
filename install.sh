#!/usr/bin/bash

### Stop on error
set -e

cd ~/docker-install/
./installDocker.sh
./installPortainer.sh
exit 0
