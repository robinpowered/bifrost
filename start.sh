#!/bin/sh

export NODE_ENV=production
export PATH=/usr/local/bin:$PATH
PI_HOME="/home/pi/"
RBN_PI="rbn-pi"
RBN_PI_JS="${PI_HOME}/${RBN_PI}/${RBN_PI}.js"
FOREVER="forever"

sudo ${FOREVER} start ${RBN_PI_JS}

