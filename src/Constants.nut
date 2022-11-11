enum Enemy{
    NONE,
    GOBLIN,

    MAX
};

enum EnemyNames{
    NONE = "None",
    GOBLIN = "Goblin",

    MAX = "Max"
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

::ItemToName <- function(item){
    switch(item){
        case Item.NONE: return ItemNames.NONE;
        case Item.HEALTH_POTION: return ItemNames.HEALTH_POTION;
        case Item.SIMPLE_SWORD: return ItemNames.SIMPLE_SWORD;
        case Item.SIMPLE_SHIELD: return ItemNames.SIMPLE_SHIELD;
        default:
            assert(false);
    }
}

::EnemyToName <- function(enemy){
    switch(enemy){
        case Enemy.NONE: return EnemyNames.NONE;
        case Enemy.GOBLIN: return EnemyNames.GOBLIN;
        default:
            assert(false);
    }
}