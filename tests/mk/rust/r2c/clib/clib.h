
#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

struct Foo {
	char *name;
	int n;
};

struct Foo *clib_new_foo(const char *name, int n);
const char *clib_foo_name(struct Foo *foo);
void clib_del_foo(struct Foo *foo);

#ifdef __cplusplus
} // extern "C"
#endif
