all:changelog
	fakeroot dpkg-deb -v -b debian
changelog:
	mkdir -p debian/usr/share/doc/alice-xrootd/
	cp changelog debian/usr/share/doc/alice-xrootd/changelog
	cp copyright debian/usr/share/doc/alice-xrootd/copyright
	cp conffiles debian/DEBIAN/conffiles
	gzip -n9f debian/usr/share/doc/alice-xrootd/changelog
	chmod 0644 debian/usr/share/doc/alice-xrootd/changelog.gz
test:all
	lintian debian.deb
clean:
	rm -rf debian.deb
allclean: clean
	rm -r debian/lib debian/usr

.PHONY: changelog
