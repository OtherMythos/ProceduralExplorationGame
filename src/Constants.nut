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
    DIALOG,
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
    TESTING_WORLD,
    OVERWORLD
};
::WorldTypeStrings <- [
    "World",
    "ProceduralExplorationWorld",
    "ProceduralDungeonWorld",
    "VisitedLocationWorld",
    "TestingWorld",
    "Overworld",
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
    INVENTORY_EQUIPPABLES,
    INVENTORY_GRID_SECONDARY
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

enum CollisionWorldTriggerResponses{
    EXP_ORB,
    OVERWORLD_VISITED_PLACE,
    REGISTER_TELEPORT_LOCATION,
    PROJECTILE_DAMAGE,
    PASSIVE_DAMAGE,
    BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED,
    BASIC_ENEMY_PLAYER_TARGET_RADIUS,
    BASIC_ENEMY_PLAYER_TARGET_RADIUS_PROJECTILE,
    DIE,
    NPC_INTERACT,
    PLACED_ITEM_COLLIDE_CHANGE,
    COLLECTABLE_ITEM_COLLIDE,
    ITEM_SEARCH,
    PICK,
    PICK_KEEP_PLACED_ITEM,
    READ_LORE,

    MAX = 100
};

enum Event{
    INVENTORY_CONTENTS_CHANGED = 1001,
    MONEY_CHANGED = 1002,
    PLACE_VISITED = 1003,

    DIALOG_SPOKEN = 1004,
    DIALOG_META = 1005,
    DIALOG_OPTION = 1006,

    PLAYER_DIED = 1008,

    MONEY_ADDED = 1009,
    EXP_ORBS_ADDED = 1010
    SCREEN_CHANGED = 1011,

    PLAYER_HEALTH_CHANGED = 1012,
    PLAYER_TARGET_CHANGE = 1013,

    CURRENT_WORLD_CHANGE = 1014,
    ACTIVE_WORLD_CHANGE = 1015,
    WORLD_DESTROYED = 1016,

    WORLD_PREPARATION_GENERATION_PROGRESS = 1020,
    WORLD_PREPARATION_STATE_CHANGE = 1021,

    PLACE_DISCOVERED = 1022,
    PLAYER_EQUIP_CHANGED = 1023,
    PLAYER_WIELD_ACTIVE_CHANGED = 1024,

    ACTIONS_CHANGED = 1025,
    SYSTEM_SETTINGS_CHANGED = 1026,

    BIOME_DISCOVER_STATS_CHANGED = 1027,
    GAMEPLAY_SESSION_STARTED = 1028,

    REQUEST_WORLD_VIEW_CHANGE = 1029,

    REGION_DISCOVERED_POPUP_FINISHED = 1030,

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

enum Popup{
    POPUP,
    BOTTOM_OF_SCREEN,
    TOP_RIGHT_OF_SCREEN,
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
    STATUS_EFFECT_FIRE,
    STATUS_EFFECT_FROZEN,

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
    VISIT,
    END_EXPLORATION,
    DESCEND,
    ASCEND,
    ENTER,
    ITEM_SEARCH,
    PICK,
    READ_LORE,
};

enum SystemSetting{
    INVERT_CAMERA_CONTROLLER,
    TOGGLE_WIREFRAME,
    TOGGLE_RENDER_STATS,

    MAX
};

::ActionSlotTypeString <- [
    "None",
    "Talk",
    "Visit",
    "End Exploration",
    "Descend",
    "Ascend",
    "Enter",
    "Item Search",
    "Pick",
    "Read"
];

enum ProceduralDungeonTypes{
    CATACOMB,
    DUST_MITE_NEST
};

enum TileGridMasks{
    HOLE = 0x80,
    ROTATE_90 = 0x20,
    ROTATE_180 = 0x40,
    ROTATE_270 = 0x60,
}

//Characters --------
enum CharacterModelType{
    NONE,
    HUMANOID,
    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,
    FOREST_GUARDIAN,
    BEE,
    DUST_MITE_WORKER,

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
        case CharacterModelType.BEE: return "Bee";
        case CharacterModelType.DUST_MITE_WORKER: return "Dust Mite Worker";
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
    LEFT_MISC_3,
    RIGHT_MISC_1,
    RIGHT_MISC_2,
    RIGHT_MISC_3,

    MAX
};

//TODO change this to be a bitmask so the same node can perform multiple destinations.
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