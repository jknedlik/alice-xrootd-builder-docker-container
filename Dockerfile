# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service
FROM debian:latest
MAINTAINER jknedlik <j.knedlik@gsi.de>
RUN apt-get update
RUN apt-get install wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ -y
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
ADD http://alitorrent.cern.ch/src/xrd3/xrd3-installer /xrdinstall/xrd-installer.sh
RUN apt-get install wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ -y
RUN chmod a+x xrd-installer.sh
ENTRYPOINT ["/xrdinstall/xrd-installer.sh" ,"--install"] 
CMD ["--version=4.4.1", "--prefix=/opt/xrootd/xrootd-4.4.1-jessie-x86_64/"]

#RUN chef-client --local -j /chef/attributes/static.json -o recipe[alicet2_xrootd::xrootd-service]
#ONBUILD ADD ./ServiceRole.json /chef/roles/DefaultRole.json 
#ONBUILD RUN chef-client --local -j /chef/attributes/static.json -o "role[DefaultRole]"
# ONBUILD RUN chef-client -z -o /cookbook/recipes/default.rb #If we only need to run one recipe per service, and it can use same name on each service we can use this line



