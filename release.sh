#!/bin/bash
proj_path_nv=$(cd $(dirname $0); pwd)
echo "Current Path : $proj_path_nv"
rm -rf $proj_path_nv/out
mkdir out

jq -h >/dev/null
if [ $? != 0 ];
then
   echo "The program 'jq' is currently not installed. You can install it by typing: sudo apt install jq"
   exit
fi

if [ x"$1" = x ];
then
   version=adapter
else
   version=product
fi

echo "Build Rtos Project ..."
ADA_VERSION=`cat $proj_path_nv/$version/version.h |grep ADA_VERSION| awk '{print $3}'`
echo "Current ADA VERSION : $ADA_VERSION"
SDK_VERSION=`cat $proj_path_nv/iot_sdk/version.h |grep SDK_VERSION| awk '{print $3}'`
echo "Current SDK VERSION : $SDK_VERSION"
MODULE_TYPE=`cat $proj_path_nv/param_tool/dev.conf | jq '.module_type'|awk -F '["]' '{print$2}'`
echo "Current MODULE_TYPE : $MODULE_TYPE"
GADGET_TYPE_ID=`cat $proj_path_nv/param_tool/dev.conf | jq '.gadget_type_id'`
echo "Current GADGET_TYPE_ID : $GADGET_TYPE_ID"

for build_option in release debug
do
    cd $proj_path_nv
    rm -rf $proj_path_nv/imgs $proj_path_nv/.output $proj_path_nv/adapter_lib/.output  $proj_path_nv/adapter/.output $proj_path_nv/product/.output
    mkdir $proj_path_nv/imgs

    ./build.sh ${build_option} $1
    if [ $? != 0 ];
    then
       echo "Build Rtos Project Error !!!"
       exit
    fi
    cp -rf $proj_path_nv/esp8266_sdk/ESP8266_RTOS_SDK-master/bin/ $proj_path_nv/imgs

    for CLOUD in dev pvt api
    do
        echo ""
        echo ""
        echo "----------------------------------------------------------------------------------------------------"
        echo "----------------------------------RELEASE $CLOUD BIN------------------------------------------------"
        echo "----------------------------------------------------------------------------------------------------"
        #CLOUD=`cat $proj_path_nv/param_tool/dev.conf | jq '.cloud'`
        echo "Current CLOUD : $CLOUD"

        echo "Param Rtos Project ..."
        cd $proj_path_nv/param_tool
        ./param $CLOUD $proj_path_nv/param_tool/dev.conf param_$CLOUD.bin

        if [ $? != 0 ];
        then
           echo "Param Rtos Project Error !!!"
           exit
        fi
        mv $proj_path_nv/param_tool/param_$CLOUD.bin $proj_path_nv/imgs/bin

        echo "Combine Rtos Project ..."
        cd $proj_path_nv/combine_tool
        ./combine $proj_path_nv/combine_tool/combine_$CLOUD.conf
        if [ $? != 0 ];
        then
           echo "Combine Rtos Project Error !!!"
           exit
        fi

        mkdir -p $proj_path_nv/out/${build_option}
        echo "release $proj_path_nv/out/${build_option}/${MODULE_TYPE}_${GADGET_TYPE_ID}_${CLOUD}_${SDK_VERSION}_${ADA_VERSION}.bin"
        mv $proj_path_nv/combine_tool/combine_$CLOUD.bin $proj_path_nv/out/${build_option}/${MODULE_TYPE}_${GADGET_TYPE_ID}_${CLOUD}_${SDK_VERSION}_${ADA_VERSION}.bin
        cp $proj_path_nv/imgs/bin/upgrade/*.bin $proj_path_nv/out/${build_option}/update_${GADGET_TYPE_ID}_${ADA_VERSION}.bin
    done
    md5sum $proj_path_nv/out/${build_option}/* > $proj_path_nv/out/${build_option}/md5sum.txt
done

tree $proj_path_nv/out/
