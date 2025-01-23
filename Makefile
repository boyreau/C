# **************************************************************************** #
#                                                                              #
#                                                               ++             #
#    Makefile                                                  +**+   +*  *    #
#                                                              ##%#*###*+++    #
#    By: aboyreau <bnzlvosnb@mozmail.com>                     +**+ -- ##+      #
#                                                             # *   *. #*      #
#    Created: 2024/07/12 02:16:49 by aboyreau          **+*+  * -_._-   #+     #
#    Updated: 2024/12/22 01:27:19 by aboyreau          +#-.-*  +         *     #
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
			-Wno-padded

# C preprocessor flags
CPPFLAGS += -I include

# Linker flags.
$(eval CPPFLAGS+=$(addprefix -I ,$(addprefix lib/,$(addprefix $(LIBS),/include))))
# Libraries that should be used.
$(eval LDFLAGS+=$(addprefix -L ,$(addprefix lib/,$(LIBS))))
# Libraries that should be linked.
$(eval LDLIBS+=$(subst lib,-l,$(LIBS)))

vpath %.c src/
vpath %.o obj/
vpath %.d .d/
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
	$(RM) -r .d/
	$(RM) -r bin/
	$(RM) -r $(addsuffix _test,$(TESTS))
	$(RM) -r coverage/
	$(RM) -r test/*.prof*
	$(RM) -r test/*.o

# Deletes objects, binaries, libraries and dependencies
fclean: clean
	$(RM) $(NAME)

libs:
	for lib in $(LIBS);			\
	do							\
		$(MAKE) -C lib/$$lib;	\
	done;


############################## UNITS TESTS RULES ###############################

# Generate a summary of the code coverage of the project.
coverage: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping -D TEST=1
coverage: fclean $(addsuffix .profraw,$(TESTS)) $(NAME)
	@$(eval PROFRAW_FILES=$(addsuffix .profraw,$(TESTS)))
	@llvm-profdata merge -sparse $(PROFRAW_FILES) -o test/coverage.profdata
	llvm-cov report -instr-profile=test/coverage.profdata $(addsuffix _test, $(addprefix --object=,$(TESTS))) -sources $(SRCS)

# Run unit tests.
check: fclean $(NAME) $(TESTS)

# Put everything common to your tests in test/common.c.
test/common.o:
	@$(CC) -Wall -Wextra -Werror -I include -I libs/libft/includes test/common.c -c -o test/common.o

# Run each test separately.
test/%: %_test.c test/common.o $(OBJS) libs
	@$(CC) $(LDFLAGS) $(CFLAGS) $(CPPFLAGS) test/common.o $(OBJS) $< $(LDLIBS) -o $@_test
	@(tabs -4 ; LD_LIBRARY_PATH=$(shell pwd) $(DEBUGGER) $@_test)

# Build raw coverage data for a specific test.
%.profraw: CFLAGS+=-fprofile-instr-generate -fcoverage-mapping
%.profraw: TEST_SOURCE=$(subst .profraw,_test,$@).c
%.profraw: TEST_BIN=$(subst .profraw,_test,$@)
%.profraw: $(OBJS) $(LIBFT) test/common.o 
	@$(CC) $(LDFLAGS) $(CFLAGS) $(CPPFLAGS) test/common.o $(OBJS) $(TEST_SOURCE) $(LDLIBS) -o $(TEST_BIN)
	@env LLVM_PROFILE_FILE="$@" LD_LIBRARY_PATH=$(shell pwd) $(TEST_BIN) >/dev/null 2>/dev/null

# Build coverage data from raw coverage data.
%.profdata: test/%.profraw
	@llvm-profdata merge -sparse $< -o $@

# Display a coverage summary for a specific test.
coverage/%.report: TEST_SOURCE=$(subst coverage/,obj/,$(subst .report,,$@).o)
coverage/%.report: %.profdata
	@mkdir -p $(@D)
	@llvm-cov report -instr-profile=$< -show-functions $(TEST_SOURCE) $(subst .profdata,,$(subst test/,src/,$<)).c


############################## .h DEPENDENCIES RULE ############################

#https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html
# Patched to work with obj/%.o.

# Trigger .d/%.d rule to include non-existing or outdated .d files.
include $(addprefix .d/, $(addsuffix .d, $(notdir $(SRC))))

# Generates .d files to add .h dependency on .o file (if .h changes, rebuilds .o for affected .c files)
.d/%.d: %.c
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
