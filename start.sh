#!/bin/bash
DEB_VERSION="10.8" #switch to 9.5 or 8.8
docker rm xrootdBuilder-$DEB_VERSION &>/dev/null
docker build --tag xrootdbuilder-$DEB_VERSION:0.1 --tag xrootdbuilder-$DEB_VERSION:latest --build-arg XRD_VER="5.1.1" --build-arg DEB_VER="debian:$DEB_VERSION" --build-arg ADDITIONAL_VERSION_STRING="-gsi-3" .
docker run -v $PWD/build:/xrdinstall/vol  --name "xrootdBuilder-$DEB_VERSION" -i -t xrootdbuilder-$DEB_VERSION:latest
if [ $DEB_VERSION == "8.8" ] ; then mv build/escape-xrootd.deb build/escape-xrootd-debian8.deb; fi
if [ $DEB_VERSION == "9.13" ] ; then mv build/escape-xrootd.deb build/escape-xrootd-debian9.deb; fi
if [ $DEB_VERSION == "10.8" ] ; then mv build/alice-xrootd.deb build/alice-xrootd-debian10.deb; fi
