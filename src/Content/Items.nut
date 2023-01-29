enum ItemId{
    NONE,
    HEALTH_POTION,
    LARGE_HEALTH_POTION,

    SIMPLE_SWORD,
    SIMPLE_SHIELD,

    BRONZE_SWORD,
    BRONZE_SHIELD,
    BRONZE_LEGGINGS,
    BRONZE_CHESTPLATE,
    BRONZE_HELMET,
    BRONZE_BOOTS,
    BRONZE_BATTLEAXE,
    BRONZE_DAGGER,

    IRON_SWORD,
    IRON_SHIELD,
    IRON_LEGGINGS,
    IRON_CHESTPLATE,
    IRON_HELMET,
    IRON_BOOTS,
    IRON_BATTLEAXE,
    IRON_DAGGER,

    STEEL_SWORD,
    STEEL_SHIELD,
    STEEL_LEGGINGS,
    STEEL_CHESTPLATE,
    STEEL_HELMET,
    STEEL_BOOTS,
    STEEL_BATTLEAXE,
    STEEL_DAGGER,



    MAX,
};

enum ItemType{
    NONE,
    EQUIPPABLE,
    CONSUMABLE,
    MONEY
};

/**
 * Item objects.
 * This separates items from itemDefs.
 * ItemDefs are static and should not change.
 * However, certain items might have effects such as curses, buffs, etc.
 * This wrapper contains that information while also storing a reference to the item def.
 */
::Item <- class{
    mItem_ = null;
    constructor(item=ItemId.NONE){
        mItem_ = ::Items[item];
    }

    function isNone() { return getType() == ItemId.NONE; }
    function getDef(){ return mItem_; }
    function getType(){ return mItem_.getType(); }
    function getName(){ return mItem_.getName(); }
    function getDescription(){ return mItem_.getDescription(); }
    function getEquippableSlot(){ return mItem_.getEquippableSlot(); }
    function getScrapVal(){ return mItem_.getScrapVal(); }
    function toStats(){
        return ::ItemHelper.itemToStats(getType());
    }
}
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

//-------------------------------
::Items[ItemId.NONE] = ItemDef("None", "None", ItemType.NONE, 1, EquippedSlotTypes.NONE);

::Items[ItemId.HEALTH_POTION] = ItemDef("Health Potion", "A potion of health. Bubbles gently inside a cast glass flask.", ItemType.CONSUMABLE, 5, EquippedSlotTypes.NONE);
::Items[ItemId.LARGE_HEALTH_POTION] = ItemDef("Large Health Potion", "A large potion of health.", ItemType.CONSUMABLE, 5, EquippedSlotTypes.NONE);

::Items[ItemId.SIMPLE_SWORD] = ItemDef("Simple Sword", "A cheap, weak sword. Relatively blunt for something claiming to be a sword.", ItemType.EQUIPPABLE, 5, EquippedSlotTypes.SWORD);
::Items[ItemId.SIMPLE_SHIELD] = ItemDef("Simple Shield", "An un-interesting shield. Provides minimal protection.", ItemType.EQUIPPABLE, 5, EquippedSlotTypes.SHIELD);

::Items[ItemId.BRONZE_SWORD] = ItemDef("Bronze Sword", "A sword made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);
::Items[ItemId.BRONZE_SHIELD] = ItemDef("Bronze Shield", "A shield made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SHIELD);
::Items[ItemId.BRONZE_LEGGINGS] = ItemDef("Bronze Leggings", "A set of leegings made from bronze.", ItemType.EQUIPPABLE, 15, EquippedSlotTypes.LEGS);
::Items[ItemId.BRONZE_CHESTPLATE] = ItemDef("Bronze Chestplate", "A chestplate made from bronze.", ItemType.EQUIPPABLE, 15, EquippedSlotTypes.BODY);
::Items[ItemId.BRONZE_HELMET] = ItemDef("Bronze Helmet", "A helmet made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.HEAD);
::Items[ItemId.BRONZE_BOOTS] = ItemDef("Bronze Boots", "A pair of boots made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.FEET);
::Items[ItemId.BRONZE_BATTLEAXE] = ItemDef("Bronze Battleaxe", "A battleaxe made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);
::Items[ItemId.BRONZE_DAGGER] = ItemDef("Bronze Dagger", "A dagger made from bronze.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);

::Items[ItemId.IRON_SWORD] = ItemDef("Iron Sword", "A sword made from iron.", ItemType.EQUIPPABLE, 20, EquippedSlotTypes.SWORD);
::Items[ItemId.IRON_SHIELD] = ItemDef("Iron Shield", "A shield made from iron.", ItemType.EQUIPPABLE, 20, EquippedSlotTypes.SHIELD);
::Items[ItemId.IRON_LEGGINGS] = ItemDef("Iron Leggings", "A set of leegings made from iron.", ItemType.EQUIPPABLE, 25, EquippedSlotTypes.LEGS);
::Items[ItemId.IRON_CHESTPLATE] = ItemDef("Iron Chestplate", "A chestplate made from iron.", ItemType.EQUIPPABLE, 25, EquippedSlotTypes.BODY);
::Items[ItemId.IRON_HELMET] = ItemDef("Iron Helmet", "A helmet made from iron.", ItemType.EQUIPPABLE, 20, EquippedSlotTypes.HEAD);
::Items[ItemId.IRON_BOOTS] = ItemDef("Iron Boots", "A pair of boots made from iron.", ItemType.EQUIPPABLE, 20, EquippedSlotTypes.FEET);
::Items[ItemId.IRON_BATTLEAXE] = ItemDef("Iron Battleaxe", "A battleaxe made from iron.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);
::Items[ItemId.IRON_DAGGER] = ItemDef("Iron Dagger", "A dagger made from iron.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);

::Items[ItemId.STEEL_SWORD] = ItemDef("Steel Sword", "A sword made from steel.", ItemType.EQUIPPABLE, 30, EquippedSlotTypes.SWORD);
::Items[ItemId.STEEL_SHIELD] = ItemDef("Steel Shield", "A shield made from steel.", ItemType.EQUIPPABLE, 30, EquippedSlotTypes.SHIELD);
::Items[ItemId.STEEL_LEGGINGS] = ItemDef("Steel Leggings", "A set of leegings made from steel.", ItemType.EQUIPPABLE, 35, EquippedSlotTypes.LEGS);
::Items[ItemId.STEEL_CHESTPLATE] = ItemDef("Steel Chestplate", "A chestplate made from steel.", ItemType.EQUIPPABLE, 35, EquippedSlotTypes.BODY);
::Items[ItemId.STEEL_HELMET] = ItemDef("Steel Helmet", "A helmet made from steel.", ItemType.EQUIPPABLE, 30, EquippedSlotTypes.HEAD);
::Items[ItemId.STEEL_BOOTS] = ItemDef("Steel Boots", "A pair of boots made from steel.", ItemType.EQUIPPABLE, 30, EquippedSlotTypes.FEET);
::Items[ItemId.STEEL_BATTLEAXE] = ItemDef("Steel Battleaxe", "A battleaxe made from steel.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);
::Items[ItemId.STEEL_DAGGER] = ItemDef("Steel Dagger", "A dagger made from steel.", ItemType.EQUIPPABLE, 10, EquippedSlotTypes.SWORD);
//-------------------------------

::ItemHelper <- {
    function itemToStats(item){
        local stat = ItemStat();

        switch(item){
            case ItemId.NONE: return ItemStat();
            case ItemId.HEALTH_POTION: {
                stat.mRestorativeHealth = 10;
                return stat;
            }
            case ItemId.LARGE_HEALTH_POTION: {
                stat.mRestorativeHealth = 20;
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

            case ItemId.BRONZE_SWORD:
            case ItemId.BRONZE_DAGGER:
            case ItemId.BRONZE_BATTLEAXE:
            {
                stat.mAttack = 10;
                return stat;
            }
            case ItemId.BRONZE_SHIELD:
            case ItemId.BRONZE_LEGGINGS:
            case ItemId.BRONZE_CHESTPLATE:
            case ItemId.BRONZE_HELMET:
            case ItemId.BRONZE_BOOTS:
            {
                stat.mDefense = 10;
                return stat;
            }

            case ItemId.IRON_SWORD:
            case ItemId.IRON_DAGGER:
            case ItemId.IRON_BATTLEAXE:
            {
                stat.mAttack = 20;
                return stat;
            }
            case ItemId.IRON_SHIELD:
            case ItemId.IRON_LEGGINGS:
            case ItemId.IRON_CHESTPLATE:
            case ItemId.IRON_HELMET:
            case ItemId.IRON_BOOTS:
            {
                stat.mDefense = 20;
                return stat;
            }

            case ItemId.STEEL_SWORD:
            case ItemId.STEEL_DAGGER:
            case ItemId.STEEL_BATTLEAXE:
            {
                stat.mAttack = 30;
                return stat;
            }
            case ItemId.STEEL_SHIELD:
            case ItemId.STEEL_LEGGINGS:
            case ItemId.STEEL_CHESTPLATE:
            case ItemId.STEEL_HELMET:
            case ItemId.STEEL_BOOTS:
            {
                stat.mDefense = 30;
                return stat;
            }
            default:
                assert(false);
        }

        return stat;
    }

    function actuateItem(item){
        local itemType = item.getType();
        if(itemType == ItemType.EQUIPPABLE){
            local slotIdx = item.getEquippableSlot();
            ::Base.mPlayerStats.equipItem(item, slotIdx);
        }
        else if(itemType == ItemType.CONSUMABLE){
            local itemStats = item.toStats();
            assert(itemStats.mRestorativeHealth != 0);
            ::Base.mPlayerStats.alterPlayerHealth(itemStats.mRestorativeHealth);
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