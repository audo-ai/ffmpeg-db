import json

from pkg_resources import resource_filename


def ext_to_codecs_json():
    with open(resource_filename('ffmpeg_db', 'data/ext-to-codecs.json')) as f:
        return json.load(f)


def codec_info_json():
    with open(resource_filename('ffmpeg_db', 'data/codec-info.json')) as f:
        return json.load(f)
