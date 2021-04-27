
# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service

ARG DEB_VER
FROM $DEB_VER
MAINTAINER jknedlik <j.knedlik@gsi.de>
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y git wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ debhelper dpkg lintian gzip chrpath patchelf zlib1g-dev zlib1g uuid-dev
RUN if [  "x$DEB_VER" = "xdebian:9.5" ] ; then apt-get install -y libssl1.0-dev libssl1.0.2; else apt-get install -y libssl-dev; fi
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
RUN curl -O http://alitorrent.cern.ch/src/xrd3/xrd3-installer
# Comment in to see build-failures:
ARG DEB_VER
COPY xrd3-installer-debug /tmp/xrd3-installer
# we need the custom xrd-installer for buster
RUN if [ "x$DEB_VER" = "xdebian:10.8" ]; then cp /tmp/xrd3-installer xrd3-installer; fi
RUN chmod a+x xrd3-installer
ARG XRD_VER
WORKDIR /xrdinstall
# in case we need the openssl1.1 version for buster, copy it over 
COPY xrootd-alicetokenacc/tokenauthz-custom-openssl1.1/ /tmp/tokenauthz-custom-openssl1.1
# we run the custom xrd-installer for Buster, and the original one for stretch/jessie
RUN ./xrd3-installer --install --version=$XRD_VER --prefix=/xrdinstall/xrootd
# Copy edited symlink source to /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
WORKDIR /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10
# in case of jessie/stretch, copy non-openssl1.1 version
COPY xrootd-alicetokenacc/tokenauthz-1.1.10/TTokenAuthz.cxx /tmp/TTokenAuthz.cxx
COPY xrootd-alicetokenacc/tokenauthz-1.1.10/TTokenAuthz.h /tmp/TTokenAuthz.h
# Remake the libtokenauthz without openssl 1.1
RUN  if [  "x$DEB_VER" = "xdebian:9.5" ]  || [  "x$DEB_VER" = "xdebian:8.8" ];\
 then cp /tmp/TTokenAuthz.* /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10 && \
 rm /tmp/xrd-installer-/libtokenauthz/tokenauthz-1.1.10/TTokenAuthz.o \
 && make clean && make && make install; fi
# copy custom alicetokenacc-sources with symlink feature
WORKDIR /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
COPY xrootd-alicetokenacc/XrdAliceTokenAcc.hh /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
COPY xrootd-alicetokenacc/XrdAliceTokenAcc.cc /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5
RUN rm /tmp/xrd-installer-/alicetokenacc/xrootd-alicetokenacc-1.2.5//XrdAliceTokenAcc.o
#Then run make
RUN make clean && make && make install

WORKDIR /xrdinstall
ARG ADDITIONAL_VERSION_STRING
RUN mkdir build
#Now copy relevant files
RUN cp -r xrootd build/xrootd
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
#build lustre
RUN apt-get install -y linux-headers-amd64 libyaml-dev
RUN git clone --branch 2.12.4 --depth 1 --single-branch git://git.whamcloud.com/fs/lustre-release.git
RUN cd lustre-release && git checkout 2.12.4 && sh autogen.sh && ./configure --disable-modules --prefix /lustre
RUN cd lustre-release && make -j8 
RUN cd lustre-release && make install
#build LibXrdLustreOss.so
RUN git clone --branch master --depth 1 --single-branch https://github.com/jknedlik/XrdLustreOssWrapper
RUN cd XrdLustreOssWrapper/src && LIBRARY_PATH=/xrdinstall/xrootd/lib64 XRD_PATH=/xrdinstall/xrootd LUSTRE_PATH=/lustre make
RUN cp XrdLustreOssWrapper/src/LibXrdLustreOss.so* /xrdinstall/build/xrootd/lib
# debianize the heck out of it
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
