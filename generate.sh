#!/usr/bin/env bash

set -eE

orig_path=$(pwd)
cd "$(dirname "$0")"

mkdir -p build
[ -d build/Ffmpeg ] || git clone https://github.com/FFmpeg/FFmpeg build/Ffmpeg --depth 1 --single-branch
cd build/Ffmpeg
git pull

for exe in grep python3 find jq xargs pcregrep; do
  if ! command -v "$exe" &>/dev/null; then
    echo "Error: Please install $exe"
  fi
done

output_folder=../../ffmpeg_db/data
mkdir -p "$output_folder"

grep -RPo 'AV_CODEC_ID_[A-Z0-9]+' | python3 -c '
import sys, json

fn_to_codecs = {}
for line in sys.stdin:
  fn, codec_raw = line.split(":")
  codec = codec_raw.strip()
  if codec != "AV_CODEC_ID_NONE":
    fn_to_codecs.setdefault(fn, {})[codec] = 1

print(json.dumps({k: list(v) for k, v in fn_to_codecs.items()}))
' > ../codec_ids.json

python3 -c '
import re, sys, json
formatters={}
print(json.dumps([
  {
    mi.group(1): formatters.get(mi.group(1), lambda x: x.strip("\""))(
      re.sub(r"\s+", " ", re.sub(r"NULL_IF_CONFIG_SMALL\((.*)\)", r"\1", mi.group(2)))
    )
    for mi in re.finditer(r"(?:^|(?<=\n))\s*\.([a-zA-Z0-9_]+)\s*=\s*((?:.|\n)*?)(?:,(?=\n)|(?=\n}))", m.group(1))
  }
  for m in re.finditer(r"\{((?:.|\n)*?)\}(?:,|;)\n", sys.stdin.read())
]))' < libavcodec/codec_desc.c > ../codecs.json

find . -iname '*.c' -print0 |
  xargs -0 pcregrep -M 'AVOutputFormat\s+([a-zA-Z_0-9]+)\s*=\s*\{((?:.|\n)*?)\};\n' |
  python3 -c '
import re, sys, json
formatters={
  "extensions": lambda x: sum([
    [v for i in m.group(1).split(",") for v in [i.strip()] if v]
    for m in re.finditer(r"\"([^\"]*)\"", x)
  ], [])
}
print(json.dumps([
  dict({
    mi.group(1): formatters.get(mi.group(1), lambda x: x.strip("\""))(
      re.sub(r"\s+", " ", re.sub(r"NULL_IF_CONFIG_SMALL\((.*)\)", r"\1", mi.group(2)))
    )
    for mi in re.finditer(r"(?:^|(?<=\n))\s*\.([a-zA-Z0-9_]+)\s*=\s*((?:.|\n)*?)(?:,(?=\n)|(?=\n}))", m.group(2))
  }, filename=m.group(1))
  for m in re.finditer(r"(?:(?<=\n)|^)(.*?):[^=]*=\s*\{((?:.|\n)*?)\};\n", sys.stdin.read())
]))' > ../muxers.json

jq -n --argfile muxers ../muxers.json --argfile codec_ids ../codec_ids.json '
  $muxers[] | . + {codec_ids: ($codec_ids[.filename | sub("./";"")] // [])}
' > ../muxers-combined.json

ext_to_codec_output=$output_folder/ext-to-codecs.json
jq -n --argfile muxers ../muxers-combined.json --argfile codecs ../codecs.json \
  --argfile blacklist ../../ext-to-codecs_blacklist.json '
    reduce (
      $muxers[] | .codecs = (
        [
          .codec_ids[] | (
            . as $codec_id | (
              $codecs[] | select(.id == $codec_id) | .name
            )
          )
        ]
      ) | del(.codec_ids) | . as $val | (.extensions // [])[] | {ext: ., val: $val}
    ) as $i ({}; .[$i.ext] = ((
      (.[$i.ext] // []) + $i.val.codecs - ($blacklist[$i.ext] // [])
    ) | unique))
' > $ext_to_codec_output

echo "Generated to $(realpath --relative-to="$orig_path" "$ext_to_codec_output")"

codec_info_output=$output_folder/codec-info.json
mkdir -p "$(dirname "$ext_to_codec_output")"
jq -n --argfile codecs ../codecs.json --argfile muxers ../muxers-combined.json \
  --argfile blacklist ../../ext-to-codecs_blacklist.json '
    reduce ($blacklist | to_entries)[] as $i ({}; . as $val | $i.value[] | $val[.] = (($val[.] // []) + [$i.key])) | . as $rev_blacklist |
    reduce $codecs[] as $i (
      {};
      .[$i.name] = {
        type: ($i.type | sub("AVMEDIA_TYPE_";"") | ascii_downcase),
        extensions: ([
          (($muxers[] | select(.codec_ids[] | contains($i.id)) | .extensions) // [])[]
        ] | unique)
      }
    )
' > $codec_info_output

echo "Generated to $(realpath --relative-to="$orig_path" "$codec_info_output")"