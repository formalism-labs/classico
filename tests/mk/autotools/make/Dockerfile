FROM ubuntu:noble

SHELL ["/bin/bash", "-l", "-c"]

WORKDIR /build

ADD . classico

RUN ./classico/bin/getget
RUN ./classico/bin/getpy
RUN ./classico/bin/getgcc
RUN ./classico/bin/getautotools --modern

RUN apt-get install -y git make pkg-config texinfo autopoint

WORKDIR /build/classico/tests/mk/autotools/make

RUN make fetch
RUN mkdir build

WORKDIR /build/classico/tests/mk/autotools/make/make
RUN ./bootstrap

WORKDIR /build/classico/tests/mk/autotools/make/build
RUN ../make/configure --without-guile
RUN make -j
