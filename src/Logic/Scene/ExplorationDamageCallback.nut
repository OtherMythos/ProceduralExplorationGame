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

    ::Base.mExplorationLogic.notifyNewEntityHealth(entity, newHealth);

    if(newHealth <= 0){
        _entity.destroy(entity);
    }
}