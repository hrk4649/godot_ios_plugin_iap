#!/bin/bash

SCHEME=${1:-godot_plugin}
PROJECT=${2:-godot_plugin.xcodeproj}
OUT=ios-in-app-purchase
CLASS=IOSInAppPurchase

xcodebuild archive \
    -project "./$PROJECT" \
    -scheme $SCHEME \
    -archivePath "./bin/ios_release.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS="PluginClass=${CLASS}"

xcodebuild archive \
    -project "./$PROJECT" \
    -scheme $SCHEME \
    -archivePath "./bin/sim_release.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS="PluginClass=${CLASS}"

xcodebuild archive \
    -project "./$PROJECT" \
    -scheme $SCHEME \
    -archivePath "./bin/ios_debug.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS="DEBUG_ENABLED=1 PluginClass=${CLASS}"

xcodebuild archive \
    -project "./$PROJECT" \
    -scheme $SCHEME \
    -archivePath "./bin/sim_debug.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS="DEBUG_ENABLED=1 PluginClass=${CLASS}"

mv "./bin/ios_release.xcarchive/Products/usr/local/lib/lib${SCHEME}.a" "./bin/ios_release.xcarchive/Products/usr/local/lib/${OUT}.a"
mv "./bin/sim_release.xcarchive/Products/usr/local/lib/lib${SCHEME}.a" "./bin/sim_release.xcarchive/Products/usr/local/lib/${OUT}.a"
mv "./bin/ios_debug.xcarchive/Products/usr/local/lib/lib${SCHEME}.a" "./bin/ios_debug.xcarchive/Products/usr/local/lib/${OUT}.a"
mv "./bin/sim_debug.xcarchive/Products/usr/local/lib/lib${SCHEME}.a" "./bin/sim_debug.xcarchive/Products/usr/local/lib/${OUT}.a"

rm -rf "./bin/${OUT}.release.xcframework"
rm -rf "./bin/${OUT}.debug.xcframework"

xcodebuild -create-xcframework \
    -library "./bin/ios_release.xcarchive/Products/usr/local/lib/${OUT}.a" \
    -library "./bin/sim_release.xcarchive/Products/usr/local/lib/${OUT}.a" \
    -output "./bin/${OUT}.release.xcframework"

xcodebuild -create-xcframework \
    -library "./bin/ios_debug.xcarchive/Products/usr/local/lib/${OUT}.a" \
    -library "./bin/sim_debug.xcarchive/Products/usr/local/lib/${OUT}.a" \
    -output "./bin/${OUT}.debug.xcframework"



