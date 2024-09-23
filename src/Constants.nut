::ConstHelper <- {};

const TRIGGER = 0;
const DAMAGE = 1;

const PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4;
const VISITED_WORLD_UNIT_MULTIPLIER = 0.4;

const EFFECT_WINDOW_CAMERA_Z = 100;

const SCREENS_START_Z = 40;
const POPUPS_START_Z = 60;

const MAX_PLAYER_NAME_LENGTH = 30;

const INVALID_REGION_ID = 0xFF;
const INVALID_LAND_ID = 0xFF;
const INVALID_WATER_ID = 0xFF;
const INVALID_WORLD_POINT = 0xFFFFFFFF;

const ACTION_MANAGER_NUM_SLOTS = 2;

enum FullscreenMode{
    WINDOWED,
    BORDERLESS_FULLSCREEN
};

enum TargetInterface{
    MOBILE,
    DESKTOP,

    MAX
};

enum DebugOverlayId{
    COMBAT,
    INPUT
};

enum InputActionSets{
    EXPLORATION,
    MENU,
    DEBUG_CONSOLE,

    MAX

};

enum Component{
    HEALTH = 0,
    MISC = 1
}

enum WorldTypes{
    WORLD,
    PROCEDURAL_EXPLORATION_WORLD,
    PROCEDURAL_DUNGEON_WORLD,
    VISITED_LOCATION_WORLD,
    TESTING_WORLD
};
::WorldTypeStrings <- [
    "World",
    "ProceduralExplorationWorld",
    "ProceduralDungeonWorld",
    "VisitedLocationWorld",
    "TestingWorld",
];

enum ObjectType{
    SCREEN_DATA = "ScreenData",
    POPUP_DATA = "PopupData",
    EFFECT_DATA = "EffectData",
};

enum StatType{
    RESTORATIVE_HEALTH,
    ATTACK,
    DEFENSE,

    MAX
};

enum InventoryGridType{
    INVENTORY_GRID,
    INVENTORY_EQUIPPABLES
};

//Profiles define how the game should operate,
//for instance if developing, profiles might help setup a development environment
enum GameProfile{
    RELEASE,
    DEVELOPMENT_BEGIN_EXPLORATION,
    TEST_SCREEN,
    DISPLAY_WORLD_STATS,
    FORCE_MOBILE_INTERFACE,
    SCREENSHOT_MODE,
    DISABLE_ENEMY_SPAWN,
    DISABLE_DISTRACTION_SPAWN,
    ENABLE_RIGHT_CLICK_WORKAROUNDS,
    FORCE_WINDOWED,
    DEBUG_OVERLAY_COMBAT,
    DEBUG_OVERLAY_INPUT,
    FORCE_SMALL_WORLD,
    PLAYER_GHOST,

    MAX
};
::GameProfileString <- [
    "Release",
    "DevelopmentBeginExploration",
    "TestScreen",
    "DisplayWorldStats",
    "ForceMobileInterface",
    "ScreenshotMode",
    "DisableEnemySpawn",
    "DisableDistractionSpawn",
    "EnableRightClickWorkarounds",
    "ForceWindowed",
    "DebugOverlayCombat",
    "DebugOverlayInput",
    "ForceSmallWorld",
    "PlayerGhost"
];

enum Event{
    INVENTORY_CONTENTS_CHANGED = 1001,
    MONEY_CHANGED = 1002,
    PLACE_VISITED = 1003,

    DIALOG_SPOKEN = 1004,
    DIALOG_META = 1005,

    PLAYER_DIED = 1007,

    MONEY_ADDED = 1009,
    EXP_ORBS_ADDED = 1010
    SCREEN_CHANGED = 1011,

    PLAYER_HEALTH_CHANGED = 1012,
    PLAYER_TARGET_CHANGE = 1013,

    CURRENT_WORLD_CHANGE = 1014,
    ACTIVE_WORLD_CHANGE = 1015,

    WORLD_PREPARATION_GENERATION_PROGRESS = 1016,
    WORLD_PREPARATION_STATE_CHANGE = 1017,

    PLACE_DISCOVERED = 1018,
    PLAYER_EQUIP_CHANGED = 1019,
    PLAYER_WIELD_ACTIVE_CHANGED = 1020,

    ACTIONS_CHANGED = 1021,

}

enum FoundObjectType{
    NONE,
    ITEM,
    PLACE
};

enum ItemInfoMode{
    KEEP_SCRAP_EXPLORATION,
    USE,
    KEEP_SCRAP_SPOILS,
};

enum Screen{
    SCREEN,
    MAIN_MENU_SCREEN,
    HELP_SCREEN,
    SAVE_SELECTION_SCREEN,
    GAMEPLAY_MAIN_MENU_SCREEN,
    EXPLORATION_SCREEN,
    ITEM_INFO_SCREEN,
    INVENTORY_SCREEN,
    VISITED_PLACES_SCREEN,
    DIALOG_SCREEN,
    TEST_SCREEN,
    SAVE_EDIT_SCREEN,
    EXPLORATION_END_SCREEN,
    PLAYER_DEATH_SCREEN,
    WORLD_GENERATION_STATUS_SCREEN,
    NEW_SAVE_VALUES_SCREEN,
    INVENTORY_ITEM_HELPER_SCREEN,
    PAUSE_SCREEN,

    MAX
};
::ScreenString <- [
    "screen",
    "mainMenuScreen",
    "helpScreen",
    "saveSelectionScreen",
    "gamePlayMainMenuScreen",
    "explorationScreen",
    "itemInfoScreen",
    "inventoryScreen",
    "visitedPlacesScreen",
    "dialogScreen",
    "testScreen",
    "saveEditScreen",
    "explorationEndScreen",
    "playerDeathScreen",
    "worldGenerationStatusScreen",
    "newSaveValuesScreen",
    "inventoryItemHelperScreen",
    "pauseScreen"
];

enum Popup{
    POPUP,
    BOTTOM_OF_SCREEN,
    REGION_DISCOVERED,
    SINGLE_TEXT,

    MAX
};

enum Effect{
    EFFECT,
    SPREAD_COIN_EFFECT,
    LINEAR_COIN_EFFECT,
    LINEAR_EXP_ORB_EFFECT,
    FOUND_ITEM_EFFECT,
    FOUND_ITEM_IDLE_EFFECT,

    MAX
};

enum EquippedSlotTypes{
    NONE,
    HEAD,
    BODY,
    LEFT_HAND,
    RIGHT_HAND,
    LEGS,
    FEET,
    ACCESSORY_1,
    ACCESSORY_2,

    MAX,
    HAND
};

enum CombatOpponentAnims{
    NONE,

    HOPPING,
    DYING
};

enum ExplorationGizmos{
    TARGET_ENEMY,

    MAX
};

enum WorldDistractionType{
    PERCENTAGE_ENCOUNTER,
    HEALTH_ORB,
    EXP_ORB
};

enum ActionSlotType{
    NONE,
    TALK_TO,
};

::ActionSlotTypeString <- [
    "None",
    "Talk",
];

//Characters --------
enum CharacterModelType{
    NONE,
    HUMANOID,
    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,
    FOREST_GUARDIAN,

    MAX
};
::ConstHelper.CharacterModelTypeToString <- function(e){
    switch(e){
        case CharacterModelType.NONE: return "None";
        case CharacterModelType.HUMANOID: return "Humanoid";
        case CharacterModelType.GOBLIN: return "Goblin";
        case CharacterModelType.SQUID: return "Squid";
        case CharacterModelType.CRAB: return "Crab";
        case CharacterModelType.SKELETON: return "Skeleton";
        case CharacterModelType.FOREST_GUARDIAN: return "Forest Guardian";
        default:{
            assert(false);
        }
    }
}
::ConstHelper.ItemIdToString <- function(e){
    return ::Items[e].getName();
}

enum CharacterModelPartType{
    NONE,

    HEAD,
    BODY,
    LEFT_HAND,
    RIGHT_HAND,
    LEFT_FOOT,
    RIGHT_FOOT,

    LEFT_MISC_1,
    LEFT_MISC_2,
    RIGHT_MISC_1,
    RIGHT_MISC_2,

    MAX
};

enum CharacterModelEquipNodeType{
    NONE,

    LEFT_HAND,
    RIGHT_HAND,

    //Place where weapons are put when not active.
    WEAPON_STORE,

    MAX
};

enum CharacterModelAnimId{
    NONE,

    BASE_LEGS_WALK,
    BASE_ARMS_WALK,
    BASE_ARMS_SWIM,

    REGULAR_SWORD_SWING,
    REGULAR_TWO_HANDED_SWORD_SWING,

    SQUID_WALK,
    CRAB_WALK,
    FOREST_GUARDIAN_WALK,
    FOREST_GUARDIAN_ARMS_WALK,

    MAX
};

enum CharacterModelAnimBaseType{
    UPPER_WALK,
    LOWER_WALK,

    UPPER_SWIM,

    MAX
};
//-------------------