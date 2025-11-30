cmake_minimum_required(VERSION 3.5)
project(native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "")
set(ENGINE_SOURCE_PATH "" CACHE FILEPATH "Path to the engine source code")

if(ENGINE_SOURCE_PATH STREQUAL "")
    message( FATAL_ERROR "Please populate the ENGINE_SOURCE_PATH variable")
endif()

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG=1 -D_DEBUG=1")

if(PLATFORM STREQUAL "OS64" OR PLATFORM STREQUAL "android")
    set(STATIC_ONLY TRUE)
endif()

if(PLATFORM STREQUAL "android")
    add_definitions(-DTARGET_ANDROID)
endif()

if(PLATFORM STREQUAL "OS64")
    add_definitions(-DTARGET_IPHONE)
endif()

include_directories(${ENGINE_SOURCE_PATH}/src)
list(APPEND CMAKE_MODULE_PATH ${ENGINE_SOURCE_PATH}/CMake)
add_subdirectory(${ENGINE_SOURCE_PATH}/CMake avEngineSource)

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
include_directories(${AV_LIBS_DIR}/sds_library/include/sds)

add_subdirectory(core)
add_subdirectory(plugin)
#add_subdirectory(tool)