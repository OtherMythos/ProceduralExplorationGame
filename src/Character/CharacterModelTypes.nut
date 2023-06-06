//NOTE might not use the children system depending how animating in blender ends up working out.
local Entry = class{
    mMesh = null;
    mPart = CharacterModelPartType.NONE;
    mChildren = null;
    mPos = null;
    mScale = null;
    mEquipType = null;
    constructor(mesh=null, modelPart=CharacterModelPartType.NONE, children=null, pos=null, scale=null, equipType=null){
        mMesh = mesh;
        mPart = modelPart;
        mChildren = children;
        mPos = pos;
        mScale = scale;
        mEquipType = equipType;
    }
};

local ModelType = class{
    mAnimFile = null;
    mNodes = null;
    mNodeIds = null;
    constructor(anim, nodes){
        mAnimFile = ::CharacterGeneratorPrefix + anim;

        mNodes = nodes;

        //Resolve the node ids table upfront so it doesn't have to be stored in each model instance.
        mNodeIds = {};
        foreach(c,i in mNodes){
            assert(i.mPart != CharacterModelPartType.NONE);
            mNodeIds.rawset(i.mPart, c);
        }
    }
};

//TODO move this into a separate thing.
::CharacterGenerator.mModelTypes_[CharacterModelType.HUMANOID] = ModelType("assets/characterAnimations/baseAnimation.xml",
    [
        Entry(
            "playerHead.mesh", CharacterModelPartType.HEAD, null, Vec3(0, 10, 0), Vec3(1, 1, 1)
        ),
        Entry(
            "playerBody.mesh", CharacterModelPartType.BODY, null, Vec3(0, 3, 0), Vec3(0.9, 1, 0.9)
        ),

        Entry(
            "playerArm.mesh", CharacterModelPartType.LEFT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), CharacterModelEquipNodeType.LEFT_HAND)]
            , Vec3(-8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),
        Entry(
            "playerArm.mesh", CharacterModelPartType.RIGHT_HAND, null, Vec3(8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),

        Entry(
            "playerFoot.mesh", CharacterModelPartType.LEFT_FOOT, null, Vec3(-1, 2, 0), Vec3(1, 1, 1)
        ),
        Entry(
            "playerFoot.mesh", CharacterModelPartType.RIGHT_FOOT, null, Vec3(4.5, 2, 0), Vec3(1, 1, 1)
        )
    ]
);