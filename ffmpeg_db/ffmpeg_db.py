import json

from pkg_resources import resource_filename


def load_resource(name):
    with open(resource_filename('ffmpeg_db', name)) as f:
        return json.load(f)


def ext_to_codecs_json():
    return load_resource('data/ext-to-codecs.json')


def codec_info_json():
    return load_resource('data/codec-info.json')
