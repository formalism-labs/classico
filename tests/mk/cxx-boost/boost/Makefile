MK.conan=1

ROOT=..

BINDIR=$(BINROOT)/boost

MK_CUSTOM_CLEAN=1

define CONAN_PROFILE_CC.gcc
compiler=gcc
compiler.cppstd=gnu17
compiler.libcxx=libstdc++11
compiler.version=11
endef

define CONAN_PROFILE_CC.clang.linux
compiler=clang
compiler.cppstd=20
compiler.libcxx=libc++
compiler.version=19
endef

define CONAN_PROFILE_CC.clang
compiler=apple-clang
compiler.cppstd=gnu17
compiler.libcxx=libc++
compiler.version=13
endef

CLASSICO=../../../..
include $(CLASSICO)/mk/main

custom-clean:
	$(SHOW)rm -rf $(BINDIR)
ifeq ($(CACHE),1)
	$(SHOW)rm -rf $$HOME/.conan2
endif
