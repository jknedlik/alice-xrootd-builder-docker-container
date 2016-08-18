#!/bin/bash
sudo docker build -t xrootdbuilder:0.1 -t xrootdbuilder:latest .
docker rm xrootdBuilder &>/dev/null
docker run -v $PWD/build:/opt/xrootd  --name "xrootdBuilder" -i -t xrootdbuilder:latest
