#!/bin/bash
# MARE Viewer — Linux build script
# Usage: ./build_linux.sh [configure|build|both]
set -e

ACTION="${1:-both}"

# Path to viewer-build-variables (adjust if your Linux build env differs)
: "${AUTOBUILD_VARIABLES_FILE:=$HOME/dev/viewer-build-variables/variables}"

if [ ! -f "$AUTOBUILD_VARIABLES_FILE" ]; then
    echo "ERROR: AUTOBUILD_VARIABLES_FILE not found: $AUTOBUILD_VARIABLES_FILE"
    echo "Set the env var to point to your viewer-build-variables/variables file."
    exit 1
fi

export AUTOBUILD_VARIABLES_FILE

CMAKE_ARGS=(
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=FALSE
    -DLL_TESTS:BOOL=OFF
    -DPACKAGE:BOOL=TRUE
    -DOPENAL:BOOL=TRUE
    -DFMODSTUDIO:BOOL=OFF
    -DUSE_KDU:BOOL=OFF
    -DHAVOK_TPV:BOOL=OFF
    -DHAVOK:BOOL=OFF
    -DRLV_ALWAYS_ON:BOOL=TRUE
    "-DVIEWER_CHANNEL=Mare Release"
)

if [[ "$ACTION" == "configure" || "$ACTION" == "both" ]]; then
    echo "=== Configuring MARE Viewer (Linux 64-bit ReleaseOS) ==="
    autobuild configure -A 64 -c ReleaseOS -- "${CMAKE_ARGS[@]}"
fi

if [[ "$ACTION" == "build" || "$ACTION" == "both" ]]; then
    echo "=== Building MARE Viewer ==="
    autobuild build -A 64 -c ReleaseOS --no-configure
    echo "=== Build complete ==="
    find . -name "mare-viewer" -type f 2>/dev/null | head -5
fi
