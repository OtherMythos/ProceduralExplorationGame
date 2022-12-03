::Base <- {
    "mExplorationLogic": null,
    "mCombatLogic": null,

    //TODO this will be created on encounter in the future.
    "mCurrentCombatData": null,

    "mInventory": null,
    "mPlayerStats": null,
    "mDialogManager": null,

    function setup(){

        _gui.loadSkins("res://assets/skins/ui.json");

        _doFile("res://src/Content/Items.nut");
        _doFile("res://src/Content/Places.nut");
        _doFile("res://src/Content/FoundObject.nut");
        _doFile("res://src/Content/CombatData.nut");

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
        local enemyData = [
            ::Combat.CombatStats(Enemy.GOBLIN, 20),
            ::Combat.CombatStats(Enemy.GOBLIN)
        ];
        mCurrentCombatData = ::Combat.CombatData(mPlayerStats.mPlayerCombatStats, enemyData);
        //TODO temporary to setup the logic. Really a new combatData would be pushed at the start of a new combat.
        mCombatLogic = CombatLogic(mCurrentCombatData);

        //::ScreenManager.transitionToScreen(MainMenuScreen());
        //::ScreenManager.transitionToScreen(ExplorationScreen(mExplorationLogic));
        //::ScreenManager.transitionToScreen(::CombatScreen(mCombatLogic));
        //::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 1);
        //::ScreenManager.transitionToScreen(ItemInfoScreen(Item.SIMPLE_SHIELD));
        ::ScreenManager.transitionToScreen(InventoryScreen(mInventory));
        //::ScreenManager.transitionToScreen(VisitedPlacesScreen(mPlayerStats));
        //::ScreenManager.transitionToScreen(::PlaceInfoScreen(Place.HAUNTED_WELL));
        //::ScreenManager.transitionToScreen(::StoryContentScreen(::StoryContentLogic(Place.GOBLIN_VILLAGE)));

    }

    function update(){
        ::ScreenManager.update();
    }
};