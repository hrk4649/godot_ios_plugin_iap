#!/bin/bash

# copy plugin's xcframework and gdip 
# to $TARGET_PROJECT/ios/plugins/$PLUGIN_NAME

PLUGIN_NAME=$(ls bin|grep release.xcframework|sed -e "s#\.release\.xcframework##")

XCF_REL=bin/$PLUGIN_NAME.release.xcframework
XCF_DBG=bin/$PLUGIN_NAME.debug.xcframework
GDIP_FILE=$PLUGIN_NAME.gdip

TARGET_PROJECT=../ios_plugin_sample_project
TARGET_PLUGIN=$TARGET_PROJECT/ios/plugins/$PLUGIN_NAME

echo PLUGIN_NAME $PLUGIN_NAME
echo XCF_REL $XCF_REL
echo XCF_DBG $XCF_DBG
echo GDIP_FILE $GDIP_FILE
echo TARGET_PROJECT $TARGET_PROJECT
echo TARGET_PLUGIN $TARGET_PLUGIN

if [ ! -d $XCF_REL ]
then
    echo no $XCF_REL exists. exit.
    exit 1
fi

if [ ! -d $XCF_DBG ]
then
    echo no $XCF_DBG exists. exit.
    exit 1
fi

if [ ! -d $TARGET_PROJECT ]
then
    echo no $TARGET_PROJECT exists. exit.
    exit 1
fi

echo mkdir $TARGET_PLUGIN
mkdir -p $TARGET_PLUGIN
echo copy $XCF_REL to $TARGET_PLUGIN
cp -r $XCF_REL $TARGET_PLUGIN
echo copy $XCF_DBG to $TARGET_PLUGIN
cp -r $XCF_DBG $TARGET_PLUGIN
echo copy $GDIP_FILE to $TARGET_PLUGIN
cp $GDIP_FILE $TARGET_PLUGIN
