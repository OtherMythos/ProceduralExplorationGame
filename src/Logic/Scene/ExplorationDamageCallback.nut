function baseDamage(id, type, internalId, sender, receiver){
    if(type != _COLLISION_ENTER) return;

    _applyDamage(receiver, 5);
}

::_applyDamage <- function(entity, damage){
    if(!entity.valid()) return;
    print("Applying damage " + damage);
    local newHealth = _component.user[Component.HEALTH].get(entity, 0) - damage;
    _component.user[Component.HEALTH].set(entity, 0, newHealth);
    print("new health " + newHealth);

    local billboardIdx = -1;
    try{
        billboardIdx = _component.user[Component.MISC].get(entity, 0);
    }catch(e){ }


    if(newHealth <= 0){
        if(billboardIdx >= 0) ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(billboardIdx);

        _entity.destroy(entity);
        return;
    }

    if(billboardIdx >= 0){
        //Check if this entity has a scene node which might have a health bar.
        //TODO clear up this entire thing.
        local maxHealth = _component.user[Component.HEALTH].get(entity, 1);
        local newPercentage = newHealth.tofloat() / maxHealth.tofloat();
        ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.updateHealth(billboardIdx, newPercentage);
    }
}