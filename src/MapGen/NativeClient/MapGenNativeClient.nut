//A script to implement a map gen client, which is able to register custom map gen steps and callbacks.
//This script will be called on worker threads.

function notifyBegan(){
    print("Script map gen began");
}

function notifyEnded(){
    print("Script map gen ended");
}