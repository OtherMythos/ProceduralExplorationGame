::EntityManager.Component <- class{
    eid = 0;
    constructor(){

    }
}

::EntityManager.Components <- array(EntityComponents.MAX);

::EntityManager.Components[EntityComponents.COLLISION_POINT] = class extends ::EntityManager.Component{

    mPoint = null;

    constructor(point){
        mPoint = point;
    }

};