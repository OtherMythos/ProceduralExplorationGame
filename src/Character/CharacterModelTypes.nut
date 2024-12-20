//NOTE might not use the children system depending how animating in blender ends up working out.
local Entry = class{
    mMesh = null;
    mPart = CharacterModelPartType.NONE;
    mChildren = null;
    mPos = null;
    mScale = null;
    mOrientation = null;
    mEquipType = null;
    constructor(mesh=null, modelPart=CharacterModelPartType.NONE, children=null, pos=null, scale=null, orientation=null, equipType=null){
        mMesh = mesh;
        mPart = modelPart;
        mChildren = children;
        mPos = pos;
        mScale = scale;
        mOrientation = orientation;
        mEquipType = equipType;
    }
};

local ModelType = class{
    mAnimFile = null;
    mNodes = null;
    mNodeIds = null;
    mBaseAnims = null;
    constructor(anim, nodes, baseAnims){
        mAnimFile = ::CharacterGeneratorPrefix + anim;

        mNodes = nodes;
        mBaseAnims = baseAnims;

        //Resolve the node ids table upfront so it doesn't have to be stored in each model instance.
        mNodeIds = {};
        foreach(c,i in mNodes){
            assert(i.mPart != CharacterModelPartType.NONE);
            mNodeIds.rawset(i.mPart, c);
        }
    }
};

::ModelTypes <- array(CharacterModelType.MAX, null);

//TODO make it possible to assign orientation to nodes.
::ModelTypes[CharacterModelType.HUMANOID] = ModelType("build/assets/characterAnimations/baseAnimation.xml",
    [
        Entry(
            "playerHead.voxMesh", CharacterModelPartType.HEAD, null, Vec3(0, 10, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "playerBody.voxMesh", CharacterModelPartType.BODY,
            [Entry(null, CharacterModelPartType.NONE, null, Vec3(0, 2, -4), Vec3(0.6, 0.6, 0.6), null, CharacterModelEquipNodeType.WEAPON_STORE)]
            , Vec3(0, 3, 0), Vec3(0.9, 1, 0.9)
        ),

        Entry(
            "playerArm.voxMesh", CharacterModelPartType.LEFT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.LEFT_HAND)]
            , Vec3(8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),
        Entry(
            "playerArm.voxMesh", CharacterModelPartType.RIGHT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.RIGHT_HAND)]
            , Vec3(-8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),

        Entry(
            "playerFoot.voxMesh", CharacterModelPartType.LEFT_FOOT, null, Vec3(-1, 2, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "playerFoot.voxMesh", CharacterModelPartType.RIGHT_FOOT, null, Vec3(4.5, 2, 0), ::Vec3_UNIT_SCALE
        )
    ],
    [CharacterModelAnimId.BASE_ARMS_WALK, CharacterModelAnimId.BASE_LEGS_WALK, CharacterModelAnimId.BASE_ARMS_SWIM]
);
::ModelTypes[CharacterModelType.GOBLIN] = ModelType("build/assets/characterAnimations/baseAnimation.xml",
    [
        Entry(
            "goblinBody.voxMesh", CharacterModelPartType.BODY,
            [Entry(null, CharacterModelPartType.NONE, null, Vec3(0, 0, -2), Vec3(0.4, 0.4, 0.4), null, CharacterModelEquipNodeType.WEAPON_STORE)]
            , Vec3(0, 4, 0), Vec3(1.2, 1.2, 1.2)
        ),

        Entry(
            "goblinArm.voxMesh", CharacterModelPartType.LEFT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.4, 0.4, 0.4), null, CharacterModelEquipNodeType.LEFT_HAND)]
            , Vec3(8, 8, 0), Vec3(1.2, 1.2, 1.2)
        ),
        Entry(
            "goblinArm.voxMesh", CharacterModelPartType.RIGHT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.4, 0.4, 0.4), null, CharacterModelEquipNodeType.RIGHT_HAND)]
            , Vec3(-8, 8, 0), Vec3(1.2, 1.2, 1.2)
        ),

        Entry(
            "goblinFoot.voxMesh", CharacterModelPartType.LEFT_FOOT, null, Vec3(-1, 2, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "goblinFoot.voxMesh", CharacterModelPartType.RIGHT_FOOT, null, Vec3(4.5, 2, 0), ::Vec3_UNIT_SCALE
        )

    ],
    [CharacterModelAnimId.BASE_ARMS_WALK, CharacterModelAnimId.BASE_LEGS_WALK, CharacterModelAnimId.BASE_ARMS_SWIM]
);
::ModelTypes[CharacterModelType.SQUID] = ModelType("build/assets/characterAnimations/squidAnimation.xml",
    [
        Entry(
            "squidBody.voxMesh", CharacterModelPartType.BODY, null, Vec3(0, 0, 0), Vec3(1.0, 1.0, 1.0)
        ),
        Entry(
            "squidTentacle.voxMesh", CharacterModelPartType.LEFT_HAND, null, Vec3(8, 0, 0), Vec3(1.2, 1.2, 1.2)
        ),
        Entry(
            "squidTentacle.voxMesh", CharacterModelPartType.RIGHT_HAND, null, Vec3(-8, 0, 0), Vec3(1.2, 1.2, 1.2)
        )
    ],
    [CharacterModelAnimId.NONE, CharacterModelAnimId.SQUID_WALK, CharacterModelAnimId.SQUID_WALK]
);
::ModelTypes[CharacterModelType.CRAB] = ModelType("build/assets/characterAnimations/crabAnimation.xml",
    [
        Entry(
            "crabBody.voxMesh", CharacterModelPartType.BODY, null
        ),

        Entry(
            "crabFeetLeft.voxMesh", CharacterModelPartType.LEFT_MISC_1, null, Vec3(4, 1, 1.01)
        ),
        Entry(
            "crabFeetLeft.voxMesh", CharacterModelPartType.LEFT_MISC_2, null, Vec3(3, 1, 4.01)
        ),

        Entry(
            "crabFeetRight.voxMesh", CharacterModelPartType.RIGHT_MISC_1, null, Vec3(-6, 1, 1.01)
        ),
        Entry(
            "crabFeetRight.voxMesh", CharacterModelPartType.RIGHT_MISC_2, null, Vec3(-5, 1, 4.01)
        )
    ],
    [CharacterModelAnimId.NONE, CharacterModelAnimId.CRAB_WALK, CharacterModelAnimId.CRAB_WALK]
);
::ModelTypes[CharacterModelType.SKELETON] = ModelType("build/assets/characterAnimations/baseAnimation.xml",
    [
        Entry(
            "skeletonHead.voxMesh", CharacterModelPartType.HEAD, null, Vec3(0, 10, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "skeletonBody.voxMesh", CharacterModelPartType.BODY,
            [Entry(null, CharacterModelPartType.NONE, null, Vec3(0, 2, -4), Vec3(0.6, 0.6, 0.6), null, CharacterModelEquipNodeType.WEAPON_STORE)]
            , Vec3(0, 3, 0), Vec3(0.9, 1, 0.9)
        ),

        Entry(
            "skeletonArm.voxMesh", CharacterModelPartType.LEFT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.LEFT_HAND)]
            , Vec3(8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),
        Entry(
            "skeletonArm.voxMesh", CharacterModelPartType.RIGHT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.RIGHT_HAND)]
            , Vec3(-8, 8, 0), Vec3(0.8, 0.8, 0.8)
        ),

        Entry(
            "skeletonFoot.voxMesh", CharacterModelPartType.LEFT_FOOT, null, Vec3(-1, 2, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "skeletonFoot.voxMesh", CharacterModelPartType.RIGHT_FOOT, null, Vec3(4.5, 2, 0), ::Vec3_UNIT_SCALE
        )
    ],
    [CharacterModelAnimId.BASE_ARMS_WALK, CharacterModelAnimId.BASE_LEGS_WALK, CharacterModelAnimId.BASE_ARMS_SWIM]
);
::ModelTypes[CharacterModelType.FOREST_GUARDIAN] = ModelType("build/assets/characterAnimations/forestGuardianAnimation.xml",
    [
        Entry(
            "forestGuardianHead.voxMesh", CharacterModelPartType.HEAD, null, Vec3(0, 19, 1), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "forestGuardianBody.voxMesh", CharacterModelPartType.BODY,
            [Entry(null, CharacterModelPartType.NONE, null, Vec3(0, 5, -2), Vec3(0.6, 0.6, 0.6), null, CharacterModelEquipNodeType.WEAPON_STORE)]
            , Vec3(0, 6, 0)
        ),

        Entry(
            "forestGuardianArm.voxMesh", CharacterModelPartType.LEFT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.LEFT_HAND)]
            , Vec3(14, 17, 0), Vec3(0.8, 0.8, 0.8)
        ),
        Entry(
            "forestGuardianArm.voxMesh", CharacterModelPartType.RIGHT_HAND,
            [Entry(null, CharacterModelPartType.NONE, null, null, Vec3(0.8, 0.8, 0.8), null, CharacterModelEquipNodeType.RIGHT_HAND)]
            , Vec3(-14, 17, 0), Vec3(0.8, 0.8, 0.8)
        ),

        Entry(
            "forestGuardianFoot.voxMesh", CharacterModelPartType.LEFT_FOOT, null, Vec3(-1, 2, 0), ::Vec3_UNIT_SCALE
        ),
        Entry(
            "forestGuardianFoot.voxMesh", CharacterModelPartType.RIGHT_FOOT, null, Vec3(4.5, 2, 0), ::Vec3_UNIT_SCALE
        )
    ],
    [CharacterModelAnimId.FOREST_GUARDIAN_ARMS_WALK, CharacterModelAnimId.FOREST_GUARDIAN_WALK, CharacterModelAnimId.BASE_ARMS_SWIM]
);
::ModelTypes[CharacterModelType.BEE] = ModelType("build/assets/characterAnimations/forestGuardianAnimation.xml",
    [
        Entry(
            "bee.voxMesh", CharacterModelPartType.BODY,
            [
                //TODO when bitmask support is in place change weapon store to be left and right hand as well.
                Entry(null, CharacterModelPartType.NONE, null, ::Vec3_ZERO, ::Vec3_UNIT_SCALE, null, CharacterModelEquipNodeType.WEAPON_STORE)
            ]
            , Vec3(0, 6, 0), Vec3(0.75, 0.75, 0.75)
        )
    ],
    [CharacterModelAnimId.NONE, CharacterModelAnimId.NONE, CharacterModelAnimId.NONE]
);
::ModelTypes[CharacterModelType.DUST_MITE_WORKER] = ModelType("build/assets/characterAnimations/forestGuardianAnimation.xml",
    [
        Entry(
            "dustMiteWorker.voxMesh", CharacterModelPartType.BODY,
            [
                Entry(null, CharacterModelPartType.NONE, null, ::Vec3_ZERO, ::Vec3_UNIT_SCALE, null, CharacterModelEquipNodeType.WEAPON_STORE)
            ]
            , Vec3(0, 0, 0)
        ),
        Entry(
            "dustMiteWorkerLeftFoot.voxMesh", CharacterModelPartType.LEFT_MISC_1, null, Vec3(3, 1, 0)
        ),
        Entry(
            "dustMiteWorkerLeftFoot.voxMesh", CharacterModelPartType.LEFT_MISC_2, null, Vec3(3, 1, -3)
        ),
        Entry(
            "dustMiteWorkerLeftFoot.voxMesh", CharacterModelPartType.LEFT_MISC_3, null, Vec3(3, 1, -6)
        ),

        Entry(
            "dustMiteWorkerRightFoot.voxMesh", CharacterModelPartType.RIGHT_MISC_1, null, Vec3(-3, 1, 0)
        ),
        Entry(
            "dustMiteWorkerRightFoot.voxMesh", CharacterModelPartType.RIGHT_MISC_2, null, Vec3(-3, 1, -3)
        ),
        Entry(
            "dustMiteWorkerRightFoot.voxMesh", CharacterModelPartType.RIGHT_MISC_3, null, Vec3(-3, 1, -6)
        )
    ],
    [CharacterModelAnimId.NONE, CharacterModelAnimId.NONE, CharacterModelAnimId.NONE]
);