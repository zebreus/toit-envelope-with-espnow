# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

SHELL := bash
.SHELLFLAGS += -e

SOURCE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include target.mk

# The following path must be kept in sync with the one in the CMakelists.txt file.
IDF_PATH := $(SOURCE_DIR)/../toit/third_party/esp-idf
IDF_PY := $(IDF_PATH)/tools/idf.py
TOIT_ROOT := $(SOURCE_DIR)/../toit
BUILD_PATH := $(SOURCE_DIR)/../build
BUILD_ESP32_PATH := $(BUILD_PATH)/esp32
# The following path must be kept in sync with the one in the CMakelists.txt file.
SDK_PATH := $(BUILD_ESP32_PATH)/sdk

ifeq ($(OS),Windows_NT)
	EXE_SUFFIX=.exe
else
	EXE_SUFFIX=
endif

.PHONY: all
all: esp32

.PHONY: check-env
check-env:
	$(MAKE) -C "$(TOIT_ROOT)" check-env
	$(MAKE) -C "$(TOIT_ROOT)" check-esp32-env

.PHONY: esp32
esp32: $(SDK_PATH)/bin/toit$(EXE_SUFFIX)
	@if [ "$(shell command -v xtensa-esp32-elf-g++)" = "" ]; then source '$(IDF_PATH)/export.sh'; fi; \
	    $(MAKE) esp32-no-env

.PHONY: esp32-no-env
esp32-no-env: check-env
	@cmake -E env IDF_TARGET=$(TARGET) IDF_CCACHE_ENABLE=1 python$(EXE_SUFFIX) "$(IDF_PY)" -C . -B"$(BUILD_PATH)" build

.PHONY: build-host
build-host:
	@$(MAKE) -C "$(TOIT_ROOT)" BUILD=$(BUILD_PATH)

$(SDK_PATH)/bin/toit$(EXE_SUFFIX): build-host

.PHONY: menuconfig
menuconfig:
	@if [ "$(shell command -v xtensa-esp32-elf-g++)" = "" ]; then source '$(IDF_PATH)/export.sh'; fi; \
	    $(MAKE) menuconfig-no-env

.PHONY: menuconfig-no-env
menuconfig-no-env: check-env
	@cmake -E env IDF_TARGET=$(TARGET) python$(EXE_SUFFIX) $(IDF_PY) -B $(BUILD_PATH) menuconfig
	@cmake -E env IDF_TARGET=$(TARGET) python$(EXE_SUFFIX) $(IDF_PY) -B $(BUILD_PATH) save-defconfig

.PHONY: clean
clean:
	@rm -rf "$(BUILD_PATH)"
