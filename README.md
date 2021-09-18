# Ffmpeg Db

*Dataset/library of parsed ffmpeg codec information*

To know ahead of time information about codecs (ie. whether a given codec can
be muxed into a given container), we need to have a database of codec
information. While [this wikipedia page](https://en.wikipedia.org/wiki/Comparison_of_video_container_formats)
has some of this info, it's not complete and doesn't match with ffprobe's output.

That's where this comes in. This repo generates a JSON dataset of file extensions
to the container corresponding to this extension's supported ffmpeg codecs.
It does this using a best effort upper bound approach by parsing FFMPEG's source
code for codec ids in a file containing the muxer associated with a given
extension. This means that it's possible for some false positives where a certain
codec is marked as supported when it's not. For these cases we have a blacklist
that explicitly removes these false positives.
