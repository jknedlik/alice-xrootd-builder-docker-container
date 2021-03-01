#!/bin/bash
DEB_VER="10.8" #switch to 9.5 or 8.8
docker rm xrootdBuilder-$DEB_VER &>/dev/null
docker build --tag xrootdbuilder-$DEB_VER:0.1 --tag xrootdbuilder-$DEB_VER:latest --build-arg XRD_VER="4.12.6" --build-arg DEB_VER="debian:$DEB_VER" --build-arg ADDITIONAL_VERSION_STRING="-gsi-2" .
docker run -v $PWD/build:/xrdinstall/vol  --name "xrootdBuilder-$DEB_VER" -i -t xrootdbuilder-$DEB_VER:latest
if [ $DEB_VER == "8.8" ] ; then mv build/alice-xrootd.deb build/alice-xrootd-debian8.deb; fi
if [ $DEB_VER == "9.5" ] ; then mv build/alice-xrootd.deb build/alice-xrootd-debian9.deb; fi
if [ $DEB_VER == "10.8" ] ; then mv build/alice-xrootd.deb build/alice-xrootd-debian10.deb; fi
