if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message( FATAL_ERROR "This CMakeLists.txt should be run as a subdirectory to register static plugins for an engine build. Native code can be built using the CMake project found in the native/ directory.")
endif()

message("Processing ProceduralExplorationGame cmake files")

set(StaticPluginIncludes ${CMAKE_CURRENT_LIST_DIR})
set(StaticPluginIncludes ${StaticPluginIncludes} PARENT_SCOPE)

set(BuildDir build)
if(${CMAKE_SYSTEM_NAME} STREQUAL "iOS")
    set(BuildDir buildIos)
    set(IosBuildEnding "-iphoneos")
endif()

FIND_LIBRARY(NATIVE_CORE_LIBRARY NAMES ProceduralExplorationGameNativeCore
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/${BuildDir}/core/${CMAKE_BUILD_TYPE}${IosBuildEnding}
    PATH_SUFFIXES a lib
    )

FIND_LIBRARY(PROCEDURAL_EXPLORATION_GAME_PLUGIN NAMES ProceduralExplorationGamePlugin_static
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/${BuildDir}/plugin/${CMAKE_BUILD_TYPE}${IosBuildEnding}
    PATH_SUFFIXES a lib
    )

if(NATIVE_CORE_LIBRARY AND PROCEDURAL_EXPLORATION_GAME_PLUGIN)
    set(StaticPluginLibraries "${NATIVE_CORE_LIBRARY};${PROCEDURAL_EXPLORATION_GAME_PLUGIN}")
    set(StaticPluginLibraries "${StaticPluginLibraries}" PARENT_SCOPE)

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