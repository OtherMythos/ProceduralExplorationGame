project(VoxelConverterTool)
cmake_minimum_required(VERSION 3.1)

file(GLOB_RECURSE tool_srcs "src/*.cpp")

add_executable(${PROJECT_NAME}
    ${tool_srcs}
)

target_include_directories(${PROJECT_NAME} PUBLIC src)