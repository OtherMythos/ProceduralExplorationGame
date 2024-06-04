::CharacterModelAnimDef <- class{
    mName = null;
    mUsedNodes = null;

    constructor(name, usedNodes){
        mName = name;
        mUsedNodes = usedNodes;
    }
};
::CharacterModelAnims <- array(CharacterModelAnimId.MAX, null);

::CharacterModelAnims[CharacterModelAnimId.BASE_LEGS_WALK] = ::CharacterModelAnimDef("BaseFeetWalk", [CharacterModelPartType.LEFT_FOOT, CharacterModelPartType.RIGHT_FOOT]);
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_WALK] = ::CharacterModelAnimDef("BaseUpperWalk", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_SWIM] = ::CharacterModelAnimDef("BaseUpperSwim", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.REGULAR_SWORD_SWING] = ::CharacterModelAnimDef("RegularSwordSwing", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING] = ::CharacterModelAnimDef("RegularTwoHandedSwordSwing", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.SQUID_WALK] = ::CharacterModelAnimDef("SquidWalk", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.BODY]);
::CharacterModelAnims[CharacterModelAnimId.CRAB_WALK] = ::CharacterModelAnimDef("CrabWalk", [CharacterModelPartType.LEFT_MISC_1, CharacterModelPartType.LEFT_MISC_2, CharacterModelPartType.RIGHT_MISC_1, CharacterModelPartType.RIGHT_MISC_2]);
::CharacterModelAnims[CharacterModelAnimId.FOREST_GUARDIAN_WALK] = ::CharacterModelAnimDef("ForestGuardianFeetWalk", [CharacterModelPartType.LEFT_FOOT, CharacterModelPartType.RIGHT_FOOT]);
::CharacterModelAnims[CharacterModelAnimId.FOREST_GUARDIAN_ARMS_WALK] = ::CharacterModelAnimDef("ForestGuardianUpperWalk", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
