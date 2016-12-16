#!/bin/bash
echo Adding changing ownership to current user
sudo chown -R jknedlik build/*
 echo Moving alice-install to a nice debpackage friendly layout
mv build/* build/usr
rm -r build/usr/etc
echo removing .la files
find ./build -type f -name '*.la' -exec rm {} +
echo stripping all .so libs of their debug symbols
strip --strip-debug --strip-unneeded build/usr/lib/*.so build/usr/lib64/*.so

echo stripping binaries of their debug symbols and removing rpath
for fn in `find build/ -type f -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary' | awk -F':' {'print $1'}` ;
do
	echo stripping $fn and removing its rpath
	strip --strip-debug --strip-unneeded $fn
	chrpath -r $fn
done

