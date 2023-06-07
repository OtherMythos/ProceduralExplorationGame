//Items define the name and descriptions, equippables define information about how the item is equipped in a shareable format.

function regularSwordBaseAttack(p, pos){
    print("Regular sword attack " + p);

    ::Base.mExplorationLogic.mProjectileManager_.spawnProjectile(ProjectileId.AREA, pos, Vec3(), _COLLISION_ENEMY);
}



enum EquippableId{
    NONE,

    REGULAR_SWORD,

    MAX
};

::EquippableDef <- class{

    mEquippedSlot_ = EquippedSlotTypes.NONE;
    mAttackFunction_ = null;
    mTotalFrames_ = 0;

    constructor(equippedSlot, attackFunction, totalFrames){
        mEquippedSlot_ = EquippedSlotTypes.SWORD;
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
    constructor(equippable){
        mEquippable = equippable;
    }
    function update(pos){
        if(mCurrentFrame_ >= mEquippable.mTotalFrames_) return false;
        mEquippable.mAttackFunction_(mCurrentFrame_, pos);
        mCurrentFrame_++;

        return true;
    }
}

::Equippables <- array(EquippableId.MAX, null);

//-------------------------------
::Equippables[EquippableId.NONE] = EquippableDef(EquippedSlotTypes.NONE, null, 0);

::Equippables[EquippableId.REGULAR_SWORD] = EquippableDef(EquippedSlotTypes.SWORD, regularSwordBaseAttack, 10);
//-------------------------------