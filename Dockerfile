
# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service
ARG DEB_VER=debian:8.8
FROM $DEB_VER
MAINTAINER jknedlik <j.knedlik@gsi.de>
ARG DEB_VER=debian:8.8
RUN echo $DEB_VER
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y wget cmake libxml2 libssl-dev libxml2-dev  automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ debhelper dpkg lintian gzip chrpath patchelf zlib1g-dev zlib1g uuid-dev libssl-dev
#RUN  if [  "x$DEB_VER" = "xdebian:8.8" ] ; then apt-get install -y libssl-dev; else apt-get install -y libssl1.0-dev libssl1.0.2; fi
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN ls
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
RUN curl -O http://alitorrent.cern.ch/src/xrd3/xrd3-installer
RUN chmod a+x xrd3-installer
ARG XRD_VER

RUN ./xrd3-installer --install --version=$XRD_VER --prefix=/xrdinstall/xrootd


#Copy edited symlink source to /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
WORKDIR /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10
COPY xrootd-alicetokenacc/tokenauthz-1.1.10/TTokenAuthz.cxx /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10
COPY xrootd-alicetokenacc/tokenauthz-1.1.10/TTokenAuthz.h /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10
RUN rm /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10/TTokenAuthz.o
RUN  make && make install
#COPY xrootd-alicetokenacc/
WORKDIR /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
COPY xrootd-alicetokenacc/XrdAliceTokenAcc.hh /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
COPY xrootd-alicetokenacc/XrdAliceTokenAcc.cc /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
RUN rm /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5//XrdAliceTokenAcc.o
#Then run make
RUN  make && make install

WORKDIR /xrdinstall
ARG ADDITIONAL_VERSION_STRING
RUN mkdir build
#Now copy relevant files
RUN cp -r xrootd build/xrootd
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
COPY end.sh debianize.sh
RUN ./debianize.sh
CMD ["/bin/bash"]
RUN mkdir /xrdinstall/vol
COPY alice-xrootd-deb /xrdinstall/alice-xrootd-deb
COPY controlfiles/$DEB_VER  /xrdinstall/alice-xrootd-deb/debian/DEBIAN/control
RUN sed -i s/UPSTREAM_VERSION/${XRD_VER}/g /xrdinstall/alice-xrootd-deb/debian/DEBIAN/control
RUN echo "alice-xrootd (${XRD_VER}${ADDITIONAL_VERSION_STRING}) UNRELEASED; urgency=medium\n" >/xrdinstall/alice-xrootd-deb/changelog
RUN echo "  * Package has been built.\n" >>/xrdinstall/alice-xrootd-deb/changelog
RUN echo " -- Jan Knedlik <j.knedlik@gsi.de>  $(date -R)" >>/xrdinstall/alice-xrootd-deb/changelog
RUN cp -r /xrdinstall/build/* alice-xrootd-deb/debian/
RUN chmod 0755 /xrdinstall/alice-xrootd-deb/debian/DEBIAN/postinst /xrdinstall/alice-xrootd-deb/debian/DEBIAN/postrm
RUN make -C alice-xrootd-deb test
ENTRYPOINT ["cp"]

CMD ["alice-xrootd-deb/debian.deb","vol/alice-xrootd.deb"]
