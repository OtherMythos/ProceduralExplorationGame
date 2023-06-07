//Items define the name and descriptions, equippables define information about how the item is equipped in a shareable format.

function regularSwordBaseAttack(p, model, pos){
    print("Regular sword attack " + p);

    if(p == 0){
        model.startAnimation(CharacterModelAnimId.REGULAR_SWORD_SWING);
    }

    if(p == 15){
        ::Base.mExplorationLogic.mProjectileManager_.spawnProjectile(ProjectileId.AREA, pos, Vec3(), _COLLISION_ENEMY);
    }

    if(p == 20){
        model.stopAnimation(CharacterModelAnimId.REGULAR_SWORD_SWING);
    }
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
    mModel_ = null;
    constructor(equippable, model){
        mEquippable = equippable;
        mModel_ = model;
    }
    function update(pos){
        if(mCurrentFrame_ > mEquippable.mTotalFrames_) return false;
        mEquippable.mAttackFunction_(mCurrentFrame_, mModel_, pos);
        mCurrentFrame_++;

        return true;
    }
}

::Equippables <- array(EquippableId.MAX, null);

//-------------------------------
::Equippables[EquippableId.NONE] = EquippableDef(EquippedSlotTypes.NONE, null, 0);

::Equippables[EquippableId.REGULAR_SWORD] = EquippableDef(EquippedSlotTypes.SWORD, regularSwordBaseAttack, 20);
//-------------------------------