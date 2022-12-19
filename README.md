# Turn based game
An un-named project for the avEngine.

This game is based on RPG mechanics and built around the idea of exploration.
The gameplay loop focuses on the player exploring the world, finding items, places and combat encounters.
I hope to have a large number of collectables and a variety of content in this game.

Expected features include:
 * Voxel graphics for character models, scenes, items, etc.
 * Turn based combat system.
 * Copious amounts of collectables.
 * Quest and task system.
 * Designed around mobile, i.e quick bursts of play sessions.

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
./av ~/template/avSetup.cfg
```