#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$#" -gt 1 || ( "$#" -eq 1 && "$1" != "--build-only" ) ]]; then
    echo "Usage: bash harmony/upload.sh [--build-only]" >&2
    exit 2
fi

# Build both artifacts before publishing either. The core must be available first.
hvigorw --mode module -p product=default -p module=dimina@default -p buildMode=release assembleHar --no-daemon
hvigorw --mode module -p product=default -p module=map_amap@default -p buildMode=release assembleHar --no-daemon

core=dimina/build/default/outputs/default/dimina.har
adapter=map_amap/build/default/outputs/default/map_amap.har
test -s "$core"
test -s "$adapter"
python3 scripts/check-map-publication.py "$adapter"
if [[ "${1:-}" == "--build-only" ]]; then
    exit 0
fi
ohpm publish "$core"
ohpm publish "$adapter"
