::ScreenManager <- {

    "MAX_SCREENS": 3,
    "mActiveScreens_": null,
    "mPreviousScreens_": null,

    "mScreenQueued_": false,
    "mQueuedScreens_": null,

    function setup(){
        mActiveScreens_ = array(MAX_SCREENS, null);
        mPreviousScreens_ = array(MAX_SCREENS, null);
        mQueuedScreens_ = array(MAX_SCREENS, null);
    }

    function _createScreenForId(screenId){
        switch(screenId){
            case Screen.SCREEN: return ::Screen();
            case Screen.MAIN_MENU_SCREEN: return ::MainMenuScreen();
            case Screen.SAVE_SELECTION_SCREEN: return ::SaveSelectionScreen();
            case Screen.GAMEPLAY_MAIN_MENU_SCREEN: return ::GameplayMainMenuScreen();
            case Screen.EXPLORATION_SCREEN: return ::ExplorationScreen(::Base.mExplorationLogic);
            case Screen.ENCOUNTER_POPUP_SCREEN: return ::EncounterPopupScreen();
            case Screen.COMBAT_SCREEN: return ::CombatScreen(::Base.mCombatLogic);
            //TODO this will need to be populated with the item idx, otherwise it will assert.
            case Screen.ITEM_INFO_SCREEN: return ::ItemInfoScreen(Item.SIMPLE_SHIELD, ItemInfoMode.USE);
            case Screen.INVENTORY_SCREEN: return ::InventoryScreen(::Base.mInventory);
            case Screen.VISITED_PLACES_SCREEN: return ::VisitedPlacesScreen(::Base.mPlayerStats);
            case Screen.PLACE_INFO_SCREEN: return ::PlaceInfoScreen(Place.HAUNTED_WELL);
            case Screen.STORY_CONTENT_SCREEN: return ::StoryContentScreen(::StoryContentLogic(Place.GOBLIN_VILLAGE));
            case Screen.DIALOG_SCREEN: return ::DialogScreen();
            default:{
                assert(false);
            }
        }
    }

    /**
     * Immediate transition to a new screen.
     */
    //TODO now I have the enums for screen construction consider removing this.
    function transitionToScreen(screenObject, transitionEffect = null, layerId = 0){
        assert(layerId < MAX_SCREENS);
        local current = mActiveScreens_[layerId];
        if(current != null){
            print("Calling shutdown for layer " + layerId);
            current.shutdown();
            mPreviousScreens_[layerId] = current
        }
        mActiveScreens_[layerId] = screenObject;

        if(!screenObject) return;

        print("Setting up screen for layer " + layerId);
        mActiveScreens_[layerId].setup();
    }

    function transitionToScreenForId(screenId, transitionEffect = null, layerId = 0){
        local screen = _createScreenForId(screenId);
        transitionToScreen(screen, transitionEffect, layerId);
    }

    /**
     * Queue the transition of the window to the start of the next frame.
     * This can help to ease issues if the transition happens deep in a callback stack.
     * i.e so the gui isn't deleted as part of its callback in an inconvenient way.
     */
    function queueTransition(screenObject, transitionEffect = null, layerId = 0){
        mQueuedScreens_[layerId] = screenObject;
        mScreenQueued_ = true;
    }

    /**
     * Head back to the previous screen, stored in memory.
     */
    function backupScreen(layerId){
        local prev = mPreviousScreens_[layerId];
        if(prev == null) return;
        transitionToScreen(prev, null, layerId);
    }

    function update(){
        if(mScreenQueued_){
            for(local i = 0; i < MAX_SCREENS; i++){
                local screen = mQueuedScreens_[i];
                if(!screen) continue;
                transitionToScreen(screen, null, i);
                mQueuedScreens_[i] = null;
            }
            mScreenQueued_ = false;
        }

        foreach(i in mActiveScreens_){
            if(i != null) i.update();
        }
    }
};

::ScreenManager.setup();