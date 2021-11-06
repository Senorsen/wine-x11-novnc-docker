#!/bin/bash

set -e

if [ "x$VNC_PASSWORD" = "x" ]; then
    echo "WARNING: No vnc password provided, server will be unprotected!"
    export VNC_PASSWD_PARAM="-nopw"
else
    echo "VNC password set."
    export VNC_PASSWD_PARAM="-passwd \"$VNC_PASSWORD\""
fi

exec $@
