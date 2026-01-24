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
        _doFile("script://OrbEnums.nut");
        _doFile("script://StatusAfflictionEnums.nut");
        _doFile("script://VoxelEnums.nut");
        _doFile("script://PlacedItemEnums.nut");
        _doFile("script://ArtifactEnums.nut");
        _doFile("script://CameraEffectEnums.nut");
        _doFile("script://WorldEffectEnums.nut");
    }

    function loadContentFiles(){
        _doFile("res://src/Content/ItemDefs.nut");
        _doFile("res://src/Content/EnemyDefs.nut");
        _doFile("res://src/Content/Orb.nut");
        _doFile("res://src/Content/OrbDefs.nut");
        _doFile("res://src/Content/StatusAfflictionDefs.nut");
        _doFile("res://src/Content/PlaceDefs.nut");
        _doFile("res://src/Content/PlacedItemDefs.nut");
        _doFile("res://src/Content/Artifact.nut");
        _doFile("res://src/Content/ArtifactDefs.nut");
        _doFile("script://VoxelDefs.nut");
        _doFile("res://src/Content/WorldEffects.nut");
    }

    function setupFirst(){

    }

    function loadFilesEnd(){
        _doFile("res://src/GUI/Screens/MainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/HelpScreen.nut");
        _doFile("res://src/GUI/Screens/SaveSelectionScreen.nut");
        _doFile("res://src/GUI/Screens/GameplayMainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/Exploration/ExplorationScreen.nut");
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
        _doFile("res://src/GUI/Screens/GameplayMainMenuComplexScreen.nut");
        _doFile("res://src/GUI/Screens/ExplorationMapSelectScreen.nut");
        _doFile("res://src/GUI/Screens/GameTitleScreen.nut");
        _doFile("res://src/GUI/Screens/SettingsScreen.nut");
        _doFile("res://src/GUI/Screens/OtherMythosSplashScreen.nut");
        _doFile("res://src/GUI/Screens/FoundOrbScreen.nut");
        _doFile("res://src/GUI/Screens/BankDepositWithdrawScreen.nut");
        _doFile("res://src/GUI/Screens/ArtifactScreen.nut");

        _doFile("res://src/GUI/Widgets/BankWidget.nut");
        _doFile("res://src/GUI/Widgets/ShopWidget.nut");
        _doFile("res://src/GUI/Widgets/InventoryHoverItemInfo.nut");

        _doFile("res://src/Content/World/WorldComponents.nut");

        _doFile("res://src/Logic/World/CameraEffects/CameraShakeEffect.nut");
        _doFile("res://src/Content/CameraEffectDefs.nut");

        //Particles must be loaded later to ensure the custom emitters from the plugin are registered.
        local platform = _settings.getPlatform();
        _resources.addResourceLocation("res://build/assets/particles", platform == _PLATFORM_ANDROID ? "APKFileSystem" : "FileSystem", "Particles");
        _resources.initialiseResourceGroup("Particles");
    }

    function setupSecondary(){

    }

}