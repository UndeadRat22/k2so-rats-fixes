.PHONY: test-e2e test-proto lint thumbnail package install

# Path to the Factorio binary (auto-detected from Steam install on macOS)
FACTORIO_BIN ?= $(HOME)/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio

VERSION := $(shell sed -n 's/.*"version": "\([^"]*\)".*/\1/p' info.json)
MOD_NAME := k2so-rats-fixes
PACKAGE_DIR := $(MOD_NAME)_$(VERSION)
RELEASES_DIR := releases
PACKAGE_ZIP := $(RELEASES_DIR)/$(PACKAGE_DIR).zip

# Source sprite for the thumbnail (K2's biomass icon, from Krastorio2Assets)
THUMBNAIL_SRC ?= $(HOME)/Library/Application Support/factorio/mods/Krastorio2Assets_2.1.0.zip

# Default Factorio mods dir per OS for `make install`
UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(UNAME_S),Darwin)
	FACTORIO_MODS_DIR ?= $(HOME)/Library/Application Support/factorio/mods
else ifneq ($(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)),)
	FACTORIO_MODS_DIR ?= $(APPDATA)/Factorio/mods
else
	FACTORIO_MODS_DIR ?= $(HOME)/.factorio/mods
endif

test-e2e:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-e2e.sh

test-proto:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-proto.sh --all

lint:
	luacheck data-final-fixes.lua fixes/*.lua tests/scenario/biomass-stall/control.lua --no-config || true

thumbnail:
	@mkdir -p scripts/.src
	@unzip -p -o "$(THUMBNAIL_SRC)" "Krastorio2Assets_*/icons/items/biomass.png" > scripts/.src/biomass.png
	@python3 scripts/make_thumbnail.py scripts/.src/biomass.png thumbnail.png
	@rm -rf scripts/.src

package:
	@echo "Packaging $(MOD_NAME) $(VERSION)..."
	@rm -rf $(PACKAGE_DIR) $(RELEASES_DIR)
	@mkdir -p $(RELEASES_DIR)
	@mkdir -p $(PACKAGE_DIR)
# Files shipped in the zip: info.json + Lua are runtime requirements,
# changelog.txt is shown by the in-game mod list, thumbnail.png is read by
# the mod portal, and LICENSE must accompany MIT-licensed distributions.
# README.md, tests/, scripts/ and the Makefile are repo-only and stay out.
	@cp -r changelog.txt data-final-fixes.lua info.json LICENSE thumbnail.png $(PACKAGE_DIR)/
	@[ ! -d fixes ] || cp -r fixes $(PACKAGE_DIR)/
	@zip -r $(PACKAGE_DIR).zip $(PACKAGE_DIR) >/dev/null
	@mv $(PACKAGE_DIR).zip $(RELEASES_DIR)/
	@rm -rf $(PACKAGE_DIR)
	@echo "Created $(PACKAGE_ZIP)"

install: package
	@mkdir -p "$(FACTORIO_MODS_DIR)"
	@rm -rf "$(FACTORIO_MODS_DIR)/$(PACKAGE_DIR)"
	@cp "$(PACKAGE_ZIP)" "$(FACTORIO_MODS_DIR)/"
	@echo "Installed $(PACKAGE_DIR).zip to $(FACTORIO_MODS_DIR)"
