ERL ?= erl
ERLC ?= $(ERL)c
EDOC ?= edoc

ifeq ($(NAME),)
NAME != $(ERL) -noshell -eval 'io:put_chars(filename:basename(hd(filelib:wildcard("src/*.app.src")), ".app.src")).' -s init stop
endif

ERLC_OPTS := +debug_info +inline
ERLC_DEFS := $(shell $(ERL) -noshell -eval 'is_binary(catch <<0:16/float>>) andalso io:put_chars("-DHAVE_float16")' -s init stop)

SOURCES = $(wildcard src/*.erl)
MODULES = $(SOURCES:src/%.erl=ebin/%.beam)

TEST_SOURCES = $(wildcard test/*.erl)
EUNIT_MODULES = $(SOURCES:src/%.erl=.eunit/%.beam) $(TEST_SOURCES:test/%.erl=.eunit/%.beam)

APP = ebin/$(NAME).app
APP_SRC = src/$(NAME).app.src

app: $(APP)

doc: doc/edoc-info

$(APP): $(APP_SRC) $(MODULES)
	$(ERL) -noshell -eval '$(APP_SCRIPT)' -s init stop

$(MODULES): $(SOURCES) ebin/
	$(ERLC) -o ebin $(ERLC_OPTS) $(ERLC_DEFS) $(SOURCES)

ebin/:
	mkdir ebin

doc/edoc-info: $(SOURCES)
	$(ERL) -noshell -eval "edoc:application('.', [$(EDOC_OPTS)])." -s init stop

$(EUNIT_MODULES): $(SOURCES) $(TEST_SOURCES) .eunit/
	$(ERLC) -o .eunit $(ERLC_OPTS) $(ERLC_DEFS) -DTEST $(SOURCES) $(TEST_SOURCES)

.eunit/:
	mkdir .eunit

eunit: $(EUNIT_MODULES)
	cd .eunit && $(ERL) -noshell -eval 'eunit:test($(NAME), [$(EUNIT_OPTS)]).' -s init stop

clean:
	rm -rf ebin doc .eunit

define APP_SCRIPT
{ok, [{application, $(NAME), L}]} = file:consult("$(APP_SRC)"), \
file:write_file("$(APP)", \
                io_lib:format("{application, $(NAME), ~91p}.~n", \
                              [lists:keystore(modules, 1, L, \
                                              {modules, \
                                               lists:map(fun(F) -> list_to_atom(filename:basename(F, ".beam")) end, \
                                                         filelib:wildcard("*.beam", "ebin"))})]), \
                [raw]).
endef
