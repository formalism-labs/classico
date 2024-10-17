
ROOT=..

CC_PROD=lib

SRCDIR=../..

define CC_SOURCES
	wd40/bb/bb.c
	cetara/diag/gdb.c
endef

define CC_INCLUDES
	../../..
endef

define CC_DEFS
	DEBUG
endef

BINDIR=$(BINROOT)/bb

CLASSICO=../..
include $(CLASSICO)/mk/main
