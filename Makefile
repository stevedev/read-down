.PHONY: setup generate build run install install-cli clean bump-major bump-minor bump-patch

BUILD_DIR := build
APP_NAME := ReadDown
CLI_NAME := readdown
INSTALL_DIR := /Applications
CLI_INSTALL_DIR := /usr/local/bin

VERSION := $(shell cat VERSION)
BUILD_NUMBER := $(shell cat BUILD_NUMBER)

setup:
	@bash Scripts/setup.sh

generate:
	xcodegen generate

increment-build:
	@echo $$(( $(BUILD_NUMBER) + 1 )) > BUILD_NUMBER
	@echo "==> Build $(VERSION) ($(shell cat BUILD_NUMBER))"

build: generate increment-build
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		MARKETING_VERSION=$(VERSION) \
		CURRENT_PROJECT_VERSION=$(shell cat BUILD_NUMBER) \
		build

build-cli: generate
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme ReadDownCLI \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

install: build
	@echo "==> Installing $(APP_NAME).app $(VERSION) ($(shell cat BUILD_NUMBER)) to $(INSTALL_DIR)..."
	@cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app" "$(INSTALL_DIR)/"
	@echo "==> Installed."

install-cli: build-cli
	@echo "==> Installing $(CLI_NAME) to $(CLI_INSTALL_DIR)..."
	@cp "$(BUILD_DIR)/Build/Products/Release/$(CLI_NAME)" "$(CLI_INSTALL_DIR)/$(CLI_NAME)"
	@chmod +x "$(CLI_INSTALL_DIR)/$(CLI_NAME)"
	@echo "==> Installed. Run: $(CLI_NAME) <file.md>"

install-all: install install-cli

bump-major:
	@python3 -c "v='$(VERSION)'.split('.'); v[0]=str(int(v[0])+1); v[1]='0'; v[2]='0'; print('.'.join(v))" > VERSION
	@echo "1" > BUILD_NUMBER
	@echo "==> Version: $$(cat VERSION)"

bump-minor:
	@python3 -c "v='$(VERSION)'.split('.'); v[1]=str(int(v[1])+1); v[2]='0'; print('.'.join(v))" > VERSION
	@echo "1" > BUILD_NUMBER
	@echo "==> Version: $$(cat VERSION)"

bump-patch:
	@python3 -c "v='$(VERSION)'.split('.'); v[2]=str(int(v[2])+1); print('.'.join(v))" > VERSION
	@echo "1" > BUILD_NUMBER
	@echo "==> Version: $$(cat VERSION)"

clean:
	@rm -rf $(BUILD_DIR)
	@rm -rf $(APP_NAME).xcodeproj
	@echo "==> Cleaned."
