
function receivePlayerEntered(id, type, internal, sender, receiver){
    if(!sender.valid() || !receiver.valid()) return;

    local distance = sender.getPosition().distance(receiver.getPosition());
    if(distance >= 4) return;
    if(distance <= 0.8){
        ::Base.mExplorationLogic.notifyFoundEXPOrb();
        _entity.destroy(sender);
        return;
    }

    distance /= 4;

    local anim = sqrt(1 - pow(distance - 1, 2)) * 0.4;
    sender.moveTowards(receiver.getPosition(), anim);
}