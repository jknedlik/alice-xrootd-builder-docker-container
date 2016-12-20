#!/bin/bash
docker rm xrootdBuilder &>/dev/null
docker build  --build-arg XRD_VER=4.4.1 -t xrootdbuilder:0.1 -t xrootdbuilder:latest . 
docker run -v $PWD/build:/xrdinstall/vol  --name "xrootdBuilder" -i -t xrootdbuilder:latest
