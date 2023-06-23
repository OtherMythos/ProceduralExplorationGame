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
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_WALK] = ::CharacterModelAnimDef("BaseUpperWalk", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_SWIM] = ::CharacterModelAnimDef("BaseUpperSwim", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.REGULAR_SWORD_SWING] = ::CharacterModelAnimDef("RegularSwordSwing", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING] = ::CharacterModelAnimDef("RegularTwoHandedSwordSwing", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.SQUID_WALK] = ::CharacterModelAnimDef("SquidWalk", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.BODY]);
