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

::EntityManager.Components[EntityComponents.ANIMATION_COMPONENT] = class extends ::EntityManager.Component{

    mAnim = null;

    constructor(anim){
        mAnim = anim;
    }

};
