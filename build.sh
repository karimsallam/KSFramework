#!/bin/sh

echo Building KSFramework

rm -rf build
rm -rf KSFramework/build

xcodebuild -project KSFramework/KSFramework.xcodeproj -target KSFramework -configuration Release -sdk iphoneos
xcodebuild -project KSFramework/KSFramework.xcodeproj -target KSFramework -configuration Release -sdk iphonesimulator

mkdir build
lipo KSFramework/build/Release-iphoneos/libKSFramework.a KSFramework/build/Release-iphonesimulator/libKSFramework.a -create -output build/libKSFramework.a

rm -rf KSFramework/build

mkdir build/Headers
find KSFramework/KSFramework -type f -name "*.h" -exec cp {} build/Headers \;

mkdir build/Scripts
find KSFramework/KSFramework -type f -name "*.sh" -exec cp {} build/Scripts \;

lipo -info build/libKSFramework.a

echo Done
