::Base <- {
    "mExplorationLogic": null,
    "mCombatLogic": null,

    //TODO this will be created on encounter in the future.
    "mCurrentCombatData": null,

    "mInventory": null,
    "mPlayerStats": null,
    "mDialogManager": null,
    mInputManager = null

    mTargetInterface_ = TargetInterface.DESKTOP

    function checkUserParams(){
        //TODO work around the fact that I can't use multiple avSetup files to override this yet.
        if(_settings.getPlatform() == _PLATFORM_IOS){
            mTargetInterface_ = TargetInterface.MOBILE;
        }
    }
    function getTargetInterface(){
        return mTargetInterface_;
    }

    function setup(){
        printVersionInfos();
        checkUserParams();

        //TODO move this somewhere else.
        _animation.loadAnimationFile("res://build/assets/animation/baseAnimation.xml");
        _animation.loadAnimationFile("res://assets/characterAnimations/equippableAnimation.xml");

        createLights();

        _gui.loadSkins("res://assets/skins/ui.json");

        _doFile("res://src/Helpers.nut");
        _doFile("res://src/System/InputManager.nut");
        _doFile("res://src/Util/VoxToMesh.nut");
        _doFile("res://src/Util/IdPool.nut");
        _doFile("res://src/Logic/Util/PercentageEncounterHelper.nut");
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

        _doFile("res://src/Character/CharacterModelAnimations.nut");
        _doFile("res://src/Character/CharacterModel.nut");
        _doFile("res://src/Character/CharacterGenerator.nut");
        _doFile("res://src/Character/CharacterModelTypes.nut");

        _doFile("res://src/System/DatablockManager.nut");

        _doFile("res://src/System/DialogManager.nut");
        mDialogManager = DialogManager();

        _doFile("res://src/System/Inventory.nut");
        mInventory = ::Inventory();

        _doFile("res://src/System/PlayerStats.nut");
        mPlayerStats = ::PlayerStats();

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
        _doFile("res://src/GUI/Screens/SaveSelectionScreen.nut");
        _doFile("res://src/GUI/Screens/GameplayMainMenuScreen.nut");
        _doFile("res://src/GUI/Screens/Exploration/ExplorationScreen.nut");
        _doFile("res://src/GUI/Screens/EncounterPopupScreen.nut");
        _doFile("res://src/GUI/Screens/Combat/CombatScreen.nut");
        _doFile("res://src/GUI/Screens/ItemInfoScreen.nut");
        _doFile("res://src/GUI/Screens/InventoryScreen.nut");
        _doFile("res://src/GUI/Screens/VisitedPlacesScreen.nut");
        _doFile("res://src/GUI/Screens/PlaceInfoScreen.nut");
        _doFile("res://src/GUI/Screens/StoryContentScreen.nut");
        _doFile("res://src/GUI/Screens/DialogScreen.nut");
        _doFile("res://src/GUI/Screens/CombatSpoilsPopupScreen.nut");
        _doFile("res://src/GUI/Screens/TestScreen.nut");
        _doFile("res://src/GUI/Screens/ExplorationTestScreen.nut");
        _doFile("res://src/GUI/Screens/WorldGenerationStatusScreen.nut");

        _doFile("res://src/Logic/EntityTargetManager.nut");
        _doFile("res://src/Logic/ActiveEnemyEntry.nut");
        _doFile("res://src/Logic/World/TerrainChunkManager.nut");
        _doFile("res://src/Logic/World/TerrainChunkFileHandler.nut");
        _doFile("res://src/Logic/World/World.nut");
        _doFile("res://src/Logic/World/VisitedLocationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorld.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorld.nut");
        _doFile("res://src/Logic/World/WorldPreparer.nut");
        _doFile("res://src/Logic/World/ProceduralExplorationWorldPreparer.nut");
        _doFile("res://src/Logic/World/ProceduralDungeonWorldPreparer.nut");
        _doFile("res://src/Logic/ExplorationLogic.nut");
        _doFile("res://src/Logic/ExplorationProjectileManager.nut");
        _doFile("res://src/Logic/CombatLogic.nut");
        _doFile("res://src/Logic/Scene/CombatSceneLogic.nut");
        _doFile("res://src/Logic/StoryContentLogic.nut");

        _doFile("res://src/Logic/World/Actions/WorldAction.nut");
        _doFile("res://src/Logic/World/Actions/EXPTrailAction.nut");

        _doFile("res://src/GUI/RenderIconManager.nut");
        ::RenderIconManager.setup();

        setupBaseMaterials();
        setupBaseMeshes();

        ::InputManager.setup();

        mExplorationLogic = ExplorationLogic();
        /*
        local enemyData = [
            ::Combat.CombatStats(EnemyId.GOBLIN, 20),
            ::Combat.CombatStats(EnemyId.GOBLIN)
        ];
        mCurrentCombatData = ::Combat.CombatData(mPlayerStats.mPlayerCombatStats, enemyData);
        */
        //TODO temporary to setup the logic. Really a new combatData would be pushed at the start of a new combat.
        //mCombatLogic = CombatLogic(mCurrentCombatData);

        //::ScreenManager.transitionToScreen(Screen.MAIN_MENU_SCREEN);
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": mExplorationLogic}));
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.COMBAT_SCREEN, {"logic": mCombatLogic}));
        //::ScreenManager.transitionToScreen(Screen.TEST_SCREEN);
        //::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_TEST_SCREEN, {"logic": mExplorationLogic}));
        //::ScreenManager.transitionToScreen(Screen.WORLD_SCENE_SCREEN);
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ENCOUNTER_POPUP_SCREEN, null), null, 1);
        //::ScreenManager.transitionToScreen(Screen.ITEM_INFO_SCREEN);
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, {"inventory": mInventory, "equipStats": ::Base.mPlayerStats.mPlayerCombatStats.mEquippedItems}));
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.VISITED_PLACES_SCREEN, {"stats": mPlayerStats}));
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, {"logic": ::StoryContentLogic(PlaceId.HAUNTED_WELL)}));
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.STORY_CONTENT_SCREEN, {"logic": ::StoryContentLogic(PlaceId.HAUNTED_WELL)}));
        //::ScreenManager.transitionToScreen(Screen.STORY_CONTENT_SCREEN);
        //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_END_SCREEN, {"totalFoundItems": 5, "totalDiscoveredPlaces": 4, "totalEncountered": 2, "totalDefeated": 1}), null, 1);

        //mExplorationLogic.resetExploration_();
    }

    function update(){
        ::ScreenManager.update();
        ::PopupManager.update();
        ::EffectManager.update();
    }

    function notifyEncounter(combatData){
        mCurrentCombatData = combatData;
        mCombatLogic = ::CombatLogic(combatData);
    }

    function notifyEncounterEnded(){
        mCombatLogic.shutdown();
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
        _scene.setAmbientLight(ColourValue(val, val, val, 1.0), ColourValue(val, val, val, 1.0), Vec3(0, 1, 0));
    }

    function setupBaseMeshes(){
        local voxMesh = VoxToMesh();

        local voxData = array(1, 188);

        local meshObj = voxMesh.createMeshForVoxelData("EXPOrbMesh", voxData, 1, 1, 1);
    }

    function setupBaseMaterials(){
        local datablock = _hlms.getDatablock("baseVoxelMaterial");
        datablock.setUserValue(0, 0.5, 0, 0, 0);
    }

    function determineGitHash(){
        if(getconsttable().rawin("GIT_HASH")){
            return getconsttable().rawget("GIT_HASH");
        }

        //Otherwise try and read it from the git directory.
        local directory = _settings.getDataDirectory();
        local path = directory + "/.git/refs/heads/master";
        if(_system.exists(path)){
            local f = File();
            f.open(path);
            local hash = f.getLine();
            return hash.slice(0, 8);
        }

        return null;
    }
    function getVersionInfo(){
        local hash = determineGitHash();
        local suffix = VERSION_SUFFIX;
        if(hash != null){
            suffix += ("-" + hash);
        }

        local versionTotal = format("%i.%i.%i-%s", VERSION_MAX, VERSION_MIN, VERSION_PATCH, suffix);
        local engine = _settings.getEngineVersion();
        local engineVersionTotal = format("Engine: %i.%i.%i-%s", engine.major, engine.minor, engine.patch, engine.suffix);

        return {
            "info": versionTotal,
            "engineInfo": engineVersionTotal
        };
    }

    function printVersionInfos(){
        local infos = getVersionInfo();
        local strings = [];
        strings.append(GAME_TITLE.toupper());
        strings.append(infos.info);
        strings.append(infos.engineInfo);

        local max = 0;
        foreach(i in strings){
            local len = i.len();
            if(len > max){
                max = len;
            }
        }

        local decorator = "";
        local padding = "** ";
        local paddingRight = " **";
        local maxExtent = max + (padding.len() * 2);
        for(local i = 0; i < maxExtent; i++){
            decorator += "*";
        }

        print(decorator);
        foreach(i in strings){
            local starting = padding + i;
            local remainder = maxExtent - starting.len() - padding.len();
            local spaces = "";
            for(local i = 0; i < remainder; i++){
                spaces += " ";
            }
            print(starting + spaces + paddingRight);
        }
        print(decorator);
    }

};
