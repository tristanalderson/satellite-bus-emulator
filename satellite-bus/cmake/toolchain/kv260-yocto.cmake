# F Prime toolchain for KV260 via Yocto SDK
# Requires: SDK environment sourced before running fprime-util
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Pull compilers from the sourced SDK environment
set(CMAKE_C_COMPILER $ENV{OECORE_NATIVE_SYSROOT}/usr/bin/aarch64-poky-linux/aarch64-poky-linux-gcc)
set(CMAKE_CXX_COMPILER $ENV{OECORE_NATIVE_SYSROOT}/usr/bin/aarch64-poky-linux/aarch64-poky-linux-g++)
set(CMAKE_SYSROOT $ENV{SDKTARGETSYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# F Prime platform: reuse the stock Linux platform support
set(FPRIME_PLATFORM Linux)
