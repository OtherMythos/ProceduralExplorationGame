enum ItemId{
    NONE,
    HEALTH_POTION,
    LARGE_HEALTH_POTION,

    SIMPLE_SWORD,
    SIMPLE_SHIELD,
    SIMPLE_TWO_HANDED_SWORD,
    BONE_MACE,

    MAX,
};

enum ItemType{
    NONE,
    EQUIPPABLE,
    CONSUMABLE,
    MONEY
};

//Separate rotation parameters into re-useable objects.
enum ItemEquipTransformType{
    NONE,
    BASIC_SWORD,
    BASIC_SHIELD,
    BASIC_TWO_HANDED_SWORD,

    MAX
};

/**
 * Item objects.
 * This separates items from itemDefs.
 * ItemDefs are static and should not change.
 * However, certain items might have effects such as curses, buffs, etc.
 * This wrapper contains that information while also storing a reference to the item def.
 */
::Item <- class{
    mItemId_ = ItemId.NONE;
    mItem_ = null;
    mData_ = null;
    constructor(item=ItemId.NONE, data=null){
        mItemId_ = item;
        mItem_ = ::Items[item];
        mData_ = data;
    }

    function getData() { return mData_; }
    function isNone() { return mItemId_ == ItemId.NONE; }
    function getDef(){ return mItem_; }
    function getId(){ return mItem_.getId(); }
    function getType(){ return mItem_.getType(); }
    function getName(){ return mItem_.getName(); }
    function getMesh(){ return mItem_.getMesh(); }
    function getDescription(){ return mItem_.getDescription(); }
    function getEquippableData(){ return mItem_.getEquippableData(); }
    function getEquippablePosition(){ return mItem_.getEquippablePosition(); }
    function getEquippableOrientation(){ return mItem_.getEquippableOrientation(); }
    function getEquippableScale(){ return mItem_.getEquippableScale(); }
    function getScrapVal(){ return mItem_.getScrapVal(); }
    function getIcon(){ return mItem_.getIcon(); }
    function toStats(){
        return ::ItemHelper.itemToStats(mItemId_);
    }
    function _tostring(){
        return ::wrapToString(::Item, "Item", getName());
    }
}
::ItemDef <- class{
    mId = null;
    mName = null;
    mDesc = null;
    mMesh = null;
    mType = ItemType.NONE;
    mScrapVal = 0;
    mIcon = null;

    mEquippableData = EquippableId.NONE;
    mEquipTransformType = ItemEquipTransformType.NONE;

    constructor(name, desc, mesh, icon, type, scrapVal, equippableData, equippableTransformType=ItemEquipTransformType.NONE){
        mName = name;
        mDesc = desc;
        mMesh = mesh;
        mType = type;
        mIcon = icon;
        mScrapVal = scrapVal;
        mEquippableData = equippableData;
        mEquipTransformType = equippableTransformType;

        //Sanity checks.
        if(mType == ItemType.CONSUMABLE){
            assert(mEquippableData == EquippableId.NONE);
        }
    }

    function _tostring(){
        return ::wrapToString(::ItemDef, "ItemDef", mName);
    }

    function getId(){ return mId; }
    function getType(){ return mType; }
    function getName(){ return mName; }
    function getDescription(){ return mDesc; }
    function getMesh(){ return mMesh; }
    function getScrapVal(){ return mScrapVal; }
    function getEquippableData(){ return mEquippableData; }
    function getEquippablePosition(){ return ::ItemEquipTransforms[mEquipTransformType].mPosition; }
    function getEquippableOrientation(){ return ::ItemEquipTransforms[mEquipTransformType].mOrientation; }
    function getEquippableScale(){ return ::ItemEquipTransforms[mEquipTransformType].mScale; }
    function getIcon(){ return mIcon == null ? "icon_none" : mIcon; }
}
::Items <- array(ItemId.MAX, null);

//-------------------------------
::Items[ItemId.NONE] = ItemDef("None", "None", null, null ItemType.NONE, 1, EquippableId.NONE);

::Items[ItemId.HEALTH_POTION] = ItemDef("Health Potion", "A potion of health. Bubbles gently inside a cast glass flask.", "smallPotion.mesh", "item_healthPotion", ItemType.CONSUMABLE, 5, EquippableId.NONE);
::Items[ItemId.LARGE_HEALTH_POTION] = ItemDef("Large Health Potion", "A large potion of health.", "largePotion.mesh", "item_largeHealthPotion", ItemType.CONSUMABLE, 10, EquippableId.NONE);

::Items[ItemId.SIMPLE_SWORD] = ItemDef("Simple Sword", "A cheap, weak sword. Relatively blunt for something claiming to be a sword.", "simpleSword.mesh", "item_simpleSword", ItemType.EQUIPPABLE, 5, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);
::Items[ItemId.SIMPLE_SHIELD] = ItemDef("Simple Shield", "An un-interesting shield. Provides minimal protection.", "simpleShield.mesh", "item_simpleShield", ItemType.EQUIPPABLE, 5, EquippableId.REGULAR_SHIELD, ItemEquipTransformType.BASIC_SHIELD);
::Items[ItemId.SIMPLE_TWO_HANDED_SWORD] = ItemDef("Simple Two Handed sword", "A two handed sword as blunt as it is big.", "simpleTwoHandedSword.mesh", "item_simpleTwoHandedSword", ItemType.EQUIPPABLE, 5, EquippableId.REGULAR_TWO_HANDED_SWORD, ItemEquipTransformType.BASIC_TWO_HANDED_SWORD);
::Items[ItemId.BONE_MACE] = ItemDef("Bone Mace", "Large clobbering clump of ex-person erecter.", "boneMace.mesh", "item_boneMace", ItemType.EQUIPPABLE, 5, EquippableId.REGULAR_SWORD, ItemEquipTransformType.BASIC_SWORD);
//-------------------------------

::ItemEquipTransform <- class{
    mPosition = null;
    mOrientation = null;
    mScale = null;
    constructor(position, orientation=null, scale=null){
        mPosition = position;
        mOrientation = orientation;
        mScale = scale;
    }
};

::ItemEquipTransforms <- array(ItemEquipTransformType.MAX, null);

::ItemEquipTransforms[ItemEquipTransformType.NONE] = ::ItemEquipTransform(Vec3(0, 0, 0));

::ItemEquipTransforms[ItemEquipTransformType.BASIC_SWORD] = ::ItemEquipTransform(Vec3(0, 8, 0), Quat(2, ::Vec3_UNIT_Y));
::ItemEquipTransforms[ItemEquipTransformType.BASIC_SHIELD] = ::ItemEquipTransform(Vec3(-4, 0, 0), Quat(-PI*0.5, ::Vec3_UNIT_Y), Vec3(1.4, 1.4, 1.0));
::ItemEquipTransforms[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD] = ::ItemEquipTransform(Vec3(0, 14, 0), Quat(), Vec3(1.4, 1.4, 1.0));

function setupItemIds_(){
    foreach(c,i in ::Items){
        i.mId = c;
    }
}

::ItemHelper <- {
    coloursForStats = []

    function registerColourForStat(colValue){
        coloursForStats.append(colValue.getAsABGR());
    }

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
            case ItemId.BONE_MACE:
            case ItemId.SIMPLE_SWORD: {
                stat.mAttack = 5;
                return stat;
            }
            case ItemId.SIMPLE_TWO_HANDED_SWORD: {
                stat.mAttack = 15;
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
        local itemType = item.getType();
        if(itemType == ItemType.EQUIPPABLE){
            local equipSlot = ::Equippables[item.getEquippableData()].getEquippedSlot();
            //TODO give an option for which hand to equip the item into.
            equipSlot = EquippedSlotTypes.LEFT_HAND;
            ::Base.mPlayerStats.equipItem(item, equipSlot);
        }
        else if(itemType == ItemType.CONSUMABLE){
            local itemStats = item.toStats();
            assert(itemStats.mRestorativeHealth != 0);
            ::Base.mPlayerStats.alterPlayerHealth(itemStats.mRestorativeHealth);
        }
        else if(itemType == ItemType.MONEY){
            local data = item.getData();
            ::Base.mPlayerStats.mInventory_.addMoney(data.money);
        }
        else if(itemType == ItemType.NONE){
            //Easter egg
            ::Base.mPlayerStats.setPlayerHealth(1);
            local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
            currentWorld.spawnEnemies(currentWorld.getPlayerPosition(), 10, 5);
        }else{
            assert(false);
        }
    }

    function nameToItemId(itemName){
        foreach(c,i in ::Items){
            if(i.getName() == itemName){
                return c;
            }
        }

        return ItemId.NONE;
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

    function _tostring(){
        local t = format("{restorativeHealth: %i, attack: %i, defense: %i}", mRestorativeHealth, mAttack, mDefense);
        return ::wrapToString(::FoundObject, "ItemStat", t);
    }

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
                return format("Restores %i health.", mRestorativeHealth);
            }
            case StatType.ATTACK:{
                return format("Increases attack by %i.", mAttack);
            }
            case StatType.DEFENSE:{
                return format("Increases defense by %i.", mDefense);
            }
            default:
                assert(false);
        }
    }

    function getColourForStat(stat){
        local statColour = ::ItemHelper.coloursForStats[stat];
        return statColour;
    }

    function getDescriptionWithRichText(){
        local outString = "";
        local outRichText = [];
        for(local i = 0; i < StatType.MAX; i++){
            if(!hasStatType(i)) continue;
            print(getDescriptionForStat(i));
            local appendString = getDescriptionForStat(i) + "\n";

            local colour = getColourForStat(i);
            outRichText.append({"offset": outString.len(), "len": appendString.len(), "col": colour});
            outString += appendString;
        }

        return [outString, outRichText];
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

ItemHelper.registerColourForStat(ColourValue(1, 0, 0, 1));
ItemHelper.registerColourForStat(ColourValue(0, 1, 0, 1));
ItemHelper.registerColourForStat(ColourValue(0, 0, 1, 1));

setupItemIds_();