::BaseBasic <- class extends ::BaseImpl{

    function setup(){

    }

    function update(){

    }

    function loadEnumFiles(){
        _doFile("script://ItemEnums.nut");
        _doFile("script://EnemyEnums.nut");
        _doFile("script://PlaceEnums.nut");
        _doFile("script://ScreenEnums.nut");
        _doFile("script://StatusAfflictionEnums.nut");
        _doFile("script://VoxelEnums.nut");
        _doFile("script://PlacedItemEnums.nut");
    }

    function loadContentFiles(){
        _doFile("res://src/Content/ItemDefs.nut");
        _doFile("res://src/Content/EnemyDefs.nut");
        _doFile("res://src/Content/StatusAfflictionDefs.nut");
        _doFile("res://src/Content/PlaceDefs.nut");
        _doFile("res://src/Content/PlacedItemDefs.nut");
        _doFile("script://VoxelDefs.nut");
    }

    function setupFirst(){

    }

    function loadFilesEnd(){
        _doFile("res://src/GUI/Screens/MainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/HelpScreen.nut");
        _doFile("res://src/GUI/Screens/SaveSelectionScreen.nut");
        _doFile("res://src/GUI/Screens/GameplayMainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/Exploration/ExplorationScreen.nut");
        _doFile("res://src/GUI/Screens/ItemInfoScreen.nut");
        _doFile("res://src/GUI/Screens/InventoryScreen.nut");
        _doFile("res://src/GUI/Screens/VisitedPlacesScreen.nut");
        _doFile("res://src/GUI/Screens/DialogScreen.nut");
        _doFile("res://src/GUI/Screens/TestScreen.nut");
        _doFile("res://src/GUI/Screens/ReadableContentScreen.nut");
        _doFile("res://src/GUI/Screens/SaveEditScreen.nut");
        _doFile("res://src/GUI/Screens/WorldGenerationStatusScreen.nut");
        _doFile("res://src/GUI/Screens/NewSaveValuesScreen.nut");
        _doFile("res://src/GUI/Screens/InventoryItemHelperScreen.nut");
        _doFile("res://src/GUI/Screens/PauseScreen.nut");
        _doFile("res://src/GUI/Screens/SettingsScreen.nut");
    }

    function setupSecondary(){

    }

}