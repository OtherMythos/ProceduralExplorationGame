//A script to implement a map gen client, which is able to register custom map gen steps and callbacks.
//This script will be called on worker threads.

function notifyRegistered(data){
    ::basePath <- data.basePath;
    ::basePlacesPath <- data.basePath + "build/assets/places";

    print("Registering");
    _doFile(::basePath + "src/Constants.nut");
    _doFile(::basePath + "src/System/EnumDef.nut");
    _doFile(::basePath + "src/MapGen/Exploration/Generator/MapConstants.h.nut");

    _doFile(::basePath + "src/Content/PlaceEnums.nut");

    ::EnumDef.commitEnums();

    _doFile(::basePath + "src/Content/Places.nut");
    _doFile(::basePath + "src/Content/PlaceDefs.h.nut");

    processPlacesData();
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
    _mapGen.registerStep("DeterminePlaces", "Determine Places", ::basePath + "src/MapGen/NativeClient/DeterminePlacesMapGen.nut");
}

function notifyClaimed(data){
    print(data);
}

function processPlacesData(){

    local p = ::placeData;

    local count = 0;
    foreach(c,i in ::Places){

        local centreX = p[count];
        local centreY = p[count + 1];
        local centreZ = p[count + 2];
        local halfX = p[count + 3];
        local halfY = p[count + 4];
        local halfZ = p[count + 5];
        local radius = p[count + 6];

        i.mCentre = [centreX, centreY, centreZ];
        i.mHalf = [halfX, halfY, halfZ];
        i.mRadius = radius;

        count += 7;
    }
    getroottable().rawdelete("placeData");
}