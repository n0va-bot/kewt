PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

all: kewt

kewt:
	./tools/build-standalone.sh

install: kewt
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 kewt $(DESTDIR)$(BINDIR)/kewt

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/kewt

clean:
	rm -f kewt

.PHONY: all install uninstall clean
