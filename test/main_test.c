#include "common.h"

#include <assert.h>
#include <stddef.h>

// If your functions requires another function to work, include it here
// #include "../src/dependency.c"

void test_example(void)
{
	// Write a test here
}

// clang-format off
void (*tests[])(void) = {
	&test_example,
	// Add your tests functions here
	NULL
};
// clang-format on
