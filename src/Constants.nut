const TRIGGER = 0;

enum Enemy{
    NONE,
    GOBLIN,

    MAX
};

enum ObjectType{
    SCREEN_DATA = "ScreenData",
    POPUP_DATA = "PopupData"
};

enum EnemyNames{
    NONE = "None",
    GOBLIN = "Goblin",

    MAX = "Max"
};

enum StatType{
    RESTORATIVE_HEALTH,
    ATTACK,
    DEFENSE,

    MAX
};

enum Event{
    INVENTORY_CONTENTS_CHANGED = 1001,
    MONEY_CHANGED = 1002,
    PLACE_VISITED = 1003,

    DIALOG_SPOKEN = 1004,
    DIALOG_META = 1005,

    STORY_CONTENT_FINISHED = 1006,
    PLAYER_DIED = 1007,

    COMBAT_SPOILS_CHANGE = 1008
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
    SAVE_SELECTION_SCREEN,
    GAMEPLAY_MAIN_MENU_SCREEN,
    EXPLORATION_SCREEN,
    ENCOUNTER_POPUP_SCREEN,
    COMBAT_SCREEN,
    ITEM_INFO_SCREEN,
    INVENTORY_SCREEN,
    VISITED_PLACES_SCREEN,
    PLACE_INFO_SCREEN,
    STORY_CONTENT_SCREEN,
    DIALOG_SCREEN,
    COMBAT_SPOILS_POPUP_SCREEN,
    TEST_SCREEN,
    WORLD_SCENE_SCREEN

    MAX
};

enum Popup{
    POPUP,
    BOTTOM_OF_SCREEN,

    MAX
};

enum EquippedSlotTypes{
    NONE,
    HEAD,
    BODY,
    SWORD,
    SHIELD
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