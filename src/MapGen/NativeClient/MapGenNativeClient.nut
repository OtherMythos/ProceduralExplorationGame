//A script to implement a map gen client, which is able to register custom map gen steps and callbacks.
//This script will be called on worker threads.

function notifyRegistered(data){
    ::basePath <- data.basePath;

    print("Registering");
    _doFile(::basePath + "src/Constants.nut");
    _doFile(::basePath + "src/System/EnumDef.nut");
    _doFile(::basePath + "src/MapGen/Exploration/Generator/MapConstants.h.nut");

    _doFile(::basePath + "src/Content/PlaceEnums.nut");

    ::EnumDef.commitEnums();

    _doFile(::basePath + "src/Content/Places.nut");
    _doFile(::basePath + "src/Content/PlaceDefs.h.nut");
}

function notifyBegan(data){
    print("Script map gen began");
    print(data);
}

function notifyEnded(data){
    print("Script map gen ended");
    print(data);
}

function populateSteps(){
    _mapGen.registerStep(24, "Determine Places", ::basePath + "src/MapGen/NativeClient/DeterminePlacesMapGen.nut");
}

function notifyClaimed(data){
    print(data);
}