
testenv=$(wildcard ./testdata/*.env)
testcases=$(patsubst ./testdata/%.env,%,$(testenv))

test: $(testcases:%=test-%)
	@rm -rf testdata/tor
	@echo DONE

test-%:
	@echo testing: $*
	@./docker-entrypoint.sh test "$*"

.PHONY: test test-%
