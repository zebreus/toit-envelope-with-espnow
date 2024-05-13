# Template repository for creating a custom Toit envelope

## Setup

* Fork this repository (giving it a better name), and then detach the fork: https://support.github.com/request/fork
* Change the license to your license.
* Change the `TARGET` variable in the Makefile to the name of your chip. By default it is set to `esp32`.
* Run `make init`. This will copy some of the Toit files, depending on the target, to your repository.
* Make sure you have a complete build environment. See
  - https://github.com/toitlang/toit, and
  - https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/index.html
  - A good starting point is to run `install.sh` from the `toit/third_party/esp-idf` folder.


## Makefile targets

- `make` or `make all` - Build the envelope.
- `make init` - Initialize after cloning. See the Setup section above.
- `make menuconfig` - Runs the ESP-IDF menuconfig tool in the build-root. Also creates the `sdkconfig.defaults` file.
- `make diff` - Show the differences between your configuration (sdkconfig and partitions.csv) and the default Toit configuration.
- `make clean` - Remove all build artifacts.
