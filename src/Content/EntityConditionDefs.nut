::EntityConditions <- array(EntityConditionType.MAX, null);

::EntityConditions[EntityConditionType.ON_FIRE] = EntityConditionDef(Vec3(1, 0.2, 0.2), ExplorationGizmos.STATUS_EFFECT_FIRE, 1);
::EntityConditions[EntityConditionType.FROZEN] = EntityConditionDef(Vec3(0.2, 0.2, 1), ExplorationGizmos.STATUS_EFFECT_FROZEN, 1);
::EntityConditions[EntityConditionType.LEVITATING] = EntityConditionDef(null, null, 0);
