::PlayerStats <- class{

    mPlayerAchievements_ = null;
    mPlacesVisited_ = null;
    mLeanPlacesVisited_ = null;

    mPlayerCombatStats = null;

    constructor(){
        _event.subscribe(Event.PLACE_VISITED, receivePlaceVisitedEvent, this);

        mPlayerAchievements_ = {};
        mPlacesVisited_ = array(Place.MAX, false);
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
        print("Equipping player item: " + ::Items[item].getName())
        mPlayerCombatStats.mEquippedItems.setEquipped(item, slot);
    }

};