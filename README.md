# Procedural Exploration Game

[![Build and Test](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/build.yml/badge.svg)](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/build.yml)
[![Build Container](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/buildContainer.yml/badge.svg)](https://github.com/OtherMythos/ProceduralExplorationGame/actions/workflows/buildContainer.yml)

An un-named game for the avEngine.

This game is based on RPG mechanics and built around the idea of exploration.
The gameplay loop focuses on the player exploring a procedural world, finding items, places and combat encounters.
The game is intended to distill the feeling of exploring a large world into a short, biting gameplay loop.

Current features include:
 * Voxel graphics for character models, scenes, items, etc.
 * Point and click combat system.
 * Procedural world, complete with regions which appear in sections.
 * Designed around mobile, i.e quick bursts of play sessions.

Future intended features include:
 * Copious amounts of collectables.
 * Quest and task system.
 * Character customisation.
 * Improved variety in regions, enemies, characters, gameplay sessions.

## Building project
Assets for this project need to be built before they can be used.
This project uses the avEngine asset pipeline, which is based on docker.
Docker must be installed to be able to build this project.
This script will pull the necessary container image, so will take longer to execute the first time.

```bash
./resBuild.sh
```

This script will produce an output directory named 'build', where the built assets are stored.

## Running
Once built this project can be run like any other avEngine project
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

It is recommended that these profiles are defined in the ```avSetupSecondary.cfg``` file, which can be included in the gitignore, so local settings do not get committed.

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