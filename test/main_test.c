#include "common.h"
#include "main.h"

#include <assert.h>
#include <stddef.h>

// If your functions requires another function to work, include it here
// #include "../src/dependency.c"

static void test_example(void)
{
	a_main();
	// Write a test here
}

// clang-format off
void (*tests[])(void) = {
	&test_example,
	// Add your tests functions here
	NULL
};
// clang-format on
