local fireAreaAttack = function(frame){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    local fireArea = ::Combat.CombatMove(10);
    fireArea.mEntityCondition = EntityConditionType.ON_FIRE;
    fireArea.mEntityConditionLifetime = 100;
    currentWorld.mProjectileManager_.spawnProjectile(ProjectileId.FIRE_AREA, currentWorld.getPlayerPosition(), null, fireArea, _COLLISION_ENEMY);
    return true;
}

local levitatePerform = function(frame){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    currentWorld.applyEntityCondition(currentWorld.getPlayerEID(), EntityConditionType.LEVITATING, 360);
    return true;
}


::SpecialMoves <- array(SpecialMoveId.MAX, null);

::SpecialMoves[SpecialMoveId.NONE] = SpecialMoveDef("None");
::SpecialMoves[SpecialMoveId.FIREBALL] = SpecialMoveDef("Fireball", 50, ProjectileId.FIREBALL);
::SpecialMoves[SpecialMoveId.FIRE_AREA] = SpecialMoveDef("Fire Area", 50, ProjectileId.FIRE_AREA, fireAreaAttack);
::SpecialMoves[SpecialMoveId.LEVITATE] = SpecialMoveDef("Levitate", 150, null, levitatePerform);
