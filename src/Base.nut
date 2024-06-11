::Base <- {
    mExplorationLogic = null

    mPlayerStats = null
    mDialogManager = null
    mInputManager = null
    mSaveManager = null
    mGameProfiles_ = null

    mTargetInterface_ = TargetInterface.DESKTOP
    mFullscreenMode_ = FullscreenMode.WINDOWED
    mForceSmallWorld = false

    function checkUserParams(){
        //TODO work around the fact that I can't use multiple avSetup files to override this yet.
        if(_settings.getPlatform() == _PLATFORM_IOS){
            mTargetInterface_ = TargetInterface.MOBILE;
        }
    }
    function getTargetInterface(){
        return mTargetInterface_;
    }

    function determineForcedScreen(){
        local forcedScreen = _settings.getUserSetting("forceScreen");
        if(forcedScreen == null || typeof forcedScreen != "string") return null;
        foreach(c,i in ::ScreenString){
            if(i == forcedScreen) return c;
        }
        return null;
    }
    function determineForcedWorld(){
        local forcedWorld = _settings.getUserSetting("forceWorld");
        if(forcedWorld == null || typeof forcedWorld != "string") return null;
        foreach(c,i in ::WorldTypeStrings){
            if(i == forcedWorld) return c;
        }
        return null;
    }
    function determineGameProfiles(){
        local profileVal = _settings.getUserSetting("profile");
        if(profileVal == null || typeof profileVal != "string") return null;
        local profilesSplit = split(profileVal, ",");

        local activeProfiles = {};
        foreach(i in profilesSplit){
            local profile = getGameProfileForString_(i);
            if(profile != null) activeProfiles.rawset(profile, true);
        }

        local outProfiles = [];
        foreach(c,i in activeProfiles){
            outProfiles.append(c);
        }

        return outProfiles
    }
    function getGameProfileForString_(profile){
        for(local i = 0; i < GameProfile.MAX; i++){
            if(profile == ::GameProfileString[i]) return i;
        }
        return null;
    }
    function getScreenDataForForcedScreen(screenId){
        local data = null;
        if(screenId == Screen.INVENTORY_SCREEN){
            data = {"stats": mPlayerStats}
        }
        else if(screenId == Screen.EXPLORATION_SCREEN){
            data = {"logic": mExplorationLogic}
        }
        else if(screenId == Screen.VISITED_PLACES_SCREEN){
            data = {"stats": mPlayerStats}
        }
        return ::ScreenManager.ScreenData(screenId, data);
    }

    function setup(){
        _system.ensureUserDirectory();

        printVersionInfos();
        checkUserParams();
        registerProfiles_();
        setupDeveloperWorkaroundsPre_();

        if(!(::Base.isProfileActive(GameProfile.FORCE_WINDOWED))){
            setupFullscreen();
        }

        //TODO move this somewhere else.
        _animation.loadAnimationFile("res://build/assets/animation/baseAnimation.xml");
        _animation.loadAnimationFile("res://build/assets/characterAnimations/equippableAnimation.xml");

        createLights();

        _gui.loadSkins("res://build/assets/skins/ui.json");
        _gui.loadSkins("res://build/assets/skins/itemSkins.json");

        _doFile("res://src/System/InputManager.nut");
        _doFile("res://src/Util/VoxToMesh.nut");
        _doFile("res://src/Util/IdPool.nut");
        _doFile("res://src/Logic/Util/PercentageEncounterHelper.nut");
        _doFile("res://src/Logic/Util/SpoilsData.nut");
        _doFile("res://src/Logic/Entity/EntityManager.nut");
        _doFile("res://src/Logic/Entity/EntityComponent.nut");

        //TODO shift this off somewhere else.
        _doFile("res://src/Content/Enemies/BasicEnemyScript.nut");
        _doFile("res://src/Content/GenericCallbacks.nut");

        _doFile("res://src/Content/Enemies.nut");
        _doFile("res://src/Content/Projectiles.nut");
        _doFile("res://src/Content/Equippables.nut");
        _doFile("res://src/Content/Items.nut");
        _doFile("res://src/Content/Places.nut");
        _doFile("res://src/Content/FoundObject.nut");
        _doFile("res://src/Content/CombatData.nut");
        _doFile("res://src/Content/Moves.nut");
        _doFile("res://src/Content/StatsEntry.nut");

        _doFile("res://src/DebugOverlayManager.nut");
        _doFile("res://src/DebugConsole.nut");
        _doFile("res://src/Content/DebugCommands.nut");

        _doFile("res://src/Character/CharacterModelAnimations.nut");
        _doFile("res://src/Character/CharacterModel.nut");
        _doFile("res://src/Character/CharacterGenerator.nut");
        _doFile("res://src/Character/CharacterModelTypes.nut");

        _doFile("res://src/System/DatablockManager.nut");

        _doFile("res://src/System/DialogManager.nut");
        mDialogManager = DialogManager();

        _doFile("res://src/System/Inventory.nut");

        _doFile("res://src/System/PlayerStats.nut");
        mPlayerStats = ::PlayerStats();

        _doFile("res://src/System/Save/SaveConstants.nut");
        _doFile("res://src/System/Save/Parsers/SaveFileParser.nut");
        _doFile("res://src/System/Save/SaveManager.nut");
        mSaveManager = ::SaveManager();

        _doFile("res://src/MapGen/Exploration/Generator/Biomes.nut");
        _doFile("res://src/MapGen/Exploration/Generator/MapGen.nut");
        _doFile("res://src/MapGen/MapViewer.nut");
        _doFile("res://src/MapGen/VisitedLocationMapViewer.nut");
        _doFile("res://src/MapGen/Exploration/Viewer/ExplorationMapViewer.nut");
        _doFile("res://src/MapGen/Dungeon/Viewer/DungeonMapViewer.nut");
        _doFile("res://src/MapGen/Dungeon/Generator/DungeonGen.nut");
        _doFile("res://src/MapGen/Exploration/Generator/MapGenHelpers.nut");

        ::GuiWidgets <- {};
        _doFile("res://src/GUI/Widgets/InventoryBaseCounter.nut");
        _doFile("res://src/GUI/Widgets/InventoryMoneyCounter.nut");
        _doFile("res://src/GUI/Widgets/InventoryEXPCounter.nut");
        _doFile("res://src/GUI/Widgets/TargetEnemyWidget.nut");
        _doFile("res://src/GUI/Widgets/ProgressBar.nut");

        _doFile("res://src/GUI/Billboard/BillboardManager.nut");

        _doFile("res://src/GUI/PopupManager.nut");
        _doFile("res://src/GUI/Popups/Popup.nut");
        _doFile("res://src/GUI/Popups/BottomOfScreenPopup.nut");
        _doFile("res://src/GUI/Popups/RegionDiscoveredPopup.nut");
        _doFile("res://src/GUI/Popups/SingleTextPopup.nut");
        ::PopupManager.setup();

        _doFile("res://src/GUI/EffectManager.nut");
        _doFile("res://src/GUI/Effects/Effect.nut");
        _doFile("res://src/GUI/Effects/SpreadCoinEffect.nut");
        _doFile("res://src/GUI/Effects/LinearCoinEffect.nut");
        _doFile("res://src/GUI/Effects/LinearEXPOrbEffect.nut");
        _doFile("res://src/GUI/Effects/FoundItemEffect.nut");
        _doFile("res://src/GUI/Effects/FoundItemEffectIdle.nut");
        ::EffectManager.setup();

        _doFile("res://src/GUI/ScreenManager.nut");
        _doFile("res://src/GUI/EffectAnimationRenderWindow.nut");
        _doFile("res://src/GUI/VersionInfoWindow.nut");
        ::ScreenManager.setup();
        _doFile("res://src/GUI/Screens/Screen.nut");
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
        _doFile("res://src/GUI/Screens/SaveEditScreen.nut");
        _doFile("res://src/GUI/Screens/WorldGenerationStatusScreen.nut");
        _doFile("res://src/GUI/Screens/NewSaveValuesScreen.nut");
        _doFile("res://src/GUI/Screens/InventoryItemHelperScreen.nut");
        _doFile("res://src/GUI/Screens/PauseScreen.nut");

        _doFile("res://src/Logic/EntityTargetManager.nut");
        _doFile("res://src/Logic/ActiveEnemyEntry.nut");
        _doFile("res://src/Logic/World/TerrainChunkManager.nut");
        _doFile("res://src/Logic/World/TerrainChunkFileHandler.nut");
        _doFile("res://src/Logic/World/World.nut");
        _doFile("res://src/Logic/World/VisitedLocationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorld.nut");
        _doFile("res://src/Logic/World/TestingWorld.nut");
        _doFile("res://src/Logic/World/WorldPreparer.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorldPreparer.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorldPreparer.nut");
        _doFile("res://src/Logic/World/VisitedLocationWorldPreparer.nut");
        _doFile("res://src/Logic/ExplorationLogic.nut");
        _doFile("res://src/Logic/ExplorationProjectileManager.nut");

        _doFile("res://src/Logic/World/Actions/WorldAction.nut");
        _doFile("res://src/Logic/World/Actions/EXPTrailAction.nut");

        if(_system.exists("res://developerTools.nut")){
            _doFile("res://developerTools.nut");
        }

        _doFile("res://src/GUI/RenderIconManager.nut");
        ::RenderIconManager.setup();

        setupBaseMaterials();
        setupBaseMeshes();

        ::InputManager.setup();

        mExplorationLogic = ExplorationLogic();

        setupDeveloperWorkaroundsPost_();
    }
    function setupFullscreen(){
        setFullscreenState(FullscreenMode.BORDERLESS_FULLSCREEN);
    }

    function registerProfiles_(){
        mGameProfiles_ = determineGameProfiles();
    }
    //Split developer workarounds into two sections for tasks which need to be completed before base setup or after.
    function setupDeveloperWorkaroundsPre_(){
        if(mGameProfiles_ != null){
            foreach(i in mGameProfiles_){
                setupForProfilePre_(i);
            }
        }
    }
    function setupDeveloperWorkaroundsPost_(){
        if(mGameProfiles_ != null){
            foreach(i in mGameProfiles_){
                setupForProfilePost_(i);
            }
        }
        local forcedScreen = determineForcedScreen();
        if(forcedScreen == null && ::ScreenManager.getScreenForLayer() == null){
            //If nothing was setup then switch to the main menu.
            ::ScreenManager.transitionToScreen(Screen.MAIN_MENU_SCREEN);
        }
        if(forcedScreen != null){
            ::ScreenManager.transitionToScreen(getScreenDataForForcedScreen(forcedScreen));
        }
    }

    function getGameProfiles(){
        return mGameProfiles_;
    }
    function isProfileActive(profile){
        if(mGameProfiles_ != null){
            if(mGameProfiles_.find(profile) != null) return true;
        }
        return false;
    }

    function setupForProfilePre_(profile){
        printf("Setting up game profile pre setup '%s'", ::GameProfileString[profile]);
        switch(profile){
            case GameProfile.FORCE_MOBILE_INTERFACE:
                mTargetInterface_ = TargetInterface.MOBILE;
                break;
            case GameProfile.FORCE_SMALL_WORLD:
                mForceSmallWorld = true;
                break;
            default:
                break;
        }
    }

    function setupForProfilePost_(profile){
        printf("Setting up game profile post setup '%s'", ::GameProfileString[profile]);
        switch(profile){
            case GameProfile.DEVELOPMENT_BEGIN_EXPLORATION:
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": mExplorationLogic}));
                break;
            case GameProfile.TEST_SCREEN:
                ::ScreenManager.transitionToScreen(Screen.TEST_SCREEN);
                break;
            case GameProfile.DEBUG_OVERLAY_COMBAT:
                ::DebugOverlayManager.setupOverlay(DebugOverlayId.COMBAT);
                break;
            default:
                break;
        }
    }

    function shutdown(){
        ::PopupManager.shutdown();
        mPlayerStats.shutdown();
    }

    function update(){
        ::ScreenManager.update();
        ::PopupManager.update();
        ::EffectManager.update();
        ::DebugConsole.update();
    }

    function createLights(){
        //Create lighting upfront so all objects can share it.
        local light = _scene.createLight();
        local lightNode = _scene.getRootSceneNode().createChildSceneNode();
        lightNode.attachObject(light);

        light.setType(_LIGHT_DIRECTIONAL);
        light.setDirection(0, -1, -1);
        //light.setPowerScale(PI * 2);
        light.setPowerScale(PI);
        //light.setPowerScale(PI * 0.8);

        local val = 2.0;
        _scene.setAmbientLight(ColourValue(val, val, val, 1.0), ColourValue(val, val, val, 1.0), ::Vec3_UNIT_Y);
    }

    function setupBaseMeshes(){
        local voxMesh = VoxToMesh();

        local voxData = array(1, 188);

        voxMesh.createMeshForVoxelData("EXPOrbMesh", voxData, 1, 1, 1);
        voxData[0] = 216;
        voxMesh.createMeshForVoxelData("HealthOrbMesh", voxData, 1, 1, 1);
    }

    function setupBaseMaterials(){
        local datablock = _hlms.getDatablock("baseVoxelMaterial");
        datablock.setUserValue(0, 0.5, 0, 0, 0);
    }

    function setFullscreenState(fullscreen){
        mFullscreenMode_ = fullscreen;

        _window.setFullscreen(mFullscreenMode_ == FullscreenMode.BORDERLESS_FULLSCREEN ? _WINDOW_FULLSCREEN_BORDERLESS : _WINDOW_WINDOWED);

        /*
        if(mFullscreenMode_ == FullscreenMode.WINDOWED){
            local targetIdx = _window.getWindowDisplayIndex();
            local displaySize = _window.getDisplaySize(targetIdx);
            local position = _window.getDisplayPositionCoordinates(targetIdx);

            _window.setBorderless(false);
            _window.setSize(::canvasSize);
            _window.setPosition(displaySize / 2 - ::canvasSize / 2);
        }else if(mFullscreenMode_ == FullscreenMode.BORDERLESS_FULLSCREEN){
            local targetIdx = _window.getWindowDisplayIndex();
            local position = _window.getDisplayPositionCoordinates(targetIdx);
            local displaySize = _window.getDisplaySize(targetIdx);

            _window.setBorderless(true);
            _window.setSize(displaySize.x.tointeger(), displaySize.y.tointeger());
            _window.setPosition(position.x.tointeger(), position.y.tointeger());
        }
        */
    }

};
