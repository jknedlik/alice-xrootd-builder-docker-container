#!/bin/bash
#echo Changing ownership to current user: $USER
# chown -R $USER build/*
echo Moving alice-install to a nice debian package friendly layout
  mv build/* build/usr
  #mkdir build/usr/bin/af-xrootd
  #mv build/usr/bin/* build/usr/bin/af-xrootd
  mv build/usr/share/xrootd build/usr/share/af-xrootd
  mv build/usr/include/xrootd build/usr/include/af-xrootd
# rm -r build/usr/etc
#  rm -r build/usr/share/doc
#  mv build/usr/lib64/* build/usr/lib/
#  rm -r build/usr/lib64
  mkdir build/usr/lib/af-xrootd
  mv build/usr/lib/* build/usr/lib/af-xrootd
echo removing .la files
  find ./build -type f -name '*.la' -exec rm {} +
echo stripping binaries and shared libraries of their debug symbols and setting rpath
for fn in `find build/usr/lib  -exec file -i '{}' \; |grep x-sharedlib | awk -F':' {'print $1'};`
do
  echo  "  Stripping $fn and setting rpath to /usr/lib/af-xrootd"
  strip --strip-debug --strip-unneeded $fn
  patchelf --set-rpath /usr/lib/af-xrootd $fn
  chmod a-x $fn
done
for fn in `find build/ -type f -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary' | awk -F':' {'print $1'}` ;
do
  echo  "   Stripping $fn and setting its rpath"
  strip --strip-debug --strip-unneeded $fn
  patchelf --set-rpath /usr/lib/af-xrootd $fn
done


echo gzipping info and manpages, removing xrdcopy softlink first
  rm build/usr/share/man/man*/*
  #gzip -9n   build/usr/share/man/man*/*
echo Moving ApMon perl headers to usr/lib/perl5/
#  mkdir -p build/usr/share/perl5
  mkdir -p build/etc/logrotate.d
  mv config/config/logrotate-xrootd.conf build/etc/logrotate.d/af-xrootd
echo Moving Unit-files to correct path
  mkdir -p build/lib/systemd/system
  cp service/* build/lib/systemd/system/
echo Moving default config files to correct path
  mkdir -p build/etc/af-xrootd/
  cp config/config/* build/etc/af-xrootd
echo Creating lintian overrides for xrdinstaller problems that cannot be fixed
  cp -r lintian build/usr/share/lintian


mv build/usr/bin/af-xrootd/* build/usr/bin

#echo Removing scripts dir and xrd.sh :\)
  #rm -r build/usr/scripts
echo Creating /var/log/af-xrootd
  mkdir -p build/var/log/af-xrootd
