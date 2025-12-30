//TODO temporary
::currentNativeMapData <- null;

::Base <- {
    mExplorationLogic = null

    mBaseImpls_ = []

    mPlayerStats = null
    mDialogManager = null
    mQuestManager = null
    mInputManager = null
    mSaveManager = null
    mGameProfiles_ = null
    mActionManager = null
    mSystemSettings = null
    mLottieManager = null
    mIconButtonComplexAnimationManager = null
    mArtifactCollection = null

    mGlobalDirectionLight = null

    mTargetInterface_ = TargetInterface.DESKTOP
    mFullscreenMode_ = FullscreenMode.WINDOWED
    mForceSmallWorld = false

    function checkUserParams(){
        //TODO work around the fact that I can't use multiple avSetup files to override this yet.
        local platform = _settings.getPlatform();
        if(platform == _PLATFORM_IOS || platform == _PLATFORM_ANDROID){
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
    function determineForcedMap(){
        local forceMap = _settings.getUserSetting("forceMap");
        if(forceMap == null || typeof forceMap != "string") return null;
        return forceMap;
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

    function registerBaseImpl(impl){
        mBaseImpls_.append(impl);
    }
    function registerBasicBaseImp(impl){
        //Ensure it has priority and is registered first.
        mBaseImpls_.insert(0, impl);
    }

    function setupSecondary(){
        foreach(i in mBaseImpls_){
            i.setupSecondary()
        }
    }

    function setupFirst(){
        foreach(i in mBaseImpls_){
            i.setupFirst()
        }
    }

    function loadFiles(){
        _doFile("res://src/Util/VersionPool.nut");

        _doFile("res://src/System/CompositorManager.nut");
        ::CompositorManager.setup();

        _doFile("res://src/System/EnumDef.nut");
        _doFile("res://src/System/InputManager.nut");
        _doFile("res://src/Util/IdPool.nut");

        _doFile("res://src/System/LottieAnimationManager.nut");
        mLottieManager = ::LottieAnimationManager();

        _doFile("res://src/Logic/Util/PercentageEncounterHelper.nut");
        _doFile("res://src/Logic/Util/SpoilsData.nut");
        _doFile("res://src/Logic/Entity/EntityManager.nut");
        _doFile("res://src/Logic/Entity/EntityComponent.nut");

        _doFile("res://src/Content/Projectiles.nut");
        _doFile("res://src/Content/Equippables.nut");
        _doFile("res://src/Content/Enemies.nut");
        _doFile("res://src/Content/Items.nut");
        _doFile("res://src/Content/PlacedItem.nut");
        _doFile("res://src/Content/StatusAffliction.nut");
        _doFile("res://src/Content/Places.nut");
        _doFile("res://src/Content/FoundObject.nut");
        _doFile("res://src/Content/CombatData.nut");
        _doFile("res://src/Content/StatsEntry.nut");

        defineBaseEnums();
        loadEnumFiles();
        ::EnumDef.commitEnums();
        _doFile("res://src/System/PlayerStats.nut");
        loadContentFiles();

        _doFile("res://src/Content/Moves.nut");

        //TODO shift this off somewhere else.
        _doFile("res://src/Content/Enemies/BasicEnemyScript.nut");
        _doFile("res://src/Content/Enemies/BeeHiveScript.nut");
        _doFile("res://src/Content/Enemies/BeeEnemyScript.nut");
        _doFile("res://src/Content/Encounters/MessageInABottleScript.nut");
        _doFile("res://src/Content/GenericCallbacks.nut");

        _doFile("res://src/DebugOverlayManager.nut");
        _doFile("res://src/DebugConsole.nut");
        _doFile("res://src/Content/DebugCommands.nut");

        _doFile("res://src/Character/CharacterModelAnimations.nut");
        _doFile("res://src/Character/CharacterModel.nut");
        _doFile("res://src/Character/CharacterGenerator.nut");
        _doFile("res://src/Character/CharacterModelTypes.nut");

        _doFile("res://src/System/DatablockManager.nut");

        _doFile("res://src/System/Dialog/DialogManager.nut");
        _doFile("res://src/System/Dialog/DialogMetaScanner.nut");
        mDialogManager = DialogManager();

        _doFile("res://src/System/Quest/QuestManager.nut");
        _doFile("res://src/System/Quest/Quest.nut");
        mQuestManager = QuestManager();

        _doFile("res://src/System/Inventory.nut");

        mPlayerStats = ::PlayerStats();

        _doFile("res://src/System/ArtifactCollection.nut");
        mArtifactCollection = ::ArtifactCollection();

        _doFile("res://src/System/MultiTouchManager.nut");
        ::MultiTouchManager.setup();

        _doFile("res://src/System/Save/SaveConstants.nut");
        _doFile("res://src/System/Save/Parsers/SaveFileParser.nut");
        _doFile("res://src/System/Save/SaveManager.nut");
        mSaveManager = ::SaveManager();

        _doFile("res://src/System/ActionManager.nut");
        mActionManager = ::ActionManager();
        mActionManager.setup();

        _doFile("res://src/System/HapticManager.nut");
        ::HapticManager.initialise();

        _doFile("res://src/System/FindableDistributor.nut");

        _doFile("res://src/MapGen/Exploration/Generator/Biomes.nut");
        _doFile("res://src/MapGen/MapViewer.nut");
        _doFile("res://src/MapGen/VisitedLocationMapViewer.nut");
        _doFile("res://src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut");
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
        _doFile("res://src/GUI/Widgets/IconButton.nut");
        mIconButtonComplexAnimationManager = ::IconButtonComplexAnimationManager();
        _doFile("res://src/GUI/Widgets/TwoBarProgressBar.nut");
        _doFile("res://src/GUI/Widgets/GameplayProgressBar.nut");
        _doFile("res://src/GUI/Widgets/ExplorationDiscoverLevelBarWidget.nut");
        _doFile("res://src/GUI/Widgets/PlayerBasicStatsWidget.nut");
        _doFile("res://src/GUI/Widgets/GameplayInventoryWidget.nut");
        _doFile("res://src/GUI/Widgets/FoundItemWidget.nut");
        _doFile("res://src/GUI/Widgets/PlayerDirectJoystick.nut");

        _doFile("res://src/System/SystemSettings.nut");

        _doFile("res://src/GUI/Billboard/BillboardManager.nut");

        _doFile("res://src/GUI/PopupManager.nut");
        _doFile("res://src/GUI/Popups/Popup.nut");
        _doFile("res://src/GUI/Popups/BottomOfScreenPopup.nut");
        _doFile("res://src/GUI/Popups/TopRightOfScreenPopup.nut");
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
        _doFile("res://src/GUI/Effects/BottleEffect.nut");
        ::EffectManager.setup();

        _doFile("res://src/GUI/ScreenManager.nut");
        _doFile("res://src/GUI/VersionInfoWindow.nut");
        ::ScreenManager.setup();
        _doFile("res://src/GUI/Screens/Screen.nut");

        _doFile("res://src/Logic/EntityTargetManager.nut");
        _doFile("res://src/Logic/ActiveEnemyEntry.nut");
        _doFile("res://src/Logic/World/TileGridPlacer.nut");
        _doFile("res://src/Logic/World/TerrainChunkManager.nut");
        _doFile("res://src/Logic/World/World.nut");
        _doFile("res://src/Logic/World/VisitedLocationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorld.nut");
        _doFile("res://src/Logic/World/PlayerDeathWorld.nut");
        _doFile("res://src/Logic/World/TestingWorld.nut");
        _doFile("res://src/Logic/Overworld/Overworld.nut");
        _doFile("res://src/Logic/World/WorldPreparer.nut");
        _doFile("res://src/Logic/World/PlacePlacer.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorldPreparer.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorldPreparer.nut");
        _doFile("res://src/Logic/World/VisitedLocationWorldPreparer.nut");
        _doFile("res://src/Logic/Overworld/OverworldPreparer.nut");
        _doFile("res://src/Logic/ExplorationEffectsManager.nut");
        _doFile("res://src/Logic/ExplorationLogic.nut");
        _doFile("res://src/Logic/ExplorationProjectileManager.nut");

        _doFile("res://src/Logic/Overworld/OverworldLogic.nut");

        _doFile("res://src/Logic/World/Actions/WorldAction.nut");
        _doFile("res://src/Logic/World/Actions/EXPTrailAction.nut");
        _doFile("res://src/Logic/World/Actions/ObjectDropAction.nut");
        _doFile("res://src/Logic/World/Actions/CometAction.nut");

        _doFile("res://src/GUI/RenderIconManager.nut");
        ::RenderIconManager.setup();

        ::ItemHelper.setupItemIds_();

        _doFile("res://src/BaseHelperFunctions.nut")

        loadFilesEnd();
    }

    function defineBaseEnums(){
        ::EnumDef.addToEnum("Screen", @"
            SCREEN,
        ");
        ::EnumDef.addToString("ScreenString", [
            "screen"
        ]);
    }

    function loadEnumFiles(){
        //The enums and defs need to be registered separately so the def can use the enum.
        foreach(i in mBaseImpls_){
            i.loadEnumFiles();
        }
    }

    function loadContentFiles(){
        foreach(i in mBaseImpls_){
            i.loadContentFiles();
        }
    }

    function loadFilesEnd(){
        foreach(i in mBaseImpls_){
            i.loadFilesEnd();
        }
    }

    function setup(){
        checkForGameCorePlugin();
        _system.ensureUserDirectory();

        printVersionInfos();
        checkUserParams();
        registerProfiles_();
        setupDeveloperWorkaroundsPre_();

        _doFile("res://src/Content/BaseBasic.nut");
        registerBasicBaseImp(::BaseBasic());
        foreach(i in mBaseImpls_){
            i.setup();
        }

        /*
        if(!(::Base.isProfileActive(GameProfile.FORCE_WINDOWED))){
            setupFullscreen();
        }
        */

        //TODO move this somewhere else.
        _animation.loadAnimationFile("res://build/assets/animation/baseAnimation.xml");
        _animation.loadAnimationFile("res://build/assets/characterAnimations/equippableAnimation.xml");

        createLights();

        _gui.loadSkins("res://build/assets/skins/ui.json");
        _gui.loadSkins("res://build/assets/skins/itemSkins.json");

        applyCompositorModifications();

        loadFiles();

        setupBaseMaterials();
        setupBaseMeshes();
        _gameCore.setMapsDirectory(::BaseHelperFunctions.getMapsDir());

        ::InputManager.setup();

        mExplorationLogic = ExplorationLogic();

        _gameCore.registerMapGenClient("testClient", "res://src/MapGen/NativeClient/MapGenNativeClient.nut", {"basePath": "res://"});
        _gameCore.recollectMapGenSteps();

        setupDeveloperWorkaroundsPost_();
    }
    function setupFullscreen(){
        setFullscreenState(FullscreenMode.BORDERLESS_FULLSCREEN);
    }

    function applyCompositorModifications(){
        _gameCore.setCameraForNode("renderMainGameplayNode", "explorationCamera");
        local mobile = (getTargetInterface() == TargetInterface.MOBILE);
        local size = _window.getActualSize();
        if(mobile){
            _gameCore.disableShadows();
            size /= 2;
        }
        _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
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
                ::BaseHelperFunctions.setupForProfilePost_(i);
            }
        }
    }

    function switchToFirstScreen(){
        local forcedScreen = determineForcedScreen();
        if(forcedScreen == null && ::ScreenManager.getScreenForLayer() == null){
            //If nothing was setup then switch to the main menu.
            if(getTargetInterface() == TargetInterface.MOBILE){
                if(!isProfileActive(GameProfile.DISABLE_SPLASH_SCREEN)){
                    ::ScreenManager.transitionToScreen(::BaseHelperFunctions.getSplashScreen(), null, 3);
                }
            }
            local screenData = ::BaseHelperFunctions.getScreenDataForForcedScreen(::BaseHelperFunctions.getStartingScreen());
            if(screenData.data != null){
                screenData.data.createTitleScreen = true;
            }
            ::ScreenManager.transitionToScreen(screenData, null, 0);
        }
        if(forcedScreen != null){
            ::ScreenManager.transitionToScreen(::BaseHelperFunctions.getScreenDataForForcedScreen(forcedScreen));
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

    function shutdown(){
        ::PopupManager.shutdown();
        mPlayerStats.shutdown();
        mActionManager.shutdown();
        ::MultiTouchManager.shutdown();
        mExplorationLogic.shutdown();
        ::ScreenManager.shutdown();
        ::EffectManager.shutdown();

        ::expOrbMesh = null;
    }

    function update(){
        ::ScreenManager.update();
        ::PopupManager.update();
        ::EffectManager.update();
        ::DebugConsole.update();
        mLottieManager.update();
        mIconButtonComplexAnimationManager.update();
    }

    function createLights(){
        //Create lighting upfront so all objects can share it.
        local light = _scene.createLight();
        local lightNode = _scene.getRootSceneNode().createChildSceneNode();
        lightNode.attachObject(light);

        mGlobalDirectionLight = light;

        light.setType(_LIGHT_DIRECTIONAL);
        light.setDirection(0, -1, -1);
        //light.setPowerScale(PI * 2);
        light.setPowerScale(PI);
        //light.setPowerScale(PI * 0.8);

        local val = 2.0;
        _scene.setAmbientLight(ColourValue(val, val, val, 1.0), ColourValue(val, val, val, 1.0), ::Vec3_UNIT_Y);
    }

    function setupBaseMeshes(){
        local voxData = array(1, 205);

        ::expOrbMesh <- _gameCore.voxeliseMeshForVoxelData("EXPOrbMesh", voxData, 1, 1, 1);
        voxData[0] = 200;
        _gameCore.voxeliseMeshForVoxelData("HealthOrbMesh", voxData, 1, 1, 1);
    }

    function setupBaseMaterials(){
        local datablock = _hlms.getDatablock("baseVoxelMaterial");
        //datablock.setUserValue(0, 0.5, 0, 0, 0);
        forceTextureMaterialLoad(datablock);
    }

    function forceTextureMaterialLoad(datablock){
        local c = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        c.setDatablock(datablock);
        local tempNode = _scene.getRootSceneNode().createChildSceneNode();
        tempNode.attachObject(c);
        _graphics.waitForStreamingCompletion();
        tempNode.destroyNodeAndChildren();
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

    function checkForGameCorePlugin(){
        if(!getroottable().rawin("_gameCore")){
            //The gamecore namespace was not found, so assume the plugin was not loaded correctly.
            throw "gamecore namespace not found.";
        }

        //With the plugin loaded, check the version. There is potential for version mismatch in dynamic loaded plugins.
        local nativeVersion = _gameCore.getGameCoreVersion();
        if(
            GAME_VERSION_MAJOR != nativeVersion.major ||
            GAME_VERSION_MINOR != nativeVersion.minor ||
            GAME_VERSION_PATCH != nativeVersion.patch
        )
        {
            throw "Version mismatch in native plugin.";
        }
        //Extra check to ensure a debug and release plugin was loaded.
        local engineVersion = _settings.getEngineVersion();
        if(nativeVersion.build != engineVersion.build){
            throw format("Mismatch in engine and plugin build type. Plugin is '%s' engine is '%s'", nativeVersion.build, engineVersion.build);
        }
    }

};
