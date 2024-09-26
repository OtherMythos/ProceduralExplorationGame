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

    constructor(lifetime){
        mLifetime = lifetime;
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

::EntityManager.Components[EntityComponents.HEALTH] = class extends ::EntityManager.Component{

    mHealth = 1;
    mMaxHealth = 1;

    constructor(health){
        mHealth = health;
        mMaxHealth = health;
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

    constructor(spoilsType, first, second=null, third=null){
        mType = spoilsType;
        mFirst = first;
        mSecond = second;
        mThird = third;
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

    constructor(datablock){
        mDatablock = datablock;
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