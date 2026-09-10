#!/bin/bash

# Send a URL of the form secondlife://... to Second Life.
#

URL="$1"

if [ -z "$URL" ]; then
    echo Usage: $0 hop://...
    exit
fi

RUN_PATH=`dirname "$0" || echo .`
cd "${RUN_PATH}"

if [ `pidof do-not-directly-run-mare-viewer-bin` ]; then
    exec dbus-send --type=method_call --dest=com.mareviewer.ViewerAppAPIService /com/mareviewer/ViewerAppAPI com.mareviewer.ViewerAppAPI.GoSLURL string:"$1"
else
	exec ./mare-viewer -url \'"${URL}"\'
fi
