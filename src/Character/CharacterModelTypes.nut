//NOTE might not use the children system depending how animating in blender ends up working out.
local Entry = class{
    mMesh = null;
    mChildren = null;
    mPos = null;
    mScale = null;
    mEquipType = null;
    constructor(mesh=null, children=null, pos=null, scale=null, equipType=null){
        mMesh = mesh;
        mChildren = children;
        mPos = pos;
        mScale = scale;
        mEquipType = equipType;
    }
};

local ModelType = class{
    mAnimFile = null;
    mNodes = null;
    constructor(anim, nodes){
        mAnimFile = ::CharacterGeneratorPrefix + anim;

        mNodes = nodes;
    }
};

::CharacterGenerator.mModelTypes_[CharacterModelType.HUMANOID] = ModelType("assets/characterAnimations/humanoidAnimation.xml",
    [
    //Head
    Entry(
        "playerHead.mesh", null, Vec3(0, 10, 0), Vec3(1, 1, 1)
    ),
    //Body
    Entry(
        "playerBody.mesh", null, Vec3(0, 3, 0), Vec3(0.9, 1, 0.9)
    ),

    Entry(//Left arm
        "playerArm.mesh",
        [Entry(null, null, null, Vec3(0.8, 0.8, 0.8), CharacterModelEquipNodeType.LEFT_HAND)]
        , Vec3(-8, 8, 0), Vec3(0.8, 0.8, 0.8)
    ),
    Entry(//Right arm
        "playerArm.mesh", null, Vec3(8, 8, 0), Vec3(0.8, 0.8, 0.8)
    ),

    Entry(//Left foot
        "playerFoot.mesh", null, Vec3(-1, 2, 0), Vec3(1, 1, 1)
    ),
    Entry(//Right foot
        "playerFoot.mesh", null, Vec3(4.5, 2, 0), Vec3(1, 1, 1)
    )
]
);