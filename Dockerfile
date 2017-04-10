# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service
FROM debian:latest
MAINTAINER jknedlik <j.knedlik@gsi.de>
RUN apt-get update
RUN apt-get install wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ -y
RUN apt-get install -y debhelper dpkg lintian gzip
RUN apt-get install chrpath patchelf -y
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
RUN curl -O http://alitorrent.cern.ch/src/xrd3/xrd3-installer
RUN apt-get install wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ -y
RUN chmod a+x xrd3-installer
ARG XRD_VER
ENV XRD_VER ${XRD_VER:-4.5.0}
RUN ./xrd3-installer --install --version=$XRD_VER --prefix=/xrdinstall/xrootd
RUN mkdir build
RUN cp -r xrootd build/xrootd
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
COPY end.sh debianize.sh
RUN ./debianize.sh
RUN mkdir /xrdinstall/vol
COPY alice-xrootd-deb /xrdinstall/alice-xrootd-deb
RUN chmod 0755 /xrdinstall/alice-xrootd-deb/debian/DEBIAN/postinst
RUN cp -r /xrdinstall/build/* alice-xrootd-deb/debian/
RUN make -C alice-xrootd-deb test
ENTRYPOINT ["cp"]
CMD ["alice-xrootd-deb/debian.deb","vol/alice-xrootd.deb"]
