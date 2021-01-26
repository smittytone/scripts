#!/bin/zsh

#
# makepico.zsh
#
# Create a Raspberry Pi Pico project
#
# @author    Tony Smith
# @copyright 2021, Tony Smith
# @version   1.0.0
# @license   MIT
#


make_project() {
    touch "$1.c"
    cp "$PICO_SDK_PATH/external/pico_sdk_import.cmake" .
    make_cmake_file $1
}

make_cmake_file() {
    {
        echo 'cmake_minimum_required(VERSION 3.12)'
        echo 'include(pico_sdk_import.cmake)'
        echo "project($1)"
        echo 'pico_sdk_init()'
        echo "add_executable($1 source.c)"
        echo "pico_enable_stdio_usb($1 1)"
        echo "pico_enable_stdio_uart($1 1)"
        echo "pico_add_extra_outputs($1)"
        echo "target_link_libraries($1 pico_stdlib)"
    } >> CMakeLists.txt
}



for arg in "$@"; do
    make_project $arg
done