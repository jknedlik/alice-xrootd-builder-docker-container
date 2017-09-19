all:changelog
	fakeroot dpkg-deb -v -b debian
changelog:
	mkdir -p debian/usr/share/doc/af-xrootd/
	cp changelog debian/usr/share/doc/af-xrootd/changelog
	cp copyright debian/usr/share/doc/af-xrootd/copyright
	cp conffiles debian/DEBIAN/conffiles
	gzip -n9f debian/usr/share/doc/af-xrootd/changelog
	chmod 0644 debian/usr/share/doc/af-xrootd/changelog.gz
test:all
	lintian debian.deb
clean:
	rm -rf debian.deb
allclean: clean
	rm -r debian/lib debian/usr

.PHONY: changelog
