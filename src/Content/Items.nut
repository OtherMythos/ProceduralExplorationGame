enum ItemId{
    NONE
};

enum ItemType{
    NONE,
    EQUIPPABLE,
    CONSUMABLE,
    MONEY,
    LORE_CONTENT,
    EAT,
    DRINK,
    MESSAGE_IN_A_BOTTLE
};

//Separate rotation parameters into re-useable objects.
enum ItemEquipTransformType{
    NONE,
    BASIC_SWORD,
    BASIC_SHIELD,
    BASIC_TWO_HANDED_SWORD,
    BASIC_STAFF,

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
    function getDefData() { return mItem_.getDefData(); }
    function isNone() { return mItemId_ == ItemId.NONE; }
    function getDef(){ return mItem_; }
    function getId(){ return mItem_.getId(); }
    function getType(){ return mItem_.getType(); }
    function getName(){ return mItem_.getName(); }
    function getMesh(){ return mItem_.getMesh(); }
    function getDescription(){ return mItem_.getDescription(); }
    function getEquippableData(){ return mItem_.getEquippableData(); }
    function getEquipTransforms(wield, wieldActive){ return mItem_.getEquipTransforms(wield, wieldActive); }
    function getSellValue(){ return mItem_.getSellValue(); }
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
    mSellValue = 0;
    mIcon = null;
    mDefData = null;

    mEquippableData = EquippableId.NONE;
    mEquipTransformType = ItemEquipTransformType.NONE;

    constructor(name, desc, mesh, icon, type, sellValue, defData, equippableData=null, equippableTransformType=ItemEquipTransformType.NONE){
        mName = name;
        mDesc = desc;
        mMesh = mesh;
        mType = type;
        mIcon = icon;
        mSellValue = sellValue;
        mEquippableData = equippableData;
        mDefData = defData;
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
    function getDefData(){ return mDefData; }
    function getSellValue(){ return mSellValue; }
    function getScrapVal(){ return (mSellValue*0.4).tointeger(); }
    function getEquippableData(){ return mEquippableData; }
    function getEquipTransforms(left, wieldActive){
        if(left){
            return wieldActive ? ItemTransforms_WieldActive_LEFT[mEquipTransformType] : ItemTransforms_WieldInactive_LEFT[mEquipTransformType];
        }else{
            return wieldActive ? ItemTransforms_WieldActive_RIGHT[mEquipTransformType] : ItemTransforms_WieldInactive_RIGHT[mEquipTransformType];
        }
    }

    function getIcon(){ return mIcon == null ? "icon_none" : mIcon; }
    function getMesh(){ return mMesh == null ? "smallPotion.voxMesh" : mMesh; }
}

::ItemEquipTransform <- class{
    mPosition = null;
    mOrientation = null;
    mScale = null;
    constructor(position, orientation=null, scale=null){
        mPosition = position;
        mOrientation = orientation;
        mScale = scale;
    }

    function copy(position, orientation=null, scale=null){
        return ::ItemEquipTransform(
            position == null ? mPosition : position,
            orientation == null ? mOrientation : orientation,
            scale == null ? mScale : scale
        );
    }

    function _tostring(){
        return ::wrapToString(::ItemEquipTransform, "ItemEquipTransform", format(
            "{pos: %s, orientation: %s, scale: %s",
            mPosition ? mPosition.tostring() : "null",
            mOrientation ? mOrientation.tostring() : "null",
            mScale ? mScale.tostring() : "null"
        ));
    }
};

::ItemTransforms_WieldActive_RIGHT <- array(ItemEquipTransformType.MAX, null);
::ItemTransforms_WieldInactive_RIGHT <- array(ItemEquipTransformType.MAX, null);
::ItemTransforms_WieldActive_LEFT <- array(ItemEquipTransformType.MAX, null);
::ItemTransforms_WieldInactive_LEFT <- array(ItemEquipTransformType.MAX, null);

//Common values
local commonScale = Vec3(1.4, 1.4, 1.0);

//--Transforms for active wield items--
::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_SWORD] = ::ItemEquipTransform(Vec3(0, 8, 0), Quat(2, ::Vec3_UNIT_Y));
::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_SHIELD] = ::ItemEquipTransform(Vec3(-4, 0, 0), Quat(-PI*0.5, ::Vec3_UNIT_Y), commonScale);
::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD] = ::ItemEquipTransform(Vec3(0, 14, 0), Quat(PI*0.6, ::Vec3_UNIT_Y), commonScale);
::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_STAFF] = ::ItemEquipTransform(Vec3(0, 0, 0), Quat(0, ::Vec3_UNIT_Y), commonScale);

//---Wield active left---
::ItemTransforms_WieldActive_LEFT[ItemEquipTransformType.BASIC_SWORD] = ::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_SWORD].copy(null, Quat(-2, ::Vec3_UNIT_Y), null);
::ItemTransforms_WieldActive_LEFT[ItemEquipTransformType.BASIC_SHIELD] = ::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_SHIELD].copy(Vec3(4, 0, 0), Quat(PI*0.5, ::Vec3_UNIT_Y), null);
::ItemTransforms_WieldActive_LEFT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD] = ::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD].copy(null, Quat(-PI*0.6, ::Vec3_UNIT_Y), null);
::ItemTransforms_WieldActive_LEFT[ItemEquipTransformType.BASIC_STAFF] = ::ItemTransforms_WieldActive_RIGHT[ItemEquipTransformType.BASIC_STAFF].copy(null, Quat(0, ::Vec3_UNIT_Y), null);

//--Transforms for wield inactive right--
::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_SWORD] = ::ItemEquipTransform(Vec3(0, 8, -3.5), Quat(PI, ::Vec3_UNIT_Y) * Quat(PI+PI/6, ::Vec3_UNIT_Z));
::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_SHIELD] = ::ItemEquipTransform(Vec3(-4, 3, -5), Quat(PI, ::Vec3_UNIT_Y) * Quat(PI/6, ::Vec3_UNIT_Z), commonScale);
::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD] = ::ItemEquipTransform(Vec3(0, 8, -3.5), Quat(0, ::Vec3_UNIT_Y) * Quat(PI/6, ::Vec3_UNIT_Z), commonScale);
::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_STAFF] = ::ItemEquipTransform(Vec3(0, 8, -3.5), Quat(PI, ::Vec3_UNIT_Y) * Quat(PI+PI/6, ::Vec3_UNIT_Z), commonScale);

//---Wield inactive left---
::ItemTransforms_WieldInactive_LEFT[ItemEquipTransformType.BASIC_SWORD] = ::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_SWORD].copy(null, Quat(PI, ::Vec3_UNIT_Y) * Quat(PI-PI/6, ::Vec3_UNIT_Z));
::ItemTransforms_WieldInactive_LEFT[ItemEquipTransformType.BASIC_SHIELD] = ::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_SHIELD].copy(null, Quat(PI, ::Vec3_UNIT_Y) * Quat(PI/6, ::Vec3_UNIT_Z));
::ItemTransforms_WieldInactive_LEFT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD] = ::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_TWO_HANDED_SWORD].copy(null, Quat(PI, ::Vec3_UNIT_Y) * Quat(PI/6, ::Vec3_UNIT_Z));
::ItemTransforms_WieldInactive_LEFT[ItemEquipTransformType.BASIC_STAFF] = ::ItemTransforms_WieldInactive_RIGHT[ItemEquipTransformType.BASIC_STAFF].copy(null, Quat(PI, ::Vec3_UNIT_Y) * Quat(PI-PI/6, ::Vec3_UNIT_Z));


::ItemHelper <- {
    coloursForStats = []

    function registerColourForStat(colValue){
        coloursForStats.append(colValue.getAsABGR());
    }

    function setupItemIds_(){
        foreach(c,i in ::Items){
            i.mId = c;
        }
    }

    /*
    function itemToStats(item){
        local stat = ::StatsEntry();

        switch(item){
            case ItemId.NONE: return stat;
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
                stat.mAttack = 2;
                return stat;
            }
            case ItemId.SIMPLE_TWO_HANDED_SWORD: {
                stat.mAttack = 10;
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
*/
    function actuateItem(item){
        local itemType = item.getType();
        if(itemType == ItemType.EQUIPPABLE){
            local equipSlot = ::Equippables[item.getEquippableData()].getEquippedSlot();
            //TODO give an option for which hand to equip the item into.
            equipSlot = EquippedSlotTypes.LEFT_HAND;
            ::Base.mPlayerStats.equipItem(item, equipSlot);
        }
        else if(itemType == ItemType.CONSUMABLE || itemType == ItemType.DRINK || itemType == ItemType.EAT){
            local itemStats = item.toStats();
            if(itemStats.mRestorativeHealth == 0){
                return;
            }
            //::Base.mPlayerStats.alterPlayerHealth(itemStats.mRestorativeHealth);
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            if(world == null){
                ::Base.mPlayerStats.alterPlayerHealth(itemStats.mRestorativeHealth);
            }else{
                local entityManager = world.getEntityManager();
                ::_applyHealthChangeOther(entityManager, world.getPlayerEID(), itemStats.mRestorativeHealth);
            }
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

    function determineEquippableDefForEquipped(equippedItems, enemyId){
        local rightHand = equippedItems[EquippedSlotTypes.RIGHT_HAND];
        local leftHand = equippedItems[EquippedSlotTypes.LEFT_HAND];

        rightHand = rightHand == null ? null : rightHand.getEquippableData();
        leftHand = leftHand == null ? null : leftHand.getEquippableData();

        if(
            leftHand == EquippableId.REGULAR_TWO_HANDED_SWORD ||
            rightHand == EquippableId.REGULAR_TWO_HANDED_SWORD
        )
        {
            return ::Equippables[EquippableId.REGULAR_TWO_HANDED_SWORD];
        }

        if(rightHand == EquippableId.REGULAR_SWORD){
            return ::Equippables[rightHand];
        }
        if(leftHand == EquippableId.REGULAR_SWORD){
            return ::Equippables[leftHand];
        }

        //Now just find the default equippable.
        if(enemyId == EnemyId.NONE){
            //Assume it's the player
            return ::Equippables[EquippableId.BARE_HANDS];
        }
        return ::Equippables[::Enemies[enemyId].getDefaultEquippableDef()];
    }

    function nameToItemId(itemName){
        foreach(c,i in ::Items){
            if(i.getName() == itemName){
                return c;
            }
        }

        return ItemId.NONE;
    }

    function removeItemsFromInventory(itemsTable){
        local playerStats = ::Base.mPlayerStats;

        if(!itemsTable.rawin("items")){
            return;
        }

        foreach(itemData in itemsTable.items){
            local idx = itemData.idx;
            local gridType = itemData.gridType;

            if(gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
                playerStats.unEquipItem(idx+1);
            }else if(gridType == InventoryGridType.INVENTORY_GRID){
                local inventory = playerStats.mInventory_;
                inventory.removeFromInventory(idx);
            }
        }
    }
};

ItemHelper.registerColourForStat(ColourValue(1, 0, 0, 1));
ItemHelper.registerColourForStat(ColourValue(0, 1, 0, 1));
ItemHelper.registerColourForStat(ColourValue(0, 0, 1, 1));