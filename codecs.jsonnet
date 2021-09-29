local movExtensions = ["3g2","3gp","f4v","isma","ismv","m4a","m4b","m4v","mov","mp4","psp"];
local movUnsupportedCodecs = ["vp8", "flac", "truehd"];
local unsupportedCombos = [[movExtensions, movUnsupportedCodecs]];

local isBlacklisted(ext, codec) = (
    std.length([
        c
        for c in unsupportedCombos
        if std.setMember(codec, c[1]) && std.setMember(ext, c[0])
    ]) > 0
);

local data = import 'codec-extractor/build/codec-data.json';
{
    "ext-to-codecs.json": {
        [ext]: [
            codec
            for codec in data.extToCodecs[ext]
            if !isBlacklisted(ext, codec)
        ]
        for ext in std.objectFields(data.extToCodecs)
    },
    "codec-info.json": {
        [codec]: data.codecInfo[codec] + {extensions: [
            ext
            for ext in data.codecInfo[codec].extensions
            if !isBlacklisted(ext, codec)
        ]}
        for codec in std.objectFields(data.codecInfo)
    }
}

