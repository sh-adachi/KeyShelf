#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/clang-cache .build/swift-cache
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
ACTION="${1:-build}"
if [ "$#" -gt 0 ]; then shift; fi
case "$ACTION" in
    build|test|package|run)
        exec swift "$ACTION" --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security "$@"
        ;;
    *) exec swift "$ACTION" "$@" ;;
esac
