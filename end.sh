#!/bin/bash
#echo Changing ownership to current user: $USER
# chown -R $USER build/*
echo Moving alice-install to a nice debian package friendly layout
  mv build/* build/usr
  rm -r build/usr/etc
  rm -r build/usr/share/doc
  mv build/usr/lib64/* build/usr/lib/
  rm -r build/usr/lib64
  mkdir build/usr/lib/alice-xrootd
  mv build/usr/lib/* build/usr/lib/alice-xrootd
  rm build/usr/bin/autoconf
echo removing .la files
  find ./build -type f -name '*.la' -exec rm {} +
echo stripping binaries and shared libraries of their debug symbols and setting rpath
for fn in `find build/usr/lib  -exec file -i '{}' \; |grep x-sharedlib | awk -F':' {'print $1'};`
do
  echo  "  Stripping $fn and setting rpath to /usr/lib/alice-xrootd"
  strip --strip-debug --strip-unneeded $fn
  patchelf --set-rpath /usr/lib/alice-xrootd $fn
  chmod a-x $fn
done
for fn in `find build/usr/bin -type f -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary\|application/x-sharedlib; charset=binary' | awk -F':' {'print $1'}` ;
do
  echo  "   Stripping $fn and setting its rpath"
  strip --strip-debug --strip-unneeded $fn
  patchelf --set-rpath /usr/lib/alice-xrootd $fn
done
echo gzipping info and manpages, removing xrdcopy softlink first
  rm build/usr/share/man/man1/xrdcopy.1
  gzip -9n build/usr/share/info/*.info*  build/usr/share/man/man*/*
echo Moving ApMon perl headers to usr/lib/perl5/
  mkdir -p build/usr/share/perl5
  rm build/usr/scripts/ApMon/*.sh
  mv build/usr/scripts/ApMon/* build/usr/share/perl5/
  mv config/config/apmon.pl build/usr/bin/apmon
  mkdir -p build/etc/logrotate.d
  mv config/config/logrotate-xrootd.conf build/etc/logrotate.d/xrootd
echo Moving Unit-files to correct path
  mkdir -p build/lib/systemd/system
  cp service/* build/lib/systemd/system/
echo Moving default config files to correct path
  mkdir -p build/etc/xrootd/
  cp config/config/* build/etc/xrootd
echo Creating lintian overrides for xrdinstaller problems that cannot be fixed
  cp -r lintian build/usr/share/lintian
echo Removing scripts dir and xrd.sh :\)
  rm -r build/usr/scripts
echo Creating /var/log/xrootd
  mkdir -p build/var/log/xrootd
