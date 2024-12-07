::PlayerStats <- class{

    mCurrentData_ = null;
    mCurrentSaveSlot_ = -1;
    mInventory_ = null;

    mLastSaveTime_ = -1;

    mPlacesVisited_ = null;
    mLeanPlacesVisited_ = null;

    mPlayerCombatStats = null;

    constructor(){
        _event.subscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);
        _event.subscribe(Event.PLAYER_DIED, receivePlayerDiedEvent, this);

        mPlacesVisited_ = array(PlaceId.MAX, false);
        mLeanPlacesVisited_ = [];
        mInventory_ = ::Inventory();

        mPlayerCombatStats = ::Combat.CombatStats(EnemyId.NONE, 200);
        mPlayerCombatStats.calculateEquippedStats();
    }

    function shutdown(){
        _event.unsubscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);
        _event.unsubscribe(Event.PLAYER_DIED, receivePlayerDiedEvent, this);
    }

    function _tostring(){
        return ::wrapToString(::PlayerStats, "PlayerStats");
    }

    function initTime(){
        mLastSaveTime_ = _system.time();
        printf("Init time is %i", mLastSaveTime_);
    }
    function processTime(){
        if(mLastSaveTime_ < 0) return;

        local newTime = _system.time();
        local delta = newTime - mLastSaveTime_;
        if(delta > 0){
            mCurrentData_.playtimeSeconds += delta;
            printf("Playtime delta is %i for total seconds %i", delta, mCurrentData_.playtimeSeconds);
        }
        mLastSaveTime_ = newTime;
    }

    function copyQuestData_(questTable){
        local questManager = ::Base.mQuestManager;
        foreach(c,i in questTable){
            local q = questManager.getQuestForName(c);
            if(c == null) continue;
            foreach(cc,ii in i){
                q.setEntry(cc, ii);
            }
        }
    }

    function setSaveData(data, slotIdx){
        mCurrentSaveSlot_ = slotIdx;
        mCurrentData_ = data;
        local inventoryData = data.inventory.apply(function(itemVal){
            return itemVal == null ? null : ::Item(itemVal);
        });
        local equipData = data.playerEquipped.apply(function(itemVal){
            return itemVal == null ? null : ::Item(itemVal);
        });
        initTime();
        mInventory_.rawSetItems(inventoryData);
        mPlayerCombatStats.mEquippedItems.rawSetItems(equipData);
        mPlayerCombatStats.calculateEquippedStats();

        copyQuestData_(data.quest);
    }
    function getSaveSlot(){
        return mCurrentSaveSlot_;
    }
    function getSaveData(){
        //Sync up the inventory items to the data.
        assert(mInventory_.mInventoryItems_.len() == mCurrentData_.inventory.len());
        foreach(c,i in mInventory_.mInventoryItems_){
            mCurrentData_.inventory[c] = (i == null ? null : i.getId());
        }
        foreach(c,i in mPlayerCombatStats.mEquippedItems.mItems){
            if(i == null) continue;
            mCurrentData_.playerEquipped[c] = (i == null ? null : i.getId());
        }
        local questData = ::Base.mQuestManager.getTableForQuests();
        mCurrentData_.rawset("quest", questData);
        processTime();
        return mCurrentData_;
    }

    function addToInventory(item){
        mInventory_.addToInventory(item);
    }

    function alterPlayerHealth(amount){
        printf("Altering player health by %i", amount);
        mPlayerCombatStats.alterHealth(amount);
        setPlayerHealth_(mPlayerCombatStats.mHealth);
    }
    function setPlayerHealth(health){
        printf("Setting player health to %i", health);
        setPlayerHealth_(health);
    }
    function setPlayerHealth_(health){
        mPlayerCombatStats.setHealth(health);

        local data = {
            "health": mPlayerCombatStats.mHealth,
            "percentage": mPlayerCombatStats.getHealthPercentage()
        };
        //mPlayerEntry_.notifyNewHealth(newHealth, percentage);
        _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);

        if(mPlayerCombatStats.mDead){
            _event.transmit(Event.PLAYER_DIED, null);
        }
    }

    function toggleWieldActive(){
        setWieldActive(!mPlayerCombatStats.mWieldActive);
    }
    function setWieldActive(active){
        print("Setting player wield to " + active);
        //mPlayerCombatStats.setWieldActive(active);

        _event.transmit(Event.PLAYER_WIELD_ACTIVE_CHANGED, active);
    }
    function getWieldActive(){
        return mPlayerCombatStats.mWieldActive;
    }

    function notifyPlaceVisited(place){
        if(mPlacesVisited_[place]) return;

        print("Registering visited place " + ::Places[place].getName())
        mPlacesVisited_[place] = true;
        assert(mLeanPlacesVisited_.find(place) == null);
        mLeanPlacesVisited_.append(place);
    }

    function wasPlaceVisited(place){
        return (place in mPlacesVisited_);
    }

    function receivePlaceVisitedEvent(id, data){
        notifyPlaceVisited(data);
    }
    function receivePlayerDiedEvent(id, data){
        //If the player dies, reset the health to 100%
        mPlayerCombatStats.setHealthToMax();
    }

    function getPlayerHealth(){
        return mPlayerCombatStats.mHealth;
    }
    function getPlayerHealthPercentage(){
        return mPlayerCombatStats.getHealthPercentage();
    }

    function processPlayerDeath(){

    }

    function processExplorationSuccess(){

    }

    function getEquippedItem(slot){
        return mPlayerCombatStats.mEquippedItems.getEquippedItem(slot);
    }
    function equipItem(item, slot){
        printf("Equipping player item: %s", item.getName());
        local prevEquipped = mPlayerCombatStats.mEquippedItems.getEquippedItem(slot);
        mPlayerCombatStats.mEquippedItems.setEquipped(item, slot);

        equipChanged_();
        return prevEquipped;
    }
    function unEquipItem(slot){
        printf("UnEquipping player item at index: %i", slot);
        mPlayerCombatStats.mEquippedItems.unEquipItem(slot);

        equipChanged_();
    }
    function unequipTwoHandedItem(){
        local first = unequipTwoHandedItem_(EquippedSlotTypes.LEFT_HAND);
        local second = unequipTwoHandedItem_(EquippedSlotTypes.RIGHT_HAND);
        //There can't possibly be two, two handed equippables at a time.
        if(first != null && second != null) assert(false);
        if(first) return first;
        if(second) return second;
        return null;
    }
    function unequipTwoHandedItem_(slot){
        local item = getEquippedItem(slot);
        if(item != null){
            local equippableData = ::Equippables[item.getEquippableData()];
            if(equippableData.getEquippableCharacteristics() & EquippableCharacteristics.TWO_HANDED){
                unEquipItem(slot);
                return item;
            }
        }
        return null;
    }
    function equipChanged_(){
        mPlayerCombatStats.calculateEquippedStats();

        _event.transmit(Event.PLAYER_EQUIP_CHANGED, {
            "items": mPlayerCombatStats.mEquippedItems,
            "wieldActive": mPlayerCombatStats.mWieldActive
        });
    }

    function getLevel(){
        return getLevelForEXP_(mCurrentData_.playerEXP);
    }

    function getPercentageEXP(exp){
        local level = getLevelForEXP_(exp);
        return getPercentageForLevel_(level, exp);
    }
    function getLevelForEXP_(exp){
        foreach(c,i in EXP_LEVELS){
            if(exp < i) return c;
        }
        return EXP_LEVELS.len();
    }
    function getPercentageForLevel_(level, exp){
        if(level >= EXP_LEVELS.len()-1) return 1.0;
        local currentLevel = getEXPForLevel(level);
        assert(exp >= currentLevel);

        local diff = getEXPForLevel(level+1) - currentLevel;
        local delta = exp-currentLevel;
        local percentage = delta.tofloat() / diff.tofloat();
        assert(percentage <= 1.0);

        return percentage;
    }
    function addEXP(exp){
        local prevEXP = mCurrentData_.playerEXP;
        local prevLevel = getLevelForEXP_(prevEXP);
        mCurrentData_.playerEXP += exp;
        local newLevel = getLevelForEXP_(prevEXP);
        assert(prevLevel > 0);
        assert(newLevel > 0);

        local percentage = getPercentageEXP(mCurrentData_.playerEXP);
        local startPercentage = getPercentageEXP(prevEXP);
        local data = {
            "startLevel": prevLevel,
            "endLevel": newLevel,
            "startPercentage": startPercentage,
            "endPercentage": percentage,
            "startEXP": prevEXP,
            "endEXP": mCurrentData_.playerEXP
        }

        return data;
    }
    function getEXPForLevel(level){
        local target = level-1;
        if(target < 0) return EXP_LEVELS[0];
        return EXP_LEVELS[target];
    }
    function getEXPForSingleLevel(level){
        local start = getEXPForLevel(level);
        local end = getEXPForLevel(level+1);
        return end - start;
    }


    EXP_LEVELS = [
        //NOTE: You're level 1 if you have 0 EXP, there is no level 0.
        0,
        83,
        174,
        276,
        388,
        512,
        650,
        801,
        969,
        1154,
        1358,
        1584,
        1833,
        2107,
        2411,
        2746,
        3115,
        3523,
        3973,
        4470,
        5018,
        5624,
        6291,
        7028,
        7842,
        8740,
        9730,
        10824,
        12031,
        13363,
        14833,
        16456,
        18247,

        20224,
        22406,
        24815,
        27473,
        30408,
        33648,
        37224,
        41171,
        45529,
        50339,
        55649,
        61512,
        67983,
        75127,
        83014,
        91721,
        101333,
        111945,
        123660,
        136594,
        150872,
        166636,
        184040,
        203254,
        224466,
        247886,
        273742,
        302288,
        333804,
        368599,
        407015,
        449428,
        496254,

        547953,
        605032,
        668051,
        737627,
        814445,
        899257,
        992895,
        1096278,
        1210421,
        1336443,
        1475581,
        1629200,
        1798808,
        1986068,
        2192818,
        2421087,
        2673114,
        2951373,
        3258594,
        3597792,
        3972294,
        4385776,
        4842295,
        5346332,
        5902831,
        6517253,
        7195629,
        7944614,
        8771558,
        9684577,
        10692629,
        11805606,
        13034431
    ];


};