# Procedural Exploration Game

[![Build and Test](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/build.yml/badge.svg)](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/build.yml)
[![Build Container](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/buildContainer.yml/badge.svg)](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/buildContainer.yml)

[![Join the Discord](https://img.shields.io/badge/Join%20the%20Discord-purple?logo=discord&logoColor=ffffff)](https://discord.gg/P47ykcg5ed)
[![Subscribe on YouTube](https://img.shields.io/badge/Subscribe%20on%20YouTube-red?logo=youtube&logoColor=ffffff)](https://www.youtube.com/channel/UCUIWHmJMVfNSahrnPKzli3Q?sub_confirmation=1)



An un-named game for the avEngine.

This game is based on RPG mechanics and built around the idea of exploration.
The gameplay loop focuses on the player exploring a procedural world, finding items, places and combat encounters.
The game is intended to distill the feeling of exploring a large world into a short, biting gameplay loop.



Current features include:
 * Voxel graphics for character models, scenes, items, etc.
 * Fluid combat system built round player movement.
 * Procedural world, complete with regions which appear in sections.
 * Designed around mobile, i.e quick bursts of play sessions.

Future intended features include:
 * Copious amounts of collectables.
 * Quest and task system.
 * Character customisation.
 * Improved variety in regions, enemies, characters, gameplay sessions.

## Building the Project

This project relies on both assets built for gameplay and a native plugin which contains implementations for many processor intensive jobs in the codebase.
Both of these targets need to be built before an avEngine executable can run this project.

### Asset Build
Assets for this project need to be built before they can be used.
This project uses the avEngine asset pipeline, which is based on docker.
Docker must be installed to be able to build this project.
This script will pull the necessary container image, so will take longer to execute the first time.

```bash
./resBuild.sh
```

This script will produce an output directory named 'build', where the built assets are stored.

### Native Plugin
The native plugin is written in C++ and built using the provided CMake build system.
The game will throw an error if the native plugin cannot be loaded on startup.
This must be compiled on the target system, unlike the assets which can be built with Docker.

Building the native plugin works similar to any CMake build system:

```bash
cd native
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Debug -DENGINE_SOURCE_PATH=/avEngineSource -DAV_LIBS_DIR=/BuiltAvLibs/Debug ..
cmake --build .
```

Engine source path and a built copy of the engine ```avBuilt``` directory is necessary to build the project. The windows build also relies on the ```avCore.lib``` file built as part of engine build.

## Running
Once both the native plugin and game assets have been built, this project can be run like any other avEngine project
```bash
./av avSetup.cfg
```

## Developer Tools
A few utility features are provided to help speed up development.

### Profiles
Profiles allow certain modifications to the game's operation.
These might be used to allow switching directly to a screen on startup, showing more debug information or setting up testing gameplay features, among other things.

Desired profiles should be enabled by defining a user setting:

```json
{
    "UserSettings":{
        "profile": "DevelopmentBeginExploration,DisplayWorldStats"
    }
}
```

It is recommended that these profiles are defined in the ```avSetupSecondary.cfg``` file, which is included in the gitignore, so local settings do not get committed.

### Developer Flags
Registered flags can be specified in the ```avSetupSecondary.cfg``` file to setup certain types of logic. The following table describes the available flags and their use.

| Flag | Values | Description |
|----------|----------|----------|
| ```forceScreen``` | Any string from ```::ScreenString``` | Force a screen at startup rather than the usual gameplay path. |
| ```forceWorld``` | Any string from ```::WorldTypeStrings``` | Force gameplay to initiate with the specified world type. |
| ```forceMap``` | Any valid map name | Force a map to be used with 'forceWorld' for visited places. Otherwise a default will be used. |

example:
```json
{
    "UserSettings":{
        "forceScreen": "helpScreen",
        "forceWorld": "ProceduralDungeonWorld"
    }
}
```

### Developer Functions
A number of functions have been exposed for use in the ```developerTools.nut``` script file.
This file is included in the git ignore and is meant to implement developer specific workarounds for common problems.

An example file would look like this:

```c
::developerTools_ <- {
    function checkRightClickWorkarounds(){
        print("I am called when right click workarounds are enabled");
    }
};
```

### Save Files
Save files are written to the following directories for the following platforms:

| Platform | Location |
|----------|----------|
| Linux | ~/.local/share/av/rpg-game |
| Windows | %APPDATA%/av/rpg-game |
| MacOS | ~/Library/Application Support/av/rpg-game |

Save files are indexed with an integer value.
