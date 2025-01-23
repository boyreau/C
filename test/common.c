/* ************************************************************************** */
/*                                                                            */
/*                                                              ++            */
/*   common.c                                                  +**+   +*  *   */
/*                                                             ##%#*###*+++   */
/*   By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+     */
/*                                                            # *   *. #*     */
/*   Created: 2024/12/23 17:46:01 by aboyreau          **+*+  * -_._-   #+    */
/*   Updated: 2024/12/23 19:07:55 by aboyreau          +#-.-*  +         *    */
/*                                                     *-.. *   ++       #    */
/* ************************************************************************** */

#include "common.h"
#include "ft_tab.h"

#include <unistd.h>

static size_t test_nb = 0;

#ifdef COVERAGE
#include <csetjmp>
#include <signal.h>
#include <string.h>

#define ABRT "Aborted (recovered)\n"
#define SEGF "Segmentation fault (recovered)\n"

static jmp_buf env;

_Noreturn static void abort_goto(int _)
{
	switch (_)
	{
		case SIGABRT:
			write(1, ABRT, strlen(ABRT));
			break;
		case SIGSEGV:
			write(1, SEGF, strlen(SEGF));
			break;
	}
	longjmp(env, test_nb + 1);
}

#endif

int main(void)
{
#ifdef COVERAGE
	signal(SIGABRT, abort_goto);
	signal(SIGSEGV, abort_goto);
	for (test_nb = setjmp(env); test_nb < (size_t) ft_tablen((void *) tests);)
#else
	for (test_nb = 0; test_nb < (size_t) ft_tablen((void *) tests);)
#endif
	{
		tests[test_nb]();
		test_nb++;
	}
}
