#!/bin/sh

export NODE_ENV=production
export PATH=/usr/local/bin:$PATH
PI_HOME="/home/pi/"
RBN_PI="rbn-pi"
FOREVER="forever"

cd ${PI_HOME}/${RBN_PI} && sudo ${FOREVER} start ${RBN_PI}.js

