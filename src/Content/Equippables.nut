//Items define the name and descriptions, equippables define information about how the item is equipped in a shareable format.

function regularSwordBaseAttack(p, entry, pos){
    if(p == 0){
        entry.getModel().startAnimation(CharacterModelAnimId.REGULAR_SWORD_SWING);
    }
    else if(p == 15){
        ::Base.mExplorationLogic.mProjectileManager_.spawnProjectile(ProjectileId.AREA, pos, Vec3(), ::Combat.CombatMove(3), entry.getTargetCollisionWorld());
    }
    else if(p == 20){
        entry.getModel().stopAnimation(CharacterModelAnimId.REGULAR_SWORD_SWING);
    }
}

function regularTwoHandedBaseAttack(p, entry, pos){
    if(p == 0){
        entry.getModel().startAnimation(CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING);
    }
    else if(p == 52){
        ::Base.mExplorationLogic.mProjectileManager_.spawnProjectile(ProjectileId.AREA, pos, Vec3(), ::Combat.CombatMove(10), entry.getTargetCollisionWorld());
    }
    else if(p == 80){
        entry.getModel().stopAnimation(CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING);
    }
}


enum EquippableId{
    NONE,

    REGULAR_SWORD,
    REGULAR_SHIELD,
    REGULAR_TWO_HANDED_SWORD,

    MAX
};

::EquippableDef <- class{

    mEquippedSlot_ = EquippedSlotTypes.NONE;
    mAttackFunction_ = null;
    mTotalFrames_ = 0;

    constructor(equippedSlot, attackFunction, totalFrames){
        mEquippedSlot_ = equippedSlot;
        mAttackFunction_ = attackFunction;
        mTotalFrames_ = totalFrames;
    }

    function getEquippedSlot() { return mEquippedSlot_; }
    function getTotalFrames() { return mEquippedSlot_; }

    function _tostring() { return "EquippableDef"; }
}

::EquippablePerformance <- class{
    mEquippable = null;
    mCurrentFrame_ = 0;
    mEntityEntry_ = null;
    constructor(equippable, entityEntry){
        mEquippable = equippable;
        mEntityEntry_ = entityEntry;
    }
    function update(pos){
        if(mCurrentFrame_ > mEquippable.mTotalFrames_) return false;
        mEquippable.mAttackFunction_(mCurrentFrame_, mEntityEntry_, pos);
        mCurrentFrame_++;

        return true;
    }
}

::Equippables <- array(EquippableId.MAX, null);

//-------------------------------
::Equippables[EquippableId.NONE] = EquippableDef(EquippedSlotTypes.NONE, null, 0);

::Equippables[EquippableId.REGULAR_SWORD] = EquippableDef(EquippedSlotTypes.HAND, regularSwordBaseAttack, 20);
::Equippables[EquippableId.REGULAR_SHIELD] = EquippableDef(EquippedSlotTypes.HAND, regularSwordBaseAttack, 20);
::Equippables[EquippableId.REGULAR_TWO_HANDED_SWORD] = EquippableDef(EquippedSlotTypes.HAND, regularTwoHandedBaseAttack, 80);
//-------------------------------