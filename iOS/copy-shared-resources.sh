#!/bin/bash

# Define paths
SHARED_JSAPP_PATH="${SRCROOT}/../shared/jsapp"
SHARED_JSSDK_PATH="${SRCROOT}/../shared/jssdk"
IOS_JSAPP_BUNDLE_PATH="${SRCROOT}/dimina/JSAppBundle.bundle"
IOS_JSSDK_BUNDLE_PATH="${SRCROOT}/dimina/JSSDKBundle.bundle"

echo "Copying shared resources to iOS bundles..."

# Create destination directories if they don't exist
mkdir -p "$IOS_JSAPP_BUNDLE_PATH"
mkdir -p "$IOS_JSSDK_BUNDLE_PATH"

# Copy jsapp files
echo "Copying shared jsapp files from $SHARED_JSAPP_PATH to $IOS_JSAPP_BUNDLE_PATH"
cp -R "$SHARED_JSAPP_PATH"/* "$IOS_JSAPP_BUNDLE_PATH"/ 2>/dev/null || :
echo "jsapp files copy completed"

# Copy jssdk files
echo "Copying shared jssdk files from $SHARED_JSSDK_PATH to $IOS_JSSDK_BUNDLE_PATH"
cp -R "$SHARED_JSSDK_PATH"/* "$IOS_JSSDK_BUNDLE_PATH"/ 2>/dev/null || :
echo "jssdk files copy completed"

echo "Shared resources copy completed successfully"
