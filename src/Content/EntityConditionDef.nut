::EntityConditionDef <- class{
    mDiffuse = null;
    mGizmo = null;
    mDamagePerTick = 0;
    constructor(diffuse, gizmo, damagePerTick=0){
        mDiffuse = diffuse;
        mGizmo = gizmo;
        mDamagePerTick = damagePerTick;
    }
}
