#!/usr/bin/make -f
INSTALL ?= install
PREFIX ?= /usr/local
MANPAGES ?= py3compile.1 py3clean.1
VERSION=$(shell dpkg-parsechangelog | sed -rne 's,^Version: (.+),\1,p')

clean:
	find . -name '*.py[co]' -delete
	find . -name __pycache__ -type d | xargs rm -rf
	rm -f .coverage $(MANPAGES)

install-dev:
	$(INSTALL) -m 755 -d $(DESTDIR)$(PREFIX)/bin \
		$(DESTDIR)$(PREFIX)/share/python3/runtime.d
	$(INSTALL) -m 755 runtime.d/* $(DESTDIR)$(PREFIX)/share/python3/runtime.d/

install-runtime:
	$(INSTALL) -m 755 -d $(DESTDIR)$(PREFIX)/share/python3/debpython $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -m 644 debpython/*.py $(DESTDIR)$(PREFIX)/share/python3/debpython/
	$(INSTALL) -m 755 py3compile $(DESTDIR)$(PREFIX)/bin/
	sed -i -e 's/DEVELV/$(VERSION)/' $(DESTDIR)$(PREFIX)/bin/py3compile
	$(INSTALL) -m 755 py3clean $(DESTDIR)$(PREFIX)/bin/
	sed -i -e 's/DEVELV/$(VERSION)/' $(DESTDIR)$(PREFIX)/bin/py3clean

install: install-dev install-runtime

%.1: %.rst
	rst2man $< > $@

manpages: $(MANPAGES)

sbuild:
	sbuild --debbuildopts -I

# TESTS
tests:
	nosetests3 --with-doctest --with-coverage

check_versions:
	@PYTHONPATH=. set -ex; \
	SUPPORTED=`sed -rn 's|^supported-versions = (.*)|\1|p' debian/debian_defaults | sed 's/python//g;s/,//g'`;\
	MIN_SUPPORTED=$${SUPPORTED%% *};\
	MAX_SUPPORTED=$${SUPPORTED##* };\
	grep -Fq "python3-supported-min (= $$MIN_SUPPORTED)" debian/control || \
	(echo 'Please update python3-supported-min in debian/control.in' >/dev/stderr; false);\
	grep -Fq "python3-supported-max (= $$MAX_SUPPORTED)" debian/control || \
	(echo 'Please update python3-supported-max in debian/control.in' >/dev/stderr; false)


.PHONY: clean tests test% check_versions
