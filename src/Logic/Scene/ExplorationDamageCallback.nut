function baseDamage(id, type, internalId, sender, receiver){
    if(type != _COLLISION_ENTER) return;

    _applyDamage(null, 5);
}

function _applyDamage(entityId, damage){
    //::Base.mExplorationLogic.
    print("Applying 5 damage");
}
