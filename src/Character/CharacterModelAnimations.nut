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