# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

# Change to your configuration. See toit/toolchains for the available targets.
# Then run 'make init'.
TARGET := esp32

INITIALIZE_SUBMODULES := true

# Constants that typically don't need to be changed.
BUILD := build
BUILD_ROOT := build-root
IDF_PATH := $(PWD)/toit/third_party/esp-idf
IDF_PY := $(IDF_PATH)/tools/idf.py
BUILD_PATH := $(BUILD)/esp32
TOIT_ROOT := $(PWD)/toit

all: esp32

.PHONY: initialize-submodules
initialize-submodules:
	@if [[ "$(INITIALIZE_SUBMODULES)" == "true" ]]; then \
	  echo "Initializing submodules"; \
		pushd toit && git submodule update --init --recursive && popd; \
	fi

.PHONY: esp32
esp32: initialize-submodules
	@if [[ ! -f $(BUILD_ROOT)/sdkconfig.defaults ]]; then \
	  echo "Run 'make init' first"; \
		exit 1; \
	fi
	@$(MAKE) -C $(BUILD_ROOT)

.PHONY: init
init: $(BUILD_ROOT)/sdkconfig.defaults $(BUILD_ROOT)/target.mk $(BUILD_ROOT)/partitions.csv

$(BUILD_ROOT)/sdkconfig.defaults: initialize-submodules
	@cp $(TOIT_ROOT)/toolchains/$(TARGET)/sdkconfig.defaults $@

$(BUILD_ROOT)/target.mk: initialize-submodules
	@echo "TARGET := $(TARGET)" > $@

$(BUILD_ROOT)/partitions.csv: initialize-submodules
	@cp $(TOIT_ROOT)/toolchains/$(TARGET)/partitions.csv $@

.PHONY: menuconfig
menuconfig:
	@$(MAKE) -C $(BUILD_ROOT) menuconfig

.PHONY: diff
diff:
	@diff -aur $(TOIT_ROOT)/toolchains/$(TARGET)/sdkconfig.defaults $(BUILD_ROOT)/sdkconfig.defaults || true
	@diff -aur $(TOIT_ROOT)/toolchains/$(TARGET)/partitions.csv $(BUILD_ROOT)/partitions.csv || true

.PHONY: clean
clean:
	@$(MAKE) -C $(BUILD_ROOT) clean
