::PlacedItem <- class{

    mMesh = null;
    mScale = 0.4;
    mPosOffset = null;

    constructor(mesh, scale, posOffset=null){
        mMesh = mesh;
        mScale = scale;
        mPosOffset = posOffset;
    }

}