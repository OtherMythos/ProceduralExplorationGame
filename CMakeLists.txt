if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message( FATAL_ERROR "This CMakeLists.txt should be run as a subdirectory to register static plugins for an engine build. Native code can be built using the CMake project found in the native/ directory.")
endif()

message("Processing ProceduralExplorationGame cmake files")

set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)

set(StaticPluginHeaderIncludes ${CMAKE_CURRENT_LIST_DIR})
set(StaticPluginSrcIncludes ${CMAKE_CURRENT_LIST_DIR}/plugins/include)

set(BuildDir build)
set(StaticEnding "android")
if(${CMAKE_SYSTEM_NAME} STREQUAL "iOS")
    set(BuildDir buildIos)
    set(IosBuildEnding "-iphoneos")
    set(StaticEnding "ios")
endif()

FIND_LIBRARY(NATIVE_CORE_LIBRARY NAMES ProceduralExplorationGameNativeCore ProceduralExplorationGameNativeCore_${StaticEnding}_static_${CMAKE_BUILD_TYPE} ProceduralExplorationGameNativeCore_${StaticEnding}_static_Release
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/${BuildDir}/core/${CMAKE_BUILD_TYPE}${IosBuildEnding}
    ${CMAKE_CURRENT_LIST_DIR}/native/buildAndroid/core
    ${CMAKE_CURRENT_LIST_DIR}/plugins/
    PATH_SUFFIXES a lib
    )

FIND_LIBRARY(PROCEDURAL_EXPLORATION_GAME_PLUGIN NAMES ProceduralExplorationGamePlugin_static ProceduralExplorationGamePlugin_${StaticEnding}_static_${CMAKE_BUILD_TYPE} ProceduralExplorationGamePlugin_${StaticEnding}_static_Release
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/${BuildDir}/plugin/${CMAKE_BUILD_TYPE}${IosBuildEnding}
    ${CMAKE_CURRENT_LIST_DIR}/native/buildAndroid/plugin
    ${CMAKE_CURRENT_LIST_DIR}/plugins/
    PATH_SUFFIXES a lib
    )

message(STATUS "Possible static libs: ${POSSIBLE_LIBS}")

if(NATIVE_CORE_LIBRARY AND PROCEDURAL_EXPLORATION_GAME_PLUGIN)
    set(StaticPluginLibraries "${NATIVE_CORE_LIBRARY};${PROCEDURAL_EXPLORATION_GAME_PLUGIN}")
    set(StaticPluginLibraries "${StaticPluginLibraries}" PARENT_SCOPE)

    set(StaticPluginIncludes "${StaticPluginHeaderIncludes};${StaticPluginSrcIncludes}")
    set(StaticPluginIncludes ${StaticPluginIncludes} PARENT_SCOPE)

    MESSAGE(STATUS "Found ProceduralExplorationGame: ${StaticPluginLibraries}")
    MESSAGE(STATUS "Found ProceduralExplorationGame includes: ${StaticPluginIncludes}")
else()
    message( FATAL_ERROR "Unable to find game native libraries")
endif()

file(GLOB PROJ_TO_BUNDLE
    src
    extra
    build
    avSetup.cfg
    OgreResources.cfg
)
#Remove any hidden files from the glob.
list(FILTER PROJ_TO_BUNDLE EXCLUDE REGEX "\\/\\..+$")
set(PROJ_TO_BUNDLE "${PROJ_TO_BUNDLE}" CACHE INTERNAL "PROJ_TO_BUNDLE")