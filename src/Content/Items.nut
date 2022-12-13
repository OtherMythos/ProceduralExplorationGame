enum ItemId{
    NONE,
    HEALTH_POTION,
    SIMPLE_SWORD,
    SIMPLE_SHIELD,

    MAX,
};

enum ItemType{
    NONE,
    EQUIPPABLE,
    CONSUMABLE
};

::ItemDef <- class{
    mName = null;
    mDesc = null;
    mType = ItemType.NONE;
    mScrapVal = 0;
    mEquippableSlot = EquippedSlotTypes.NONE;

    constructor(name, desc, type, scrapVal, equippableSlot){
        mName = name;
        mDesc = desc;
        mType = type;
        mScrapVal = scrapVal;
        mEquippableSlot = equippableSlot;

        //Sanity checks.
        if(mType == ItemType.CONSUMABLE){
            assert(mEquippableSlot == EquippedSlotTypes.NONE);
        }
    }

    function getType(){ return mType; }
    function getName(){ return mName; }
    function getDescription(){ return mDesc; }
    function getEquippableSlot(){ return mEquippableSlot; }
    function getScrapVal(){ return mScrapVal; }
}
::Items <- array(ItemId.MAX, null);

::Items[ItemId.HEALTH_POTION] = ItemDef("Health Potion", "A potion of health. Bubbles gently inside a cast glass flask.", ItemType.CONSUMABLE, 5, EquippedSlotTypes.NONE);
::Items[ItemId.SIMPLE_SWORD] = ItemDef("Simple Sword", "A cheap, weak sword. Relatively blunt for something claiming to be a sword.", ItemType.EQUIPPABLE, 5, EquippedSlotTypes.SWORD);
::Items[ItemId.SIMPLE_SHIELD] = ItemDef("Simple Shield", "An un-interesting shield. Provides minimal protection.", ItemType.EQUIPPABLE, 5, EquippedSlotTypes.SHIELD);

::ItemHelper <- {
    function itemToStats(item){
        local stat = ItemStat();

        switch(item){
            case ItemId.NONE: return ItemStat();
            case ItemId.HEALTH_POTION: {
                stat.mRestorativeHealth = 10;
                return stat;
            }
            case ItemId.SIMPLE_SWORD: {
                stat.mAttack = 5;
                return stat;
            }
            case ItemId.SIMPLE_SHIELD: {
                stat.mDefense = 5;
                return stat;
            }
            default:
                assert(false);
        }

        return stat;
    }

    function actuateItem(item){
        local itemDef = Items[item];

        local itemType = itemDef.getType();
        if(itemType == ItemType.EQUIPPABLE){
            local slotIdx = itemDef.getEquippableSlot();
            ::Base.mPlayerStats.equipItem(item, slotIdx);
        }
        else if(itemType == ItemType.CONSUMABLE){
            switch(item){
                case ItemId.HEALTH_POTION:{
                    ::Base.mPlayerStats.alterPlayerHealth(10);
                    break;
                }
                default:{
                    assert(false);
                }
            }
        }else{
            assert(false);
        }
    }

    function enemyToName(enemy){
        switch(enemy){
            case Enemy.NONE: return EnemyNames.NONE;
            case Enemy.GOBLIN: return EnemyNames.GOBLIN;
            default:
                assert(false);
        }
    }
};

/**
 * Store item stats as a class rather than creating a new table each time.
 * This should save the strings to identify the entries from being created each time like would happen in a table.
 */
::ItemHelper.ItemStat <- class{
    mRestorativeHealth = 0;
    mAttack = 0;
    mDefense = 0;

    function hasStatType(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH: return mRestorativeHealth != 0;
            case StatType.ATTACK: return mAttack != 0;
            case StatType.DEFENSE: return mDefense != 0;
            default:
                assert(false);
        }
    }

    function getStatType(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH: return mRestorativeHealth;
            case StatType.ATTACK: return mAttack;
            case StatType.DEFENSE: return mDefense;
            default:
                assert(false);
        }
    }

    function getDescriptionForStat(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH:{
                return format("  Restores %i health.", mRestorativeHealth);
            }
            case StatType.ATTACK:{
                return format("  Increases attack by %i.", mAttack);
            }
            case StatType.DEFENSE:{
                return format("  Increases defense by %i.", mDefense);
            }
            default:
                assert(false);
        }
    }

    /**
    * Add an item stat's values to this.
    */
    function _add(stat){
        mRestorativeHealth += stat.mRestorativeHealth;
        mAttack += stat.mAttack;
        mDefense += stat.mDefense;

        return this;
    }
};