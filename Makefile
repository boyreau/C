# **************************************************************************** #
#                                                                              #
#                                                               ++             #
#    Makefile                                                  +**+   +*  *    #
#                                                              ##%#*###*+++    #
#    By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+      #
#                                                             # *   *. #*      #
#    Created: 2024/07/12 02:16:49 by aboyreau          **+*+  * -_._-   #+     #
#    Updated: 2024/12/13 02:00:45 by aboyreau          +#-.-*  +         *     #
#                                                      *-.. *   ++       #     #
# **************************************************************************** #

# Main executable/library.
NAME = REPLACE_WITH_NAME

# Sources used to build the project.
SRC = 

# Sources with path and extension.
SRCS = $(addprefix src/, $(addsuffix .c, $(SRC)))
# Objects files with path and extension.
OBJS = $(addprefix obj/, $(addsuffix .o, $(SRC)))

# Tests files.
TESTS = 

# Path to the libft.
LIBFT_PATH = lib/libft
# Libft name.
LIBFT = $(LIBFT_PATH)/libft.a

# C compilations flags.
CFLAGS += -Wall -Wextra -Werror -pedantic
# C preprocessor flags
CPPFLAGS += -I $(LIBFT_PATH)/include -I include
# Linker flags.
LDFLAGS += -L $(LIBFT_PATH)
# Libraries that should be used.
LDLIBS += -lft

# Builds the project.
all: $(LIBFT) $(NAME)


#https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html
include $(OBJS:.o=.d)

# Ensure C files are rebuilt if one of the .h they depend on changes.
%.d: %.c
	@set -e; rm -f $@; \
     $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
     sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
     rm -f $@.$$$$
################################################################################

# Builds the libft.
$(LIBFT):
	$(MAKE) -C $(LIBFT_PATH) -j

# Builds the project's main target.
$(NAME): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(NAME) $(LDLIBS)

# Compiles a specific C file into a object file.
obj/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# Rebuilds the project.
re: fclean all

# Deletes objects and depedencies' objects.
clean:
	$(RM) $(OBJS)
	$(MAKE) clean -C $(LIBFT_PATH)

# Deletes objects, binaries, libraries and dependencies
fclean: clean
	$(RM) $(NAME)
	$(MAKE) fclean -C $(LIBFT_PATH)

# Execute all the tests.
check: $(NAME) $(TESTS)

# Execute a specific test.
src/tests/%.c: phony
	@$(CC) $(CFLAGS) $(CPPFLAGS) $@ $(NAME) -L $(LIBFT_PATH) -lft
	@(tabs -4 ; env LD_LIBRARY_PATH=$(shell pwd) $(DEBUGER) ./a.out)
	@rm a.out

 # https://stackoverflow.com/questions/35730218/how-to-automatically-generate-a-makefile-help-command
help:
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t

phony: # Ugly rule that can be added as a dependency to force the phonyness of pattern matching (%) rules.

.PHONY = phony fclean clean re $(NAME)
