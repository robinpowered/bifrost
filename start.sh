#!/bin/sh

export NODE_ENV=production
export PATH=/usr/local/bin:$PATH
PI_HOME="/home/pi/"
BIFROST="bifrost"
RBN_PI="app"
FOREVER="forever"

cd ${PI_HOME}/${BIFROST} && sudo ${FOREVER} start ${RBN_PI}.js
