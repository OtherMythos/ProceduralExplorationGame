::Base <- {
    "mExplorationLogic": null,

    "mInventory": null,
    "mPlayerStats": null,
    "mDialogManager": null,

    function setup(){

        _doFile("res://src/Content/Items.nut");
        _doFile("res://src/Content/Places.nut");
        _doFile("res://src/Content/FoundObject.nut");

        _doFile("res://src/System/DialogManager.nut");
        mDialogManager = DialogManager();

        _doFile("res://src/System/Inventory.nut");
        mInventory = ::Inventory();

        _doFile("res://src/System/PlayerStats.nut");
        mPlayerStats = ::PlayerStats();

        _doFile("res://src/GUI/Widgets/InventoryMoneyCounter.nut");

        _doFile("res://src/GUI/ScreenManager.nut");
        _doFile("res://src/GUI/Screens/Screen.nut");
        _doFile("res://src/GUI/Screens/MainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/SaveSelectionScreen.nut");
        _doFile("res://src/GUI/Screens/GameplayMainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/ExplorationScreen.nut");
        _doFile("res://src/GUI/Screens/EncounterPopupScreen.nut");
        _doFile("res://src/GUI/Screens/CombatScreen.nut");
        _doFile("res://src/GUI/Screens/ItemInfoScreen.nut");
        _doFile("res://src/GUI/Screens/InventoryScreen.nut");
        _doFile("res://src/GUI/Screens/VisitedPlacesScreen.nut");
        _doFile("res://src/GUI/Screens/PlaceInfoScreen.nut");
        _doFile("res://src/GUI/Screens/StoryContentScreen.nut");
        _doFile("res://src/GUI/Screens/DialogScreen.nut");

        _doFile("res://src/Logic/ExplorationLogic.nut");
        _doFile("res://src/Logic/CombatLogic.nut");
        _doFile("res://src/Logic/StoryContentLogic.nut");

        mExplorationLogic = ExplorationLogic();

        //::ScreenManager.transitionToScreen(MainMenuScreen());
        ::ScreenManager.transitionToScreen(ExplorationScreen(mExplorationLogic));
        //::ScreenManager.transitionToScreen(::CombatScreen(CombatLogic()));
        //::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 1);
        //::ScreenManager.transitionToScreen(ItemInfoScreen(Item.SIMPLE_SHIELD));
        //::ScreenManager.transitionToScreen(InventoryScreen(mInventory));
        //::ScreenManager.transitionToScreen(VisitedPlacesScreen(mPlayerStats));
        //::ScreenManager.transitionToScreen(::PlaceInfoScreen(Place.HAUNTED_WELL));
        //::ScreenManager.transitionToScreen(::StoryContentScreen(::StoryContentLogic(Place.GOBLIN_VILLAGE)));

    }

    function update(){
        ::ScreenManager.update();
    }
};