//Items define the name and descriptions, equippables define information about how the item is equipped in a shareable format.

function regularSwordBaseAttack(p, entry, pos){
    if(p % 5 == 0){
        local attackValue = entry.mCombatData_.mEquippedItems.mEquippedStats.getStatType(StatType.ATTACK);

        ::Base.mExplorationLogic.mCurrentWorld_.performLocalMove(entry, ::Combat.CombatMove(1));
    }
}

function regularTwoHandedBaseAttack(p, entry, pos){
    if(p == 52){
        ::Base.mExplorationLogic.mCurrentWorld_.mProjectileManager_.spawnProjectile(ProjectileId.AREA, pos, ::Vec3_ZERO, ::Combat.CombatMove(10), entry.getTargetCollisionWorld());
    }
}


enum EquippableId{
    NONE,

    REGULAR_SWORD,
    REGULAR_SHIELD,
    REGULAR_TWO_HANDED_SWORD,

    MAX
};

enum EquippableCharacteristics{
    NONE = 0x0,
    TWO_HANDED = 0x1
};

::EquippableDef <- class{

    mEquippedSlot_ = EquippedSlotTypes.NONE;
    mEquippableCharacteristics_ = null;
    mAttackFunction_ = null;
    mTotalFrames_ = 0;
    mAttackAnim_ = null;

    constructor(equippedSlot, equippableCharacteristics, attackFunction, totalFrames, attackAnim){
        mEquippedSlot_ = equippedSlot;
        mEquippableCharacteristics_ = equippableCharacteristics;
        mAttackFunction_ = attackFunction;
        mTotalFrames_ = totalFrames;
        mAttackAnim_ = attackAnim;
    }

    function getEquippedSlot() { return mEquippedSlot_; }
    function getTotalFrames() { return mEquippedSlot_; }
    function getEquippableCharacteristics() { return mEquippableCharacteristics_; }

    function _tostring() {
        return ::wrapToString(::EquippableDef, "EquippableDef");
    }
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
    function getEquippableAttackAnim(){
        return mEquippable.mAttackAnim_;
    }
}

::Equippables <- array(EquippableId.MAX, null);

//-------------------------------
::Equippables[EquippableId.NONE] = EquippableDef(EquippedSlotTypes.NONE, EquippableCharacteristics.NONE, null, 0, CharacterModelAnimId.NONE);

::Equippables[EquippableId.REGULAR_SWORD] = EquippableDef(EquippedSlotTypes.HAND, EquippableCharacteristics.NONE, regularSwordBaseAttack, 20, CharacterModelAnimId.REGULAR_SWORD_SWING);
::Equippables[EquippableId.REGULAR_SHIELD] = EquippableDef(EquippedSlotTypes.HAND, EquippableCharacteristics.NONE, regularSwordBaseAttack, 20, CharacterModelAnimId.REGULAR_SWORD_SWING);
::Equippables[EquippableId.REGULAR_TWO_HANDED_SWORD] = EquippableDef(EquippedSlotTypes.HAND, EquippableCharacteristics.TWO_HANDED, regularTwoHandedBaseAttack, 80, CharacterModelAnimId.REGULAR_TWO_HANDED_SWORD_SWING);
//-------------------------------