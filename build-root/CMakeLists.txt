# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

cmake_minimum_required(VERSION 3.5)

set(IDF_PATH "../toit/third_party/esp-idf" CACHE FILEPATH "Path to the ESP-IDF directory")
set(TOIT_SDK_DIR "../build/host/sdk" CACHE FILEPATH "Path to the Toit SDK directory")

list(APPEND EXTRA_COMPONENT_DIRS "../toit/toolchains/idf/components" "../components")

include("${IDF_PATH}/tools/cmake/project.cmake")
project(toit)

include("local.cmake" OPTIONAL)

toit_postprocess()
