//A script to implement a map gen client, which is able to register custom map gen steps and callbacks.
//This script will be called on worker threads.

function notifyRegistered(data){
    ::basePath <- data.basePath;
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
    _mapGen.registerStep(6, "test step", ::basePath + "src/MapGen/NativeClient/TestStepMapGen.nut");
}

function notifyClaimed(data){
    print(data);
}