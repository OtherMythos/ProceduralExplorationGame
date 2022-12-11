enum Enemy{
    NONE,
    GOBLIN,

    MAX
};

enum ObjectType{
    SCREEN_DATA = "ScreenData"
};

enum EnemyNames{
    NONE = "None",
    GOBLIN = "Goblin",

    MAX = "Max"
};

enum ItemType{
    EQUIPPABLE,
    CONSUMABLE
};

enum Item{
    NONE,
    HEALTH_POTION,
    SIMPLE_SWORD,
    SIMPLE_SHIELD,

    MAX,
};

enum ItemNames{
    NONE = "None",
    HEALTH_POTION = "Health Potion",
    SIMPLE_SWORD = "Simple Sword",
    SIMPLE_SHIELD = "Simple Shield",

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
}

enum Place{
    NONE,
    HAUNTED_WELL,
    DARK_CAVE,
    GOBLIN_VILLAGE,
    WIND_SWEPT_BEACH,

    MAX
};

enum PlaceNames{
    NONE = "None",
    HAUNTED_WELL = "Haunted Well",
    DARK_CAVE = "Dark Cave",
    GOBLIN_VILLAGE = "Goblin Village",
    WIND_SWEPT_BEACH = "Wind Swept Beach",

    MAX = "Max"
};

enum FoundObjectType{
    NONE,
    ITEM,
    PLACE
};

enum ItemInfoMode{
    KEEP_SCRAP,
    USE
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

    MAX
};

enum EquippedSlotTypes{
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