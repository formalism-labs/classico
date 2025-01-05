
#include "clib.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef __cpluscplus
extern "C" {
#endif
	
Foo *clib_new_foo(const char *name, int n) {
	Foo *foo = new Foo;
	foo->name = strdup(name);
	foo->n = n;
	return foo;
}

const char *clib_foo_name(struct Foo *foo) {
	return foo ? foo->name : "";
}

void clib_del_foo(Foo *foo) {
	free(foo->name);
	delete foo;
}

typedef struct Bar Bar; // opaque

extern "C" char *get_bar_text(const Bar *bar);
extern "C" void free_bar_text(char *text);

typedef void (*BarCallback)(Bar*);

extern "C" void bar_c_operation(BarCallback bar_cb, Bar *bar) {
    if (bar_cb && bar) {
        printf("bar_c_operation: Calling Rust callback...\n");
        bar_cb(bar);
		char *bar_text = get_bar_text(bar);
		printf("bar.text (from C): %s\n", bar_text);
        printf("bar_c_operation: Finished calling Rust callback.\n");
		free_bar_text(bar_text);
    }
}

#ifdef __cpluscplus
} // extern "C"
#endif
