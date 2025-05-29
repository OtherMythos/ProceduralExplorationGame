::CharacterModelAnimDef <- class{
    mName = null;
    mUsedNodes = null;
    mFile = null;
    mFilePath = null;

    constructor(name, filePath, usedNodes){
        mName = name;
        mFilePath = filePath;
        mUsedNodes = usedNodes;
        mFile = filePath;
    }
};
::CharacterModelAnims <- array(CharacterModelAnimId.MAX, null);

::CharacterModelAnims[CharacterModelAnimId.NONE] = ::CharacterModelAnimDef(null, null, []);

::CharacterModelAnims[CharacterModelAnimId.BASE_LEGS_WALK] = ::CharacterModelAnimDef("BaseFeetWalk", "baseCharacterAnimation.xml", [CharacterModelPartType.LEFT_FOOT, CharacterModelPartType.RIGHT_FOOT]);
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_WALK] = ::CharacterModelAnimDef("BaseUpperWalk", "baseCharacterAnimation.xml", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.BASE_ARMS_SWIM] = ::CharacterModelAnimDef("BaseUpperSwim", "baseCharacterAnimation.xml", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.REGULAR_SWORD_SWING] = ::CharacterModelAnimDef("RegularSwordSwing", "EquippableAnimation.xml", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
::CharacterModelAnims[CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING] = ::CharacterModelAnimDef("RegularTwoHandedSwordSwing", "EquippableAnimation.xml", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);

::CharacterModelAnims[CharacterModelAnimId.SQUID_WALK] = ::CharacterModelAnimDef("SquidWalk", "SquidAnimation.xml", [CharacterModelPartType.LEFT_HAND, CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.BODY]);
::CharacterModelAnims[CharacterModelAnimId.CRAB_WALK] = ::CharacterModelAnimDef("CrabWalk", "crabAnimation.xml", [CharacterModelPartType.LEFT_MISC_1, CharacterModelPartType.LEFT_MISC_2, CharacterModelPartType.RIGHT_MISC_1, CharacterModelPartType.RIGHT_MISC_2]);
::CharacterModelAnims[CharacterModelAnimId.FOREST_GUARDIAN_WALK] = ::CharacterModelAnimDef("ForestGuardianFeetWalk", "forestGuardianAnimation.xml", [CharacterModelPartType.LEFT_FOOT, CharacterModelPartType.RIGHT_FOOT]);
::CharacterModelAnims[CharacterModelAnimId.FOREST_GUARDIAN_ARMS_WALK] = ::CharacterModelAnimDef("ForestGuardianUpperWalk", "forestGuardianAnimation.xml", [CharacterModelPartType.RIGHT_HAND, CharacterModelPartType.LEFT_HAND]);
