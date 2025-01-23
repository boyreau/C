# **************************************************************************** #
#                                                                              #
#                                                               ++             #
#    Makefile                                                  +**+   +*  *    #
#                                                              ##%#*###*+++    #
#    By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+      #
#                                                             # *   *. #*      #
#    Created: 2024/07/12 02:16:49 by aboyreau          **+*+  * -_._-   #+     #
#    Updated: 2024/12/20 23:53:15 by aboyreau          +#-.-*  +         *     #
#                                                      *-.. *   ++       #     #
# **************************************************************************** #

# My personnal choice
CC = clang

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

LIBS = libft

# C compilations flags. The last three can be safely removed but should be kept if possible.
CFLAGS +=	-Wall \
		 	-Wextra \
		 	-Werror \
			-Wdocumentation \
		 	-pedantic \
			-Weverything \
			-Wno-unsafe-buffer-usage \
			-Wno-padded

# C preprocessor flags
CPPFLAGS += -I include
# Linker flags.
LDFLAGS += $(addprefix -I ,$(LIBS))
# Libraries that should be used.
LDLIBS += $(subst lib,-l,$(LIBS))


############################# GENERAL RULES #####################################

# Builds the project.
all: $(LIBFT) $(NAME)


# Builds the project's main target.
$(NAME): $(OBJS)
	@mkdir -p $(@D)
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

# Deletes objects, binaries, libraries and dependencies
fclean: clean
	$(RM) $(NAME)


############################## UNITS TESTS RULES ###############################

# Generate a summary of the code coverage of the project.
coverage: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping -D TEST=1
coverage: $(addsuffix .profraw,$(TESTS)) $(NAME)
	@$(eval PROFRAW_FILES=$(addsuffix .profraw,$(TESTS)))
	@llvm-profdata merge -sparse $(PROFRAW_FILES) -o tests/coverage.profdata
	llvm-cov report -instr-profile=tests/coverage.profdata $(addsuffix _test, $(addprefix --object=,$(TESTS))) -sources $(SRCS)

# Run unit tests.
check: $(NAME) $(TESTS)

# Put everything common to your tests in tests/common.c.
tests/common.o:
	@$(CC) -Wall -Wextra -Werror -I include -I libs/libft/includes tests/common.c -c -o tests/common.o

# Run each test separately.
tests/%: tests/%_test.c tests/common.o $(OBJS) $(LIBFT)
	@$(CC) $(CFLAGS) $(CPPFLAGS) tests/common.o $(OBJS) $< -L libs/libft -lft -o $@
	@(tabs -4 ; LD_LIBRARY_PATH=$(shell pwd) $@)

# Build raw coverage data for a specific test.
tests/%.profraw: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping
tests/%.profraw: TEST_SOURCE=$(subst .profraw,_test,$@).c
tests/%.profraw: TEST_BIN=$(subst .profraw,_test,$@)
tests/%.profraw: $(OBJS) $(LIBFT) tests/common.o 
	@$(CC) $(CFLAGS) $(CPPFLAGS) tests/common.o $(OBJS) $(TEST_SOURCE) -L libs/libft -lft -o $(TEST_BIN)
	@env LLVM_PROFILE_FILE="$@" LD_LIBRARY_PATH=$(shell pwd) $(TEST_BIN) >/dev/null 2>/dev/null

# Build coverage data from raw coverage data.
tests/%.profdata: tests/%.profraw
	@llvm-profdata merge -sparse $< -o $@

# Display a coverage summary for a specific test.
coverag./%.report: TEST_SOURCE=$(subst coverage/,obj/,$(subst .report,,$@).o)
coverage/%.report: tests/%.profdata
	@mkdir -p $(@D)
	@llvm-cov report -instr-profile=$< -show-functions $(TEST_SOURCE) $(subst .profdata,,$(subst tests/,src/,$<)).c


############################## .h DEPENDENCIES RULE ############################

#https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html
include $(SRCS:.c=.d)

# Ensure C files are rebuilt if one of the .h they depend on changes.
%.d: %.c
	@set -e; rm -f $@; \
     $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
     sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
     rm -f $@.$$$$


################################################################################

 # https://stackoverflow.com/questions/35730218/how-to-automatically-generate-a-makefile-help-command
help:
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t

.PHONY = all clean fclean re $(NAME) check coverage
