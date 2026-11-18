#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if (( $# != 0 )); then
    echo "Usage: $0" >&2
    exit 1
fi

cmake_args=(-DCMAKE_BUILD_TYPE=Release)
prefix=lib
extension=a
case "$(uname -s)" in
    Linux)
        os=linux
        case "$(uname -m)" in
            x86_64) arch=amd64 ;;
            aarch64|arm64) arch=arm64 ;;
            *) echo "Unsupported Linux architecture: $(uname -m)" >&2; exit 1 ;;
        esac
        ;;
    Darwin)
        if [[ "$(uname -m)" != arm64 ]]; then
            echo "macOS builds require an arm64 shell (not an Intel/Rosetta shell)." >&2
            exit 1
        fi
        os=darwin
        arch=arm64
        cmake_args+=(-DCMAKE_OSX_ARCHITECTURES=arm64)
        ;;
    MINGW*|MSYS*|CYGWIN*)
        case "${CMAKE_GENERATOR:-Visual Studio}" in
            "Visual Studio"*) ;;
            *) echo "Windows builds require a Visual Studio CMake generator; unset CMAKE_GENERATOR or select Visual Studio." >&2; exit 1 ;;
        esac
        os=windows
        arch=amd64
        prefix=
        extension=lib
        cmake_args+=(-A x64)
        ;;
    *)
        echo "Supported hosts: Linux, macOS arm64, and Windows with Git Bash." >&2
        exit 1
        ;;
esac

build="$root/.build/native/${os}_$arch"
cmake -S "$root/scripts" -B "$build" "${cmake_args[@]}"
cmake --build "$build" --config Release --parallel

for name in plutovg plutosvg; do
    destination="$root/$name/lib/${os}_$arch"
    mkdir -p "$destination"
    cp "$build/lib/Release/$prefix$name.$extension" "$destination/$prefix$name.$extension"
done

echo "Static libraries written to plutovg/lib/${os}_$arch and plutosvg/lib/${os}_$arch"
