#!/bin/bash
docker rm xrootdBuilder &>/dev/null
docker build --tag xrootdbuilder:0.1 --tag xrootdbuilder:latest --build-arg XRD_VER="4.5.0" --build-arg ADDITIONAL_VERSION_STRING="-gsi-1" .
docker run -v $PWD/build:/xrdinstall/vol  --name "xrootdBuilder" -i -t xrootdbuilder:latest
