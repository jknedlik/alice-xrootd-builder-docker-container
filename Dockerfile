# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service
FROM debian:latest
MAINTAINER jknedlik <j.knedlik@gsi.de>
RUN echo hallo
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y git wget cmake libxml2 libxml2-dev libssl-dev automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ debhelper dpkg lintian gzip chrpath patchelf
#softlink for alicetokenlib to find libcrypto in lib64 ...
RUN mkdir /usr/lib64 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib64/libcrypto.so
WORKDIR /xrdinstall
ARG XRD_VER
RUN git clone --branch local-file-impl https://github.com/xrootd/xrootd.git
COPY xrootdpatch /xrdinstall/xrootdpatch
RUN diff -u xrootd/src/XrdXrootd/XrdXrootdXeq.cc xrootdpatch/src/XrdXrootd/XrdXrootdXeq.cc > diff.txt; exit 0
RUN patch xrootd/src/XrdXrootd/XrdXrootdXeq.cc < diff.txt
RUN mkdir xrdbuild
RUN cd xrdbuild && cmake ../xrootd -DCMAKE_INSTALL_PREFIX=/paul-xrootd && make install -j 5
ARG ADDITIONAL_VERSION_STRING

RUN git clone https://github.com/pkramp/RedirPlugin.git
RUN cd RedirPlugin && export XROOTD_PATH=/paul-xrootd && cmake . -DCMAKE_INSTALL_PREFIX=/redir-plugin && make install

RUN mkdir build
RUN cp -r /paul-xrootd build/xrootd
RUN cp -r /redir-plugin/lib/* build/xrootd/lib
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
COPY end.sh debianize.sh
RUN ./debianize.sh
RUN mkdir /xrdinstall/vol
COPY alice-xrootd-deb /xrdinstall/paul-xrootd-deb
RUN sed -i s/UPSTREAM_VERSION/${XRD_VER}/g /xrdinstall/paul-xrootd-deb/debian/DEBIAN/control
RUN echo "paul-xrootd (${XRD_VER}${ADDITIONAL_VERSION_STRING}) UNRELEASED; urgency=medium\n" >/xrdinstall/paul-xrootd-deb/changelog
RUN echo "  * Package has been built.\n" >>/xrdinstall/paul-xrootd-deb/changelog
RUN echo " -- Jan Knedlik <j.knedlik@gsi.de>  $(date -R)" >>/xrdinstall/paul-xrootd-deb/changelog
RUN cp -r /xrdinstall/build/* paul-xrootd-deb/debian/
RUN chmod 0755 /xrdinstall/paul-xrootd-deb/debian/DEBIAN/postinst /xrdinstall/paul-xrootd-deb/debian/DEBIAN/postrm
RUN make -C paul-xrootd-deb test
ENTRYPOINT ["cp"]
CMD ["paul-xrootd-deb/debian.deb","vol/paul-xrootd.deb"]
