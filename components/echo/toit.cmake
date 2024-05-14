# Copyright (C) 2024 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the LICENSE file.

# Due to this function call being in a `toit.cmake` file, the library is also
# compiled into the host executable. If this is not desired, then rename this
# file or copy the content into the `CMakeLists.txt` file.

idf_component_register(
  REQUIRES toit
  SRCS echo.c
  WHOLE_ARCHIVE
)
