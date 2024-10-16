
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

struct Foo {
	char *name;
	int n;
};

struct Foo *clib_new(const char *name, int n);
const char *clib_foo_name(struct Foo *foo);
void clib_del(struct Foo *foo);

#ifdef __cplusplus
} // extern "C"
#endif
