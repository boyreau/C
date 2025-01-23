# **************************************************************************** #
#                                                                              #
#                                                               ++             #
#    Makefile                                                  +**+   +*  *    #
#                                                              ##%#*###*+++    #
#    By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+      #
#                                                             # *   *. #*      #
#    Created: 2024/07/12 02:16:49 by aboyreau          **+*+  * -_._-   #+     #
#    Updated: 2025/01/18 09:34:48 by aboyreau          +#-.-*  +         *     #
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
tests = main

TESTS = $(addsuffix _test,$(addprefix bin/test/,$(tests)))

# Libraries to build and to link against the main executable
LIBS =

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

# Run unit tests.
check: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping -g
check: CPPFLAGS+=-D TEST -D COVERAGE
check: $(TESTS)

stats: $(NAME)_coverage.json

# Get JSON-formatted stats about the current project coverage.
$(NAME)_coverage.json: bin/test/$(NAME).profdata
	@llvm-cov export -instr-profile=./bin/test/$(NAME).profdata $(TESTS) -sources $(SRCS)

# Human-readable summary about coverage.
rcov: bin/test/$(NAME).profdata
	llvm-cov report -instr-profile=./bin/test/$(NAME).profdata $(TESTS) -sources $(SRCS)

# Get a visual summary of covered and uncovered lines.
vcov: bin/test/$(NAME).profdata
	llvm-cov show -instr-profile=./bin/test/$(NAME).profdata $(TESTS) -sources $(SRCS)

# Generate a summary of the code coverage of the project.
bin/test/$(NAME).profdata: $(addsuffix .profraw,$(TESTS))
	$(eval PROFRAW_FILES=$(addsuffix .profraw,$(TESTS)))
	@llvm-profdata merge $(PROFRAW_FILES) -o ./bin/test/$(NAME).profdata; rm default.profraw

# Build coverage data from raw coverage data.
%.profdata: %.profraw
	@llvm-profdata merge $< -o $@

# Build raw coverage data for a specific test.
%.profraw: %
	@env LLVM_PROFILE_FILE="$@" $*

# Run each test separately.
bin/test/%: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping -g
bin/test/%: CPPFLAGS+=-D TEST -D COVERAGE -D DEBUG
bin/test/%: %.c obj/test/common.o $(OBJS)
	@mkdir -p $(@D)
	$(CC) $(LDFLAGS) $(CFLAGS) $(CPPFLAGS) $^ $(LDLIBS) -o $@
	@(tabs -4 ; $(DEBUGGER) $@)

# Put everything common to your tests in test/common.c.
obj/test/common.o:
	@mkdir -p $(@D)
	$(CC) -Wall -Wextra -Werror -I include -I lib/libft/include test/common.c -c -o obj/test/common.o


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

.PHONY = all clean fclean re check vcov rcov
