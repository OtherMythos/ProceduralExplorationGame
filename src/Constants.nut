::ConstHelper <- {};

const TRIGGER = 0;
const DAMAGE = 1;

const PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4;
const VISITED_WORLD_UNIT_MULTIPLIER = 0.4;

const EFFECT_WINDOW_CAMERA_Z = 100;

const SCREENS_START_Z = 40;
const POPUPS_START_Z = 60;

enum TargetInterface{
    MOBILE,
    DESKTOP,

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
};


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

//Profiles define how the game should operate,
//for instance if developing, profiles might help setup a development environment
enum GameProfile{
    RELEASE,
    DEVELOPMENT_BEGIN_EXPLORATION,
    TEST_SCREEN,
    DISPLAY_WORLD_STATS,
    FORCE_MOBILE_INTERFACE,

    MAX
};
::GameProfileString <- [
    "Release",
    "DevelopmentBeginExploration",
    "TestScreen",
    "DisplayWorldStats",
    "ForceMobileInterface"
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
    WORLD_SCENE_SCREEN,
    EXPLORATION_TEST_SCREEN,
    EXPLORATION_END_SCREEN,
    PLAYER_DEATH_SCREEN,
    WORLD_GENERATION_STATUS_SCREEN,
    NEW_SAVE_VALUES_SCREEN,

    MAX
};

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
    //TODO this whole equippable slot system could be reduced, as there's some duplication with the other equip system.
    HAND,
    LEFT_HAND,
    RIGHT_HAND,
    LEGS,
    FEET,
    ACCESSORY_1,
    ACCESSORY_2,

    MAX
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

//Characters --------
enum CharacterModelType{
    NONE,
    HUMANOID,
    GOBLIN,
    SQUID

    MAX
};
::ConstHelper.CharacterModelTypeToString <- function(e){
    switch(e){
        case CharacterModelType.NONE: return "None";
        case CharacterModelType.HUMANOID: return "Humanoid";
        case CharacterModelType.GOBLIN: return "Goblin";
        case CharacterModelType.SQUID: return "Squid";
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

    MAX
};

enum CharacterModelEquipNodeType{
    NONE,

    LEFT_HAND,
    RIGHT_HAND,

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

    MAX
};

enum CharacterModelAnimBaseType{
    UPPER_WALK,
    LOWER_WALK,

    UPPER_SWIM,

    MAX
};
//-------------------