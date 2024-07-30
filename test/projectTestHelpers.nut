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


::_testHelper.STEPS_WAIT_FOR_MAP_GEN_COMPLETE <- function(){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    if(!currentWorld.isActive()){
        ::_testHelper.repeatStep();
    }
};

::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY <- [
    function(){
        ::_testHelper.mousePressWidgetForText("Play");
        ::_testHelper.queryWindowExists("SaveSelectionScreen");
    },
    function(){
        ::_testHelper.mousePressWidgetForText("new save");

        local screen = ::ScreenManager.getScreenForLayer(1);
        screen.mEditBox_.setText("test");
        ::_testHelper.mousePressWidgetForText("confirm");
    },
    function(){
        ::_testHelper.mousePressWidgetForText("Explore");
    },
    ::_testHelper.STEPS_WAIT_FOR_MAP_GEN_COMPLETE
];