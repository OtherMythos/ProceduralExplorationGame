cmake_minimum_required(VERSION 3.5)
project(ProceduralExplorationGameNativeCore)

file(GLOB_RECURSE srcs "src/*.cpp")

if(PLATFORM STREQUAL "OS64")
    file(GLOB_RECURSE mm_srcs "src/Platform/iOS/*.mm")
    list(APPEND srcs ${mm_srcs})
endif()

add_library(${PROJECT_NAME} STATIC
    ${srcs}
)
target_include_directories(${PROJECT_NAME} PUBLIC src)