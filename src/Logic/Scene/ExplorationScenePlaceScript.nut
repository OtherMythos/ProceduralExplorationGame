
function receivePlayerEntered(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        //print("Entered place: " + ::Places[id].getName());
        ::Base.mExplorationLogic.notifyPlaceEnterState(id, true);
    }
    else if(type == _COLLISION_LEAVE){
        //print("Left place");
        ::Base.mExplorationLogic.notifyPlaceEnterState(id, false);
    }
}