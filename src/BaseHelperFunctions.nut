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
    function getStartingScreen(){
        return Screen.MAIN_MENU_SCREEN;
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
            case GameProfile.DEBUG_OVERLAY_INPUT:
                ::DebugOverlayManager.setupOverlay(DebugOverlayId.INPUT);
                break;
            default:
                break;
        }
    }

};