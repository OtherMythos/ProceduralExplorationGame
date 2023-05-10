
function destroyed(eid){
    print("Registered player death.");

    _event.transmit(Event.PLAYER_DIED, null);
}