::Base <- {
    function setup(){

        _doFile("res://src/GUI/ScreenManager.nut");
        _doFile("res://src/GUI/Screens/Screen.nut");
        _doFile("res://src/GUI/Screens/MainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/SaveSelectionScreen.nut");
        _doFile("res://src/GUI/Screens/GameplayMainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/ExplorationScreen.nut");
        _doFile("res://src/GUI/Screens/EncounterPopupScreen.nut");

        _doFile("res://src/Logic/ExplorationLogic.nut");

        //::ScreenManager.transitionToScreen(MainMenuScreen());
        ::ScreenManager.transitionToScreen(ExplorationScreen(ExplorationLogic()));
        //::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 1);
    }

    function update(){
        ::ScreenManager.update();
    }
};