::PlayerStats <- class{

    mPlayerAchievements_ = null;
    mPlacesVisited_ = null;
    mLeanPlacesVisited_ = null;

    mPlayerCombatStats = null;

    mPlayerCurrentEXP_ = 0;

    constructor(){
        _event.subscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);

        mPlayerAchievements_ = {};
        mPlacesVisited_ = array(PlaceId.MAX, false);
        mLeanPlacesVisited_ = [];

        mPlayerCombatStats = ::Combat.CombatStats(Enemy.NONE, 100);
    }

    function alterPlayerHealth(amount){
        mPlayerCombatStats.alterHealth(amount);
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

    function equipItem(item, slot){
        print("Equipping player item: " + item.getName())
        mPlayerCombatStats.mEquippedItems.setEquipped(item, slot);
    }

    function getLevelForEXP_(exp){
        foreach(c,i in EXP_LEVELS){
            if(exp < i) return c-1;
        }
        return EXP_LEVELS.len();
    }
    function getPercentageForLevel_(level, exp){
        local currentLevel = EXP_LEVELS[level];
        assert(exp >= currentLevel);
        if(currentLevel >= EXP_LEVELS.len()-1) return EXP_LEVELS.len();

        local diff = EXP_LEVELS[level+1] - currentLevel;
        local delta = exp-currentLevel;
        local percentage = delta.tofloat() / diff.tofloat();

        return percentage;
    }
    function addEXP(exp){
        local prevEXP = mPlayerCurrentEXP_;
        local prevLevel = getLevelForEXP_(prevEXP);
        mPlayerCurrentEXP_ += exp;
        local newLevel = getLevelForEXP_(prevEXP);

        local percentage = getPercentageForLevel_(newLevel, mPlayerCurrentEXP_);
        local startPercentage = getPercentageForLevel_(prevLevel, prevEXP);
        local data = {
            "startLevel": prevLevel,
            "endLevel": newLevel,
            "startPercentage": startPercentage,
            "endPercentage": percentage,
        }

        return data;
    }


    EXP_LEVELS = [
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