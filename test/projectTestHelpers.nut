//Helpers specific to the game itself, to separate the test setup script from game logic.

::_testHelper.clearAllSaves <- function(){
    print("Cleared all saves");
    _system.removeAll("user://");
}

::_testHelper.generateSimpleSaves <- function(numSaves){
    for(local i = 0; i < numSaves; i++){
        local freeSlot = i;
        local saveManager = SaveManager();
        local save = saveManager.produceSave();
        save.playerName = "generated save " + freeSlot;
        ::SaveManager.writeSaveAtPath("user://" + freeSlot, save);
    }
}