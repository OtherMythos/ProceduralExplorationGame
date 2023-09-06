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