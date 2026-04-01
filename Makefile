PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
ZSHCOMPDIR ?= $(PREFIX)/share/zsh/site-functions

all: kewt

kewt:
	./tools/build-standalone.sh

install: kewt
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 kewt $(DESTDIR)$(BINDIR)/kewt
	install -d $(DESTDIR)$(ZSHCOMPDIR)
	install -m 644 packaging/zsh/_kewt $(DESTDIR)$(ZSHCOMPDIR)/_kewt

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/kewt
	rm -f $(DESTDIR)$(ZSHCOMPDIR)/_kewt

clean:
	rm -f kewt

.PHONY: all install uninstall clean
