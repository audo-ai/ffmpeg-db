#!/usr/bin/env bash

set -eE

cd "$(dirname "$0")"

for exe in cmake jsonnet; do
  if ! command -v "$exe" &>/dev/null; then
    echo "Error: Please install $exe"
    exit 1
  fi
done

output_folder=ffmpeg_db/data
mkdir -p "$output_folder"
cmake -B codec-extractor/build/ -S codec-extractor/
cmake --build codec-extractor/build/

echo "Running codec-extractor..."
./codec-extractor/build/codec-extractor > ./codec-extractor/build/codec-data.json
echo "Generating output files..."
jsonnet codecs.jsonnet -m "$output_folder"
