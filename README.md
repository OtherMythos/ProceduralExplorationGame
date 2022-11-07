# avEngine Project Template
A bare-bones example of an avEngine project.

This project can be used as a starting point for any work with the avEngine.
This project contains

 * An avSetup.cfg file.
 * An OgreResources.cfg file, to describe resource locations.
 * A SquirrelEntry.nut file, where script execution takes place.
 * resBuild.cfg, used to trigger a build of the asset pipeline.

## Building
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