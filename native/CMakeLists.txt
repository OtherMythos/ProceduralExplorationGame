project(native)
cmake_minimum_required(VERSION 3.1)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "")
set(ENGINE_SOURCE_PATH "" CACHE FILEPATH "Path to the engine source code")

if(ENGINE_SOURCE_PATH STREQUAL "")
    message( FATAL_ERROR "Please populate the ENGINE_SOURCE_PATH variable")
endif()

include_directories(${ENGINE_SOURCE_PATH}/src)
#find_package(${ENGINE_SOURCE_PATH} CONFIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/avEngine/CMake)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/avEngine/CMake)

include_directories(
    ${Colibri_INCLUDE_DIR}
    ${Squirrel_INCLUDE_DIR}
    ${Ogre_INCLUDE_DIR}
    ${EntityX_INCLUDE_DIR}
    ${Bullet_INCLUDE_DIR}
    ${Detour_INCLUDE_DIR}
    ${OpenALSoft_INCLUDE_DIR}
    ${LibSndFile_INCLUDE_DIR}

    ${RAPIDJSON_INCLUDE}

    ${SDL2_INCLUDE_DIRS}
)

include_directories(${AV_LIBS_DIR}/spdlog/include)
include_directories(${AV_LIBS_DIR}/filesystem/)
include_directories(${AV_LIBS_DIR}/tinyxml2/)

add_subdirectory(core)
add_subdirectory(plugin)
#add_subdirectory(tool)