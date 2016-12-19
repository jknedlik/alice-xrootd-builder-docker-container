#!/bin/bash
echo Changing ownership to current user: $USER
sudo chown -R $USER build/*
echo Moving alice-install to a nice debian package friendly layout
  mv build/* build/usr
  rm -r build/usr/etc
  rm -r build/usr/share/doc
  mv build/usr/lib64/* build/usr/lib/
  rm -r build/usr/lib64
  mkdir build/usr/lib/alice-xrootd
  mv build/usr/lib/* build/usr/lib/alice-xrootd
echo removing .la files
  find ./build -type f -name '*.la' -exec rm {} +
echo stripping binaries of their debug symbols and setting rpath
for fn in `find build/usr/lib  -exec file -i '{}' \; |grep x-sharedlib | awk -F':' {'print $1'};`
do
  echo  "  Stripping $fn and setting rpath to /usr/lib/alice-xrootd"
  strip --strip-debug --strip-unneeded $fn
    patchelf --set-rpath /usr/lib/alice-xrootd $fn
  chmod a-x $fn
done
  for fn in `find build/ -type f -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary' | awk -F':' {'print $1'}` ;
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
  mv build/usr/scripts/ApMon build/usr/share/perl5/ApMon
echo Moving Unit-files to correct path
  mkdir -p build/lib/systemd/system
  cp service/* build/lib/systemd/system/
echo Removing scripts dir and xrd.sh :\)
  rm -r build/usr/scripts
