::PlacedItem <- class{

    mMesh = null;
    mScale = 0.4;
    mPosOffset = null;
    mCollisionRadius = null;

    constructor(mesh, scale, posOffset=null, collisionRadius=null){
        mMesh = mesh;
        mScale = scale;
        mPosOffset = posOffset;
        mCollisionRadius = collisionRadius;
    }

}