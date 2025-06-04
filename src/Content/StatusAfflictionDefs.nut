::StatusAfflictions <- array(StatusAfflictionType.MAX, null);

::StatusAfflictions[StatusAfflictionType.ON_FIRE] = StatusAffliction(Vec3(1, 0.2, 0.2), ExplorationGizmos.STATUS_EFFECT_FIRE);
::StatusAfflictions[StatusAfflictionType.FROZEN] = StatusAffliction(Vec3(0.2, 0.2, 1), ExplorationGizmos.STATUS_EFFECT_FROZEN);