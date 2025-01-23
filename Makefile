# **************************************************************************** #
#                                                                              #
#                                                               ++             #
#    Makefile                                                  +**+   +*  *    #
#                                                              ##%#*###*+++    #
#    By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+      #
#                                                             # *   *. #*      #
#    Created: 2024/07/12 02:16:49 by aboyreau          **+*+  * -_._-   #+     #
#    Updated: 2025/01/02 14:03:23 by aboyreau          +#-.-*  +         *     #
#                                                      *-.. *   ++       #     #
# **************************************************************************** #

# My personnal choice
CC = clang

# Main executable/library.
NAME = REPLACE_WITH_NAME

# Sources used to build the project.
SRC = main

# Sources with path and extension.
SRCS = $(addprefix src/, $(addsuffix .c, $(SRC)))
# Objects files with path and extension.
OBJS = $(addprefix obj/, $(addsuffix .o, $(SRC)))

# Tests files.
TESTS = test/main

# Libraries to build and to link against the main executable
LIBS = libft

# C compilations flags.
# The last three can be safely removed but should be kept if possible.
CFLAGS +=	-Wall \
		 	-Wextra \
		 	-Werror \
			-Wdocumentation \
		 	-pedantic \
			-Weverything \
			-Wno-unsafe-buffer-usage \
			-Wno-padded \
			-Wno-declaration-after-statement

# C preprocessor flags
CPPFLAGS += -I include

# Linker flags.
$(eval CPPFLAGS+=$(addprefix -I ,$(addprefix lib/,$(addsuffix /include,$(LIBS)))))
# Libraries that should be used.
$(eval LDFLAGS+=$(addprefix -L ,$(addprefix lib/,$(addsuffix /lib,$(LIBS)))))
# Libraries that should be linked.
$(eval LDLIBS+= -Wl,-Bstatic $(subst lib,-l,$(LIBS)) -Wl,-Bdynamic)

vpath %.c src/
vpath %.o obj/
vpath %.d .cache/.d/
vpath %_test.c test/

vpath %.profraw test/
vpath %.profdata test/


############################# GENERAL RULES #####################################

# Builds the project.
all: libs $(NAME)


# Builds the project's main target.
$(NAME): $(OBJS)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $(OBJS) -o $(NAME) $(LDLIBS)

# Compiles a specific C file into a object file.
obj/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# Rebuilds the project.
re: fclean all

# Deletes objects and depedencies' objects.
clean:
	$(RM) -r obj/
	$(RM) -r .cache/.d/
	$(RM) -r bin/
	$(RM) $(addsuffix _test,$(TESTS))
	$(RM) -r coverage/
	$(RM) test/*.prof*
	$(RM) test/*.o
	$(RM) default.profraw

# Deletes objects, binaries, libraries and dependencies
fclean: clean
	$(RM) $(NAME)

libs:
	@for lib in $(LIBS);			\
	do							\
		$(MAKE) -C lib/$$lib;	\
	done;


############################## UNITS TESTS RULES ###############################

# Generate a summary of the code coverage of the project.
coverage: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping
coverage: CPPFLAGS+=-D TEST -D COVERAGE
coverage: fclean test/common.o $(addsuffix .profraw,$(TESTS))
	@$(eval PROFRAW_FILES=$(addsuffix .profraw,$(TESTS)))
	@llvm-profdata merge -sparse $(PROFRAW_FILES) -o test/coverage.profdata

rcov: coverage
	llvm-cov report -instr-profile=test/coverage.profdata $(addsuffix _test, $(addprefix --object=,$(TESTS))) -sources $(SRCS)

vcov: coverage
	llvm-cov show -instr-profile=test/coverage.profdata $(addsuffix _test, $(addprefix --object=,$(TESTS))) -sources $(SRCS)

# Run unit tests.
check: fclean $(TESTS)

# Put everything common to your tests in test/common.c.
test/common.o:
	@$(CC) -Wall -Wextra -Werror -I include -I lib/libft/include test/common.c -c -o test/common.o

# Run each test separately.
test/%: CFLAGS+=-D DEBUG 
test/%: %_test.c test/common.o $(OBJS) libs
	$(CC) $(LDFLAGS) $(CFLAGS) $(CPPFLAGS) test/common.o obj/$*.o $< $(LDLIBS) -o $@_test
	@(tabs -4 ; $(DEBUGGER) $@_test)

# Build raw coverage data for a specific test.
%.profraw: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping
%.profraw: $(OBJS) libs test/common.o %
	env LLVM_PROFILE_FILE="$@" $*_test

# Build coverage data from raw coverage data.
%.profdata: test/%.profraw
	@llvm-profdata merge -sparse $< -o $@


############################## .h DEPENDENCIES RULE ############################

#https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html
# Patched to work with obj/%.o and .cache/.d/

# Trigger .cache/.d/%.d rule to include non-existing or outdated .d files.
include $(addprefix .cache/.d/, $(addsuffix .d, $(notdir $(SRC))))

# Generates .d files to add .h dependency on .o file (if .h changes, rebuilds .o for affected .c files)
.cache/.d/%.d: %.c
	@mkdir -p $(@D)
	@set -e; rm -f $@; \
     $(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
     sed 's,\($*\)\.o[ :]*,obj/\1.o $@ : ,g' < $@.$$$$ > $@; \
     rm -f $@.$$$$


################################################################################

 # https://stackoverflow.com/questions/35730218/how-to-automatically-generate-a-makefile-help-command
help:
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t

.PHONY = all clean fclean re $(NAME) check coverage
