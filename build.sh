#!/bin/bash
project_path=$(cd $(dirname $0); pwd)
echo "Current Path : $project_path"

ESP8266_SDK_PATH=$(cd ./esp8266_sdk/ESP8266_RTOS_SDK-master; pwd)
ESP8266_TOOLCHAINS_PATH=$(cd ./toolchains/xtensa-lx106-elf/bin; pwd)

export SDK_PATH=$ESP8266_SDK_PATH
export BIN_PATH=$ESP8266_SDK_PATH/bin
export PATH=$ESP8266_TOOLCHAINS_PATH:$PATH

make clean
make BOOT=new APP=1 SPI_SPEED=40 SPI_MODE=DOUT SPI_SIZE_MAP=5 RELEASE=$1 PRODUCT=$2
