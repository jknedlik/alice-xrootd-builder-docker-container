#!/bin/bash
docker rm xrootdBuilder &>/dev/null
docker build --tag xrootdbuilder:0.1 --tag xrootdbuilder:latest --build-arg XRD_VER="4.8.4" --build-arg DEB_VER="debian:8.8" --build-arg ADDITIONAL_VERSION_STRING="-gsi-2" .
docker run -v $PWD/build:/xrdinstall/vol  --name "xrootdBuilder" -i -t xrootdbuilder:latest
