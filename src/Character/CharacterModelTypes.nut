//NOTE might not use the children system depending how animating in blender ends up working out.
local Entry = class{
    mMesh = null;
    mChildren = null;
    mPos = null;
    mScale = null;
    constructor(mesh, children=null, pos=null, scale=null){
        mMesh = mesh;
        mChildren = children;
        mPos = pos;
        mScale = scale;
    }
};

::CharacterGenerator.mModelTypes_[CharacterModelType.HUMANOID] = [
    //Body
    Entry(
        "cube", null, Vec3(0, 2, 0), Vec3(1, 1, 1)
    ),

    Entry(//Left arm
        "cube", null, Vec3(-1, 0, 0), Vec3(0.5, 0.5, 0.5)
    ),
    Entry(//Right arm
        "cube", null, Vec3(1, 0, 0), Vec3(0.5, 0.5, 0.5)
    )
]