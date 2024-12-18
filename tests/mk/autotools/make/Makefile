
MK.configure=1

MAKE_TAG=4.4.1

SRCDIR=make

TARGET=$(BINDIR)/make

AUTOGEN_CMD=./bootstrap
CONFIGURE_FLAGS += --without-guile

export GNULIB_SRCDIR=$(CURDIR)/gnulib

CLASSICO=../../../..
include $(CLASSICO)/mk/main

fetch:
	$(SHOW)git clone -b $(MAKE_TAG) https://git.savannah.gnu.org/git/make.git $(SRCDIR)
#	$(SHOW)git clone https://git.savannah.gnu.org/git/gnulib.git

docker:
	$(SHOW)cd $(CLASSICO); docker build -f tests/mk/autotools/make/Dockerfile -t gnu-make .

.PHONY: fetch docker
