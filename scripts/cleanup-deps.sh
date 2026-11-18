#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ -L "$root/deps" ]]; then
	echo "Refusing to clean a symlinked deps directory." >&2
	exit 1
fi

for name in plutovg plutosvg; do
	dir="$root/deps/$name"
	if [[ -L "$dir" || ! -d "$dir/source" || ! -f "$dir/CMakeLists.txt" || ! -f "$dir/LICENSE" ]]; then
		echo "Expected a non-symlinked upstream source tree at $dir" >&2
		exit 1
	fi
done

paths=(
	plutovg/.github
	plutovg/.gitignore
	plutovg/examples
	plutovg/smiley.png
	plutosvg/.github
	plutosvg/.gitignore
	plutosvg/.gitmodules
	plutosvg/examples
	plutosvg/camera.png
)

for relative in "${paths[@]}"; do
	path="$root/deps/$relative"
	if [[ -e "$path" || -L "$path" ]]; then
		rm -rf -- "$path"
		printf 'Removed deps/%s\n' "$relative"
	fi
done

nested="$root/deps/plutosvg/plutovg"
if [[ -d "$nested" && ! -L "$nested" ]]; then
	shopt -s nullglob dotglob
	entries=("$nested"/*)
	if ((${#entries[@]} == 0)); then
		rmdir -- "$nested"
		echo "Removed empty deps/plutosvg/plutovg"
	else
		echo "Kept nonempty deps/plutosvg/plutovg"
	fi
fi
