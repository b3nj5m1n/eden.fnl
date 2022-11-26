EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
makePath = $(subst $(SPACE),;,$1)

PWD := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Modules

MOD_L_FSPEC := $(PWD)pkgs/fspec/?.lua
MOD_F_FSPEC := $(PWD)pkgs/fspec/?.fnl

MOD_L_SUPERNOVA := $(PWD)pkgs/supernova/?.lua

# Create Module Paths

LUA_MODULES := $(PWD)src/?.lua $(MOD_L_FSPEC) $(MOD_L_SUPERNOVA)
PATH_LUA := $(call makePath,$(LUA_MODULES))

FENNEL_MODULES := $(PWD)src/?.fnl $(MOD_F_FSPEC)
PATH_FENNEL := $(call makePath,$(FENNEL_MODULES))



.PHONY: test

# Execute unit tests
test: 
	@fennel \
		--add-fennel-path "$(PATH_FENNEL)" \
		--add-package-path "$(PATH_LUA)" \
		test/run-tests.fnl

# Run the uglyprint file
uglyprint: 
	@fennel \
		--add-fennel-path "$(PATH_FENNEL)" \
		--add-package-path "$(PATH_LUA)" \
		src/uglyprint.fnl

# Run the paco file
paco: 
	@fennel \
		--add-fennel-path "$(PATH_FENNEL)" \
		--add-package-path "$(PATH_LUA)" \
		src/paco.fnl

# Run the eden file
eden: 
	@fennel \
		--add-fennel-path "$(PATH_FENNEL)" \
		--add-package-path "$(PATH_LUA)" \
		src/eden.fnl











