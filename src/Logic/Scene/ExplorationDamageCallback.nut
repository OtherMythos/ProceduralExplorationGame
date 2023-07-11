function baseDamage(id, type, internalId, sender, receiver){
    if(type != _COLLISION_ENTER) return;

    local active = ::Base.mExplorationLogic.mProjectileManager_.mActiveProjectiles_;
    if(!active.rawin(id)) return;
    local projData = active[id];
    local damage = projData.mCombatMove_.getDamage();

    _applyDamage(receiver, damage);
}

::_applyDamage <- function(entity, damage){
    if(!entity.valid()) return;
    print("Applying damage " + damage);
    local newHealth = _component.user[Component.HEALTH].get(entity, 0) - damage;
    _component.user[Component.HEALTH].set(entity, 0, newHealth);
    print("new health " + newHealth);

    ::Base.mExplorationLogic.mCurrentWorld_.notifyNewEntityHealth(entity, newHealth);

    if(newHealth <= 0){
        _entity.destroy(entity);
    }
}