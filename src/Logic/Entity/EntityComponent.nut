::EntityManager.Component <- class{
    eid = 0;
    constructor(){

    }
}

::EntityManager.Components <- array(EntityComponents.MAX);

::EntityManager.Components[EntityComponents.COLLISION_POINT] = class extends ::EntityManager.Component{

    mPoint = null;
    mCreator = null;

    constructor(point, creator){
        mPoint = point;
        mCreator = creator;
    }

};
::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO] = class extends ::EntityManager.Component{

    mPointFirst = null;
    mPointSecond = null;
    mCreatorFirst = null;
    mCreatorSecond = null;

    constructor(first, second, creatorFirst, creatorSecond){
        mPointFirst = first;
        mPointSecond = second;
        mCreatorFirst = creatorFirst;
        mCreatorSecond = creatorSecond;
    }

};

::EntityManager.Components[EntityComponents.COLLISION_POINT_THREE] = class extends ::EntityManager.Component{

    mPointFirst = null;
    mPointSecond = null;
    mPointThird = null;
    mCreatorFirst = null;
    mCreatorSecond = null;
    mCreatorThird = null;

    constructor(first, second, third, creatorFirst, creatorSecond, creatorThird){
        mPointFirst = first;
        mPointSecond = second;
        mPointThird = third;
        mCreatorFirst = creatorFirst;
        mCreatorSecond = creatorSecond;
        mCreatorThird = creatorThird;
    }

};

::EntityManager.Components[EntityComponents.COLLISION_POINT_FOUR] = class extends ::EntityManager.Component{

    mPointFirst = null;
    mPointSecond = null;
    mPointThird = null;
    mPointFourth = null;
    mCreatorFirst = null;
    mCreatorSecond = null;
    mCreatorThird = null;
    mCreatorFourth = null;

    constructor(first, second, third, fourth, creatorFirst, creatorSecond, creatorThird, creatorFourth){
        mPointFirst = first;
        mPointSecond = second;
        mPointThird = third;
        mPointFourth = fourth;
        mCreatorFirst = creatorFirst;
        mCreatorSecond = creatorSecond;
        mCreatorThird = creatorThird;
        mCreatorFourth = creatorFourth;
    }

};

::EntityManager.Components[EntityComponents.COLLISION_POINT_FIVE] = class extends ::EntityManager.Component{

    mPointFirst = null;
    mPointSecond = null;
    mPointThird = null;
    mPointFourth = null;
    mPointFifth = null;
    mCreatorFirst = null;
    mCreatorSecond = null;
    mCreatorThird = null;
    mCreatorFourth = null;
    mCreatorFifth = null;

    constructor(first, second, third, fourth, fifth, creatorFirst, creatorSecond, creatorThird, creatorFourth, creatorFifth){
        mPointFirst = first;
        mPointSecond = second;
        mPointThird = third;
        mPointFourth = fourth;
        mPointFifth = fifth;
        mCreatorFirst = creatorFirst;
        mCreatorSecond = creatorSecond;
        mCreatorThird = creatorThird;
        mCreatorFourth = creatorFourth;
        mCreatorFifth = creatorFifth;
    }

};

::EntityManager.Components[EntityComponents.SCENE_NODE] = class extends ::EntityManager.Component{

    mNode = null;
    mDestroyOnDestruction = false;

    constructor(node, destroyOnDestruction=false){
        mNode = node;
        mDestroyOnDestruction = destroyOnDestruction;
    }

};

::EntityManager.Components[EntityComponents.LIFETIME] = class extends ::EntityManager.Component{

    mLifetime = 100;
    mLifetimeTotal = 100;

    constructor(lifetime){
        mLifetime = lifetime;
        mLifetimeTotal = lifetime;
    }

    function refresh(){
        mLifetime = mLifetimeTotal;
    }

};

::EntityManager.Components[EntityComponents.ANIMATION] = class extends ::EntityManager.Component{

    mAnim = null;

    constructor(anim){
        mAnim = anim;
    }

};

::EntityManager.Components[EntityComponents.BILLBOARD] = class extends ::EntityManager.Component{

    mBillboard = null;

    constructor(billboard){
        mBillboard = billboard;
    }

};

::EntityManager.Components[EntityComponents.SPOKEN_TEXT] = class extends ::EntityManager.Component{

    mBillboardIdx = null;
    mBillboard = null;
    mSceneNode = null;
    mYOffset = 0;
    mLifetime = 0;

    constructor(billboardIdx, billboard, sceneNode=null, yOffset=0, lifetime=100){
        mBillboardIdx = billboardIdx;
        mBillboard = billboard;
        mSceneNode = sceneNode;
        mYOffset = yOffset;
        mLifetime = lifetime;
    }

};

::EntityManager.Components[EntityComponents.HEALTH] = class extends ::EntityManager.Component{

    mHealth = 1;
    mMaxHealth = 1;

    constructor(health, maxHealth=null){
        mHealth = health;
        if(maxHealth != null){
            mMaxHealth = maxHealth;
        }else{
            mMaxHealth = health;
        }
    }

};

::EntityManager.Components[EntityComponents.SCRIPT] = class extends ::EntityManager.Component{

    mScript = null;

    constructor(script){
        mScript = script;
    }

};

::EntityManager.Components[EntityComponents.SPOILS] = class extends ::EntityManager.Component{

    mType = SpoilsComponentType.PERCENTAGE;
    //The meaning of these values changes depending on what type of spoil will be dropped.
    mFirst = null;
    mSecond = null;
    mThird = null;
    mActuateReason = null;

    constructor(spoilsType, first, second=null, third=null, actuateReason=null){
        mType = spoilsType;
        mFirst = first;
        mSecond = second;
        mThird = third;
        mActuateReason = actuateReason;
    }

};

::EntityManager.Components[EntityComponents.PROXIMITY] = class extends ::EntityManager.Component{

    mType = ProximityComponentType.PLAYER;
    mDistance = null;
    mCallback = null;

    constructor(proximityType=ProximityComponentType.PLAYER, callback=null){
        mType = proximityType;
        mCallback = callback;
    }

};

::EntityManager.Components[EntityComponents.DATABLOCK] = class extends ::EntityManager.Component{

    mDatablock = null;
    mDiffuseModifiers = null;
    mDiffuseOverride = null;
    mDiffuseOverrideStrength = 0;

    constructor(datablock){
        mDatablock = datablock;
    }

    function clearDiffuseModifier(){
        if(mDiffuseModifiers != null){
            mDiffuseModifiers.clear();
        }
        refreshDiffuseModifiers();
    }

    function applyDiffuseModifier(diffuse){
        if(mDiffuseModifiers == null){
            mDiffuseModifiers = [];
        }
        mDiffuseModifiers.append(diffuse);
    }

    function refreshDiffuseModifiers(){
        if(mDiffuseModifiers == null){
            refreshDiffuseModifiers_(1, 1, 1);
            return;
        }

        if(mDiffuseModifiers.len() == 0){
            refreshDiffuseModifiers_(1, 1, 1);
        }else{
            local finalDiffuse = Vec3();
            foreach(i in mDiffuseModifiers){
                finalDiffuse += i;
            }
            local d = finalDiffuse / mDiffuseModifiers.len();
            refreshDiffuseModifiers_(d.x, d.y, d.z);
        }
    }

    function refreshDiffuseModifiers_(r, g, b){
        if(mDiffuseOverride != null){
            local final = mix(Vec3(r, g, b), mDiffuseOverride, mDiffuseOverrideStrength);
            mDatablock.setDiffuse(final.x, final.y, final.z);
        }else{
            mDatablock.setDiffuse(r, g, b);
        }
    }

};

::EntityManager.Components[EntityComponents.DIALOG] = class extends ::EntityManager.Component{

    mDialogPath = null;
    mInitialBlock = null;

    constructor(dialogPath, initialBlock){
        mDialogPath = dialogPath;
        mInitialBlock = initialBlock;
    }

};

::EntityManager.Components[EntityComponents.TRAVERSABLE_TERRAIN] = class extends ::EntityManager.Component{

    mTraversableTerrain = null;

    constructor(traversableTerrain){
        mTraversableTerrain = traversableTerrain;
    }

};

::EntityManager.Components[EntityComponents.COLLISION_DETECTION] = class extends ::EntityManager.Component{

    mRadius = false;
    mHash = 0xFF;
    mIgnorePoint = null;

    constructor(radius, hash=0xFF, ignorePoint=null){
        mRadius = radius;
        mHash = hash;
        mIgnorePoint = ignorePoint;
    }

};

::EntityManager.Components[EntityComponents.INVENTORY_ITEMS] = class extends ::EntityManager.Component{

    mItems = null;
    mWidth = 0
    mHeight = 0

    constructor(items, width, height){
        mItems = items;
        mWidth = width;
        mHeight = height;
    }

};

::EntityManager.Components[EntityComponents.MOVEMENT] = class extends ::EntityManager.Component{

    mDirection = null;

    constructor(dir){
        mDirection = dir;
    }

};

::EntityManager.Components[EntityComponents.STATUS_AFFLICTION] = class extends ::EntityManager.Component{

    StatusAffliction = class{
        mAffliction = null;
        mTime = 0;
        mLifetime = 100;
    }

    mAfflictions = null;

    constructor(){
        mAfflictions = [];
    }

};

::EntityManager.Components[EntityComponents.GIZMO] = class extends ::EntityManager.Component{

    mGizmo = null;

    constructor(){
        mGizmo = array(ExplorationGizmos.MAX, null);
    }

};

::EntityManager.Components[EntityComponents.DATABLOCK_ANIMATOR] = class extends ::EntityManager.Component{

    mAnim = 0.0;

    constructor(){
    }

};

::EntityManager.Components[EntityComponents.COMPASS_INDICATOR] = class extends ::EntityManager.Component{

    mPoint = null;
    mCreator = null;
    mType = null;

    constructor(point, creator, type, eid){
        mPoint = point;
        mCreator = creator;
        mType = type;
        mCreator.setUserValue(mPoint, eid);
    }

};

::EntityManager.Components[EntityComponents.MOVEMENT_PARTICLES] = class extends ::EntityManager.Component{

    mParticleSystem = null;
    mPositionChangedThisFrame = false;

    constructor(particleSystem){
        mParticleSystem = particleSystem;
    }

};

::EntityManager.Components[EntityComponents.POSITION_LIMITER] = class extends ::EntityManager.Component{

    mCentre = null;
    mRadius = 0;

    constructor(centre, radius){
        mCentre = centre;
        mRadius = radius;
    }

};