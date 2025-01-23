/* ************************************************************************** */
/*                                                                            */
/*                                                              ++            */
/*   common.c                                                  +**+   +*  *   */
/*                                                             ##%#*###*+++   */
/*   By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+     */
/*                                                            # *   *. #*     */
/*   Created: 2024/12/23 17:46:01 by aboyreau          **+*+  * -_._-   #+    */
/*   Updated: 2024/12/23 17:59:29 by aboyreau          +#-.-*  +         *    */
/*                                                     *-.. *   ++       #    */
/* ************************************************************************** */

#include "../lib/libft/include/ft_tab.h"
#include "common.h"

#include <unistd.h>

#ifdef COVERAGE
#include <csetjmp>
#include <signal.h>

_Noreturn static void abort_goto(int _)
{
	(void) _;
	longjmp(env, i + 1);
}

static jmp_buf env;
#endif
static size_t test_nb = 0;

int main(void)
{
#ifdef COVERAGE
	signal(SIGABRT, abort_goto);
#endif
#ifdef COVERAGE
	for (test_nb = 0; test_nb < ft_tablen(tests); test_nb = setjmp(env))
#else
	for (test_nb = 0; test_nb < (size_t) ft_tablen((void *) tests);)
#endif
	{
		tests[test_nb]();
		test_nb++;
	}
}
