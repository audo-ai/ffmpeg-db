extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

#include <cstdio>
#include <iostream>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "utils/json-lib.hpp"
#include "utils/utils.hpp"

using std::cout;
using std::endl;
using std::getline;
using std::map;
using std::set;
using std::string;
using std::stringstream;
using std::vector;

vector<AVOutputFormat> getOutputFormats() {
    vector<AVOutputFormat> outputFormats;
    void *i = nullptr;
    const AVOutputFormat *outputFormat = nullptr;
    while (outputFormat = av_muxer_iterate(&i)) {
        outputFormats.emplace_back(*outputFormat);
    }
    return outputFormats;
}

bool operator<(const AVCodec &x, const AVCodec &y) {
    return strcmp(x.name, y.name);
}

set<AVCodec> getCodecs() {
    set<AVCodec> codecs;
    void *i = nullptr;
    const AVCodec *codec = nullptr;
    while (codec = av_codec_iterate(&i)) {
        codecs.emplace(AVCodec(*codec));
    }
    return codecs;
}

bool formatSupportsCodec(const AVOutputFormat &format, const AVCodec &codec) {
    return avformat_query_codec(&format, codec.id, FF_COMPLIANCE_NORMAL) == 1;
}

int main() {
    map<string, set<string>> extToCodecs;
    map<string, set<string>> codecToExts;

    for (auto &format : getOutputFormats()) {
        for (auto &codec : getCodecs()) {
            const auto &codecName = string(codec.name);
            auto &exts =
                codecToExts.emplace(codecName, set<string>()).first->second;
            if (formatSupportsCodec(format, codec)) {
                if (!format.extensions) {
                    continue;
                }
                for (auto &ext : splitStr(format.extensions, ',')) {
                    auto &codecs =
                        extToCodecs.emplace(ext, set<string>()).first->second;
                    codecs.emplace(codecName);
                    exts.emplace(ext);
                }
            }
        }
    }
    auto codecs = getCodecs();
    auto codecTypeByName = map<string, AVMediaType>();
    for (auto &i : codecs) {
        codecTypeByName[i.name] = i.type;
    }

    stringstream ss;
    serializeManualDict(ss, [&]() {
        manualDictEntryFunc(ss, "extToCodecs",
                            [&]() { serializeJson(ss, extToCodecs); });
        manualDictEntryFunc(ss, "codecInfo", [&]() {
            serializeIter(
                ss, codecToExts.begin(), codecToExts.end(), '{', '}',
                [&](auto entry) {
                    const string codecName(entry->first);
                    manualDictEntryFunc(ss, codecName, [&]() {
                        serializeManualDict(ss, [&]() {
                            const char *typeStr = av_get_media_type_string(
                                codecTypeByName[codecName]);
                            manualDictEntry(ss, "type",
                                            typeStr ? typeStr : "null");
                            manualDictEntry(ss, "extensions", entry->second);
                        });
                    });
                });
        });
    });

    cout << ss.str() << endl;
}
