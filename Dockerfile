# -*- docker-image-name: "xrootd_base" -*-
# xrootd base image. Provides the base image for each xrootd service

ARG DEB_VER
FROM $DEB_VER
MAINTAINER pkramp <p.n.kramp@gsi.de>
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y wget cmake libxml2 libxml2-dev  automake autoconf libtool curl libcurl4-gnutls-dev libkrb5-3 gcc g++ debhelper dpkg lintian gzip chrpath patchelf zlib1g-dev zlib1g uuid-dev unzip pkg-config sqlite3 libsqlite3-dev
RUN apt-get install -y libssl-dev libkrb5-dev build-essential voms-dev lcmaps-plugins-jobrep voms-server lcmaps-plugins-voms lcmaps-globus-interface
RUN apt-get update

#GTEST
RUN mkdir gtest
WORKDIR /xrdinstall/gtest
RUN curl -L https://github.com/google/googletest/archive/v1.10.x.zip -o gtestv1.10.x.zip
RUN unzip "gtestv1.10.x.zip"
RUN mv googletest-1.10.x/* .
RUN mkdir build && cd build && cmake ../ && ls && make -j 8 && make install

#JWT
RUN mkdir jwt
WORKDIR /xrdinstall/jwt
RUN curl -L https://github.com/Thalhammer/jwt-cpp/archive/v0.5.1.zip -o jwtv0.5.1.zip
RUN unzip "jwtv0.5.1.zip"
RUN cd jwt-cpp-0.5.1/ && cmake . && make -j 8 && ls &&  make install
ARG ADDITIONAL_VERSION_STRING

#SCITOKENS-CPP
RUN mkdir scitokens-cpp
WORKDIR /xrdinstall/scitokens-cpp
RUN curl -L https://github.com/scitokens/scitokens-cpp/archive/v0.6.3.zip -o scitokens-cpp.zip
RUN unzip "scitokens-cpp.zip"
RUN mv scitokens-cpp-0.6.3/* .
RUN mkdir build && cd build && cmake ../ && ls && make -j 8 && make install
RUN rm -rf build && mkdir build && cd build && cmake ../ -DCMAKE_INSTALL_PREFIX=/xrdinstall/xrootd && ls && make -j 8 && make install

# XROOTD
WORKDIR /xrdinstall
RUN curl -L -O https://github.com/xrootd/xrootd/archive/v5.3.1.tar.gz
RUN tar -xzf v5.3.1.tar.gz
RUN ls
RUN mv xrootd-5.3.1/* .
RUN mkdir build && cd build && cmake ../ -DCMAKE_INSTALL_PREFIX=/xrdinstall/xrootd && make -j 8 && make install
RUN rm -rf build
RUN mkdir build && cd build && cmake ../ && make -j 8 && make install
ARG ADDITIONAL_VERSION_STRING

#RUN find / -iname "*libXrdAccSciTokens*"

#XROOTD-LCMAPS
RUN mkdir xrootd-lcmaps
WORKDIR /xrdinstall/xrootd-lcmaps
RUN curl -L https://github.com/opensciencegrid/xrootd-lcmaps/archive/v1.7.8-2.zip -o xrootd-lcmaps.zip
RUN unzip "xrootd-lcmaps.zip"
RUN mv xrootd-lcmaps-1.7.8-2/* .
RUN echo "#include <string.h>\n" |cat - /xrdinstall/xrootd-lcmaps/src/XrdHttpLcmaps.cc > /tmp/out && mv /tmp/out /xrdinstall/xrootd-lcmaps/src/XrdHttpLcmaps.cc
RUN mkdir build && cd build && cmake ../ -DCMAKE_INSTALL_PREFIX=/xrdinstall/xrootd && ls && make -j 8 && make install

# back to XRootD
WORKDIR /xrdinstall
RUN ls -la xrootd
RUN ls -la build
RUN ls -la
RUN cp -r xrootd build/xrootd
COPY service /xrdinstall/service
COPY config /xrdinstall/config
COPY lintian /xrdinstall/lintian
COPY end.sh debianize.sh
RUN ./debianize.sh
CMD ["/bin/bash"]
RUN mkdir /xrdinstall/vol
COPY escape-xrootd-deb /xrdinstall/escape-xrootd-deb
ARG DEB_VER
COPY controlfiles/$DEB_VER  /xrdinstall/escape-xrootd-deb/debian/DEBIAN/control
ARG XRD_VER
RUN sed -i s/UPSTREAM_VERSION/${XRD_VER}/g /xrdinstall/escape-xrootd-deb/debian/DEBIAN/control
RUN echo "escape-xrootd (${XRD_VER}${ADDITIONAL_VERSION_STRING}) UNRELEASED; urgency=medium\n" >/xrdinstall/escape-xrootd-deb/changelog
RUN echo "  * Package has been built.\n" >>/xrdinstall/escape-xrootd-deb/changelog
RUN echo " -- Paul-Niklas Kramp <p.kramp@gsi.de>  $(date -R)" >>/xrdinstall/escape-xrootd-deb/changelog
RUN cp -r /xrdinstall/build/* escape-xrootd-deb/debian/
RUN chmod 0755 /xrdinstall/escape-xrootd-deb/debian/DEBIAN/postinst /xrdinstall/escape-xrootd-deb/debian/DEBIAN/postrm
RUN make -C escape-xrootd-deb
ENTRYPOINT ["cp"]
CMD ["escape-xrootd-deb/debian.deb","vol/escape-xrootd.deb"]
