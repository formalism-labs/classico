
MK.cmake=1

MODULE_NAME=p1
CC_PROD=prog

#----------------------------------------------------

CLASSICO=../../..
include $(CLASSICO)/mk/main

#----------------------------------------------------

MISSING_DEPS:=

export BOOST_BINDIR:=$(BINROOT)/boost
include boost/Makefile.defs

ifeq ($(wildcard $(BOOST_PRESETS)),)
MISSING_DEPS += $(BOOST_PRESETS)
endif

ifneq ($(MISSING_DEPS),)
DEPS=1
endif

DEPENDENCIES=boost

ifneq ($(filter all deps $(DEPENDENCIES),$(MAKECMDGOALS)),)
DEPS=1
endif

.PHONY: deps $(DEPENDENCIES)
