cmake_minimum_required(VERSION 2.8.12)

set(CMAKE_CXX_STANDARD 20)

project(codec-extractor)

add_executable(
    codec-extractor
    src/utils/utils.cpp
    src/codec-extractor.cpp
)

target_include_directories(
    codec-extractor BEFORE PRIVATE src/
)

target_link_libraries(
    codec-extractor
    avcodec
    avformat
    avutil
)
