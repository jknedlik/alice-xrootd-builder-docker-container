# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service
FROM debian:8.7
MAINTAINER jknedlik <j.knedlik@gsi.de>
RUN echo hallo
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y git wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ debhelper dpkg lintian gzip chrpath patchelf
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
ARG XRD_VER
RUN git clone --branch stable-4.8.x https://github.com/xrootd/xrootd.git
RUN mkdir xrdbuild
RUN cd xrdbuild && cmake ../xrootd -DCMAKE_INSTALL_PREFIX=/af-xrootd && make install -j 5
ARG ADDITIONAL_VERSION_STRING
RUN git clone https://github.com/pkramp/RedirPlugin.git --branch kit-proj
#COPY RedirPlugin RedirPlugin
RUN cd RedirPlugin && export XROOTD_PATH=/af-xrootd && cmake . -DCMAKE_INSTALL_PREFIX=/redir-plugin && make install
RUN git clone https://github.com/jknedlik/XrdProxyPrefix --branch kit-proj
#COPY XrdProxyPrefix XrdProxyPrefix
RUN cd XrdProxyPrefix && export XROOTD_PATH=/af-xrootd && export XRD_PATH=/af-xrootd && make
RUN mkdir build
RUN cp -r /af-xrootd build/xrootd
RUN cp -r /redir-plugin/lib/* build/xrootd/lib
RUN cp -r XrdProxyPrefix/XrdProxyPrefix.so build/xrootd/lib
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
COPY end.sh debianize.sh
RUN ./debianize.sh
RUN mkdir /xrdinstall/vol
COPY alice-xrootd-deb /xrdinstall/af-xrootd-deb
RUN sed -i s/UPSTREAM_VERSION/${XRD_VER}/g /xrdinstall/af-xrootd-deb/debian/DEBIAN/control
RUN echo "af-xrootd (${XRD_VER}${ADDITIONAL_VERSION_STRING}) UNRELEASED; urgency=medium\n" >/xrdinstall/af-xrootd-deb/changelog
RUN echo "  * Package has been built.\n" >>/xrdinstall/af-xrootd-deb/changelog
RUN echo " -- Jan Knedlik <j.knedlik@gsi.de>  $(date -R)" >>/xrdinstall/af-xrootd-deb/changelog
RUN cp -r /xrdinstall/build/* af-xrootd-deb/debian/
RUN chmod 0755 /xrdinstall/af-xrootd-deb/debian/DEBIAN/postinst /xrdinstall/af-xrootd-deb/debian/DEBIAN/postrm
RUN make -C af-xrootd-deb test
ENTRYPOINT ["cp"]
CMD ["af-xrootd-deb/debian.deb","vol/af-xrootd.deb"]
