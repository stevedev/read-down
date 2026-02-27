.PHONY: setup generate build run install install-cli clean

BUILD_DIR := build
APP_NAME := ReadDown
CLI_NAME := readdown
INSTALL_DIR := /Applications
CLI_INSTALL_DIR := /usr/local/bin

setup:
	@bash Scripts/setup.sh

generate:
	xcodegen generate

build: generate
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

build-cli: generate
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(CLI_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

install: build
	@echo "==> Installing $(APP_NAME).app to $(INSTALL_DIR)..."
	@cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app" "$(INSTALL_DIR)/"
	@echo "==> Installed."

install-cli: build-cli
	@echo "==> Installing $(CLI_NAME) to $(CLI_INSTALL_DIR)..."
	@cp "$(BUILD_DIR)/Build/Products/Release/$(CLI_NAME)" "$(CLI_INSTALL_DIR)/$(CLI_NAME)"
	@chmod +x "$(CLI_INSTALL_DIR)/$(CLI_NAME)"
	@echo "==> Installed. Run: $(CLI_NAME) <file.md>"

install-all: install install-cli

clean:
	@rm -rf $(BUILD_DIR)
	@rm -rf $(APP_NAME).xcodeproj
	@echo "==> Cleaned."
