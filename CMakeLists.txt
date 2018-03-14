cmake_minimum_required(VERSION 2.8.4)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/cmake/ArduinoToolchain.cmake)
set(PROJECT_NAME rfid)
project(${PROJECT_NAME})

set(${CMAKE_PROJECT_NAME}_SKETCH examples/DumpInfo/DumpInfo.ino)
set(${PROJECT_NAME}_BOARD uno)

generate_arduino_firmware(${CMAKE_PROJECT_NAME}
        LIBS SPI #SPI target created with generate_arduino_library
        )