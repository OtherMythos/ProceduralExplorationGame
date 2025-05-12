cmake_minimum_required(VERSION 3.5)
project(ProceduralExplorationGameNativeCore)

file(GLOB_RECURSE srcs "src/*.cpp")

add_library(${PROJECT_NAME} STATIC
    ${srcs}
)
target_include_directories(${PROJECT_NAME} PUBLIC src)