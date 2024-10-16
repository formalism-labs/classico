
#include "clib.h"

#include <stdlib.h>
#include <string.h>

#ifdef __cpluscplus
extern "C" {
#endif
	
Foo *clib_new(const char *name, int n) {
	Foo *foo = new Foo;
	foo->name = strdup(name);
	foo->n = n;
	return foo;
}

const char *clib_foo_name(struct Foo *foo) {
	return foo ? foo->name : "";
}

void clib_del(Foo *foo) {
	free(foo->name);
	delete foo;
}

#ifdef __cpluscplus
} // extern "C"
#endif
