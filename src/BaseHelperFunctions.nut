/*
Simple helper functions which can be altered to change how the game works.
Separated from the Base.nut file so enums can be used.
*/

::BaseHelperFunctions <- {
    function getDefaultWorld(){
        return WorldTypes.PROCEDURAL_EXPLORATION_WORLD;
    }
    function getDefaultMapName(){
        return "testVillage";
    }
    function getMapsDir(){
        return "res://build/assets/maps/";
    }
    function getOverworldDir(){
        return "res://build/assets/overworld/";
    }
    function getTargetMainMenu(){
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            return Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN;
        }else{
            return Screen.MAIN_MENU_SCREEN;
        }
    }
    function getTargetGameplayMainMenu(){
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            return Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN;
        }else{
            return Screen.GAMEPLAY_MAIN_MENU_SCREEN;
        }
    }
    function getSplashScreen(){
        return Screen.OTHER_MYTHOS_SPLASH_SCREEN;
    }
    function getStartingScreen(){
        return getTargetMainMenu();
    }
    function getScreenDataForForcedScreen(screenId){
        local data = null;
        if(screenId == Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN){
            data = {"createTitleScreen": false};
        }
        else if(screenId == Screen.INVENTORY_SCREEN){
            //data = {"stats": ::Base.mPlayerStats}
            data = {
                "stats": ::Base.mPlayerStats,
                //"width": 2,
                //"height": 2,
                //"items": [::Item(ItemId.APPLE), null, null, null],
                "multiSelection": true
            }
        }
        else if(screenId == Screen.EXPLORATION_SCREEN){
            data = {"logic": ::Base.mExplorationLogic}
        }
        else if(screenId == Screen.VISITED_PLACES_SCREEN){
            data = {"stats": ::Base.mPlayerStats}
        }
        else if(screenId == Screen.FOUND_ORB_SCREEN){
            data = {"orbId": OrbId.IN_THE_CHERRY_BLOSSOM};
        }
        else if(screenId == Screen.BANK_DEPOSIT_WITHDRAW_SCREEN){
            data = {"deposit": true};
        }
        return ::ScreenManager.ScreenData(screenId, data);
    }
    function setupForProfilePost_(profile){
        printf("Setting up game profile post setup '%s'", ::GameProfileString[profile]);
        switch(profile){
            case GameProfile.DEVELOPMENT_BEGIN_EXPLORATION:{
                local save = ::Base.mSaveManager.produceSave();
                ::Base.mPlayerStats.setSaveData(save, 0);

                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
                break;
            }
            case GameProfile.TEST_SCREEN:
                ::ScreenManager.transitionToScreen(Screen.TEST_SCREEN);
                break;
            case GameProfile.DEBUG_OVERLAY_COMBAT:
                ::DebugOverlayManager.setupOverlay(DebugOverlayId.COMBAT);
                break;
            case GameProfile.DEBUG_OVERLAY_INPUT:
                ::DebugOverlayManager.setupOverlay(DebugOverlayId.INPUT);
                break;
            default:
                break;
        }
    }

};