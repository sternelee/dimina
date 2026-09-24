#!/bin/bash
# Build the real SwiftPM SDK, then compile the Objective-C consumer against its module map.
set -euo pipefail
example_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$example_dir/../../.." && pwd)"
derived_dir="${1:-$(mktemp -d "${TMPDIR:-/tmp}/dimina-objc.XXXXXX")}"
mkdir -p "$derived_dir"
derived_dir="$(cd "$derived_dir" && pwd)"
cd "$repo_dir"
xcodebuild -scheme Dimina -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_dir" CODE_SIGNING_ALLOWED=NO build
module_dir="$derived_dir/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator"
sdk_dir="$(xcrun --sdk iphonesimulator --show-sdk-path)"
for arch in arm64 x86_64; do
    xcrun --sdk iphonesimulator clang \
        -target "$arch-apple-ios14.0-simulator" -isysroot "$sdk_dir" \
        -fobjc-arc -fmodules -fmodules-cache-path="$derived_dir/OCModuleCache" \
        -I "$module_dir" -fmodule-map-file="$module_dir/Dimina.modulemap" \
        -Werror -c "$example_dir/DMPExampleViewController.m" \
        -o "$derived_dir/DMPExampleViewController-$arch.o"
done
echo 'Objective-C consumer compilation passed (arm64 and x86_64).'
