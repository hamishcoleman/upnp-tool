
NAME := upnptool
INSTALLROOT := installdir
INSTALLDIR := $(INSTALLROOT)/usr/local/lib/site_perl

describe := $(shell git describe --dirty)
tarfile := $(NAME)-$(describe).tar.gz

all:    test

build_dep:
	aptitude install libnet-upnp-perl

install: clean
	mkdir -p $(INSTALLDIR)
	echo install -p test_harness $(INSTALLDIR)
	echo cp -pr HC $(INSTALLDIR)

tar:    $(tarfile)

$(tarfile):
	$(MAKE) install
	tar -v -c -z -C $(INSTALLROOT) -f $(tarfile) .

clean:
	rm -rf $(INSTALLROOT)

cover:
	cover -delete
	-COVER=true $(MAKE) test
	cover

test:
	~/s/bin/lib/test_harness

