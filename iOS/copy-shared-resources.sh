#!/bin/bash

# Define paths
SHARED_JSAPP_PATH="${SRCROOT}/../shared/jsapp"
SHARED_JSSDK_PATH="${SRCROOT}/../shared/jssdk"
IOS_JSAPP_BUNDLE_PATH="${SRCROOT}/dimina/Resources/JsApp.bundle"
IOS_JSSDK_BUNDLE_PATH="${SRCROOT}/dimina/Resources/JsSdk.bundle"

echo "Copying shared resources to iOS bundles..."

# Create destination directories if they don't exist
mkdir -p "$IOS_JSAPP_BUNDLE_PATH"
mkdir -p "$IOS_JSSDK_BUNDLE_PATH"

# Function to copy files while preserving .gitkeep
copy_files() {
    local src=$1
    local dest=$2
    local name=$3
    
    echo "Copying shared $name files from $src to $dest"
    # Use rsync to copy files while excluding .gitkeep from source but preserving in destination
    rsync -a --exclude='.gitkeep' --delete "$src"/ "$dest"/
    echo "$name files copy completed"
}

# Copy jsapp files
copy_files "$SHARED_JSAPP_PATH" "$IOS_JSAPP_BUNDLE_PATH" "jsapp"

# Copy jssdk files
copy_files "$SHARED_JSSDK_PATH" "$IOS_JSSDK_BUNDLE_PATH" "jssdk"

echo "Shared resources copy completed successfully"
