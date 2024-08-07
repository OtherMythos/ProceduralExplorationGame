if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    message( FATAL_ERROR "This CMakeLists.txt should be run as a subdirectory to register static plugins for an engine build. Native code can be built using the CMake project found in the native/ directory.")
endif()

message("Processing ProceduralExplorationGame cmake files")

set(StaticPluginIncludes ${CMAKE_CURRENT_LIST_DIR})
set(StaticPluginIncludes ${StaticPluginIncludes} PARENT_SCOPE)

FIND_LIBRARY(NATIVE_CORE_LIBRARY NAMES ProceduralExplorationGameNativeCore
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/build/core/${CMAKE_BUILD_TYPE}
    PATH_SUFFIXES a lib
    )

FIND_LIBRARY(PROCEDURAL_EXPLORATION_GAME_PLUGIN NAMES ProceduralExplorationGamePlugin_static
    PATHS ${CMAKE_CURRENT_LIST_DIR}/native/build/plugin/${CMAKE_BUILD_TYPE}
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