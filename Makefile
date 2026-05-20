PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
ZSHCOMPDIR ?= $(PREFIX)/share/zsh/site-functions
BASHCOMPDIR ?= $(PREFIX)/share/bash-completion/completions

all: kewt

kewt:
	./tools/build-standalone.sh

install: kewt
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 kewt $(DESTDIR)$(BINDIR)/kewt
	install -d $(DESTDIR)$(ZSHCOMPDIR)
	install -m 644 packaging/zsh/_kewt $(DESTDIR)$(ZSHCOMPDIR)/_kewt
	install -d $(DESTDIR)$(BASHCOMPDIR)
	install -m 644 packaging/bash/kewt.bash $(DESTDIR)$(BASHCOMPDIR)/kewt

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/kewt
	rm -f $(DESTDIR)$(ZSHCOMPDIR)/_kewt
	rm -f $(DESTDIR)$(BASHCOMPDIR)/kewt

clean:
	rm -f kewt kewt-*.tar.gz

dist:
	$(eval VERSION := $(shell git describe --tags --always | sed 's/^v//;s/-/./g'))
	tar -czf kewt-$(VERSION).tar.gz --exclude-vcs --exclude=kewt --exclude=kewt-$(VERSION).tar.gz --transform "s|^|kewt-$(VERSION)/|" *

srpm: dist
	$(eval VERSION := $(shell git describe --tags --always | sed 's/^v//;s/-/./g'))
	sed -e "s/VERSION_PLACEHOLDER/$(VERSION)/g" packaging/fedora/kewt.spec.template > packaging/fedora/kewt.spec
	rpmbuild -bs --define "_sourcedir $(PWD)" --define "_srcrpmdir $(PWD)" packaging/fedora/kewt.spec

test:
	sh tests/test_runner.sh

shellcheck:
	shellcheck kewt.sh markdown.sh lib/*.sh

.PHONY: all install uninstall clean test shellcheck
