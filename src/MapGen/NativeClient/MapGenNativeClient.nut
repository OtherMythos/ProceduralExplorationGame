//A script to implement a map gen client, which is able to register custom map gen steps and callbacks.
//This script will be called on worker threads.

function notifyBegan(data){
    print("Script map gen began");
    print(data);
    data.test <- "hello from the table";
}

function notifyEnded(data){
    print("Script map gen ended");
    print(data);
}

function populateSteps(){
    _mapGen.registerStep(6, "test step", "res://../../src/MapGen/NativeClient/TestStepMapGen.nut");
}

function notifyClaimed(data){
    print(data);
}