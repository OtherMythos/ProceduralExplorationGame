::PlayerStats <- class{

    mCurrentData_ = null;

    mPlacesVisited_ = null;
    mLeanPlacesVisited_ = null;

    mPlayerCombatStats = null;

    constructor(){
        _event.subscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);
        _event.subscribe(Event.PLAYER_DIED, receivePlayerDiedEvent, this);

        mPlacesVisited_ = array(PlaceId.MAX, false);
        mLeanPlacesVisited_ = [];

        mPlayerCombatStats = ::Combat.CombatStats(EnemyId.NONE, 100);

        equipItem(::Item(ItemId.SIMPLE_SWORD), EquippedSlotTypes.LEFT_HAND);
        equipItem(::Item(ItemId.SIMPLE_SHIELD), EquippedSlotTypes.RIGHT_HAND);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);
        _event.unsubscribe(Event.PLAYER_DIED, receivePlayerDiedEvent, this);
    }

    function _tostring(){
        return ::wrapToString(::PlayerStats, "PlayerStats");
    }

    function setSaveData(data){
        mCurrentData_ = data;
    }
    function getSaveData(){
        return mCurrentData_;
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
            "health": health,
            "percentage": mPlayerCombatStats.getHealthPercentage()
        };
        //mPlayerEntry_.notifyNewHealth(newHealth, percentage);
        _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);

        if(mPlayerCombatStats.mDead){
            _event.transmit(Event.PLAYER_DIED, null);
        }
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

    function getEquippedItem(slot){
        return mPlayerCombatStats.mEquippedItems.getEquippedItem(slot);
    }

    function getPlayerHealth(){
        return mPlayerCombatStats.mHealth;
    }
    function getPlayerHealthPercentage(){
        return mPlayerCombatStats.getHealthPercentage();
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
    function equipChanged_(){
        _event.transmit(Event.PLAYER_EQUIP_CHANGED, mPlayerCombatStats.mEquippedItems);
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