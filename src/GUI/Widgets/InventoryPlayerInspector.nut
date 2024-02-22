::GuiWidgets.InventoryPlayerInspector <- class{

    mParentWin_ = null;
    mRenderPanel_ = null;
    mRenderManager_ = null;

    RenderManager = class{
        mDatablock_ = null;
        mCamera_ = null;
        mCompositorId_ = null;
        mCharacterModel_ = null;
        mRotX = 0;
        mModelAABB_ = null;
        constructor(){

        }

        function setup(parentPanel){
            local winSize = parentPanel.getSize();

            local compId = ::CompositorManager.createCompositorWorkspace("renderTexture50_60Workspace", winSize, CompositorSceneType.INVENTORY_PLAYER_INSPECTOR);
            mDatablock_ = ::CompositorManager.getDatablockForCompositor(compId);
            mCompositorId_ = compId;

            mCamera_ = ::CompositorManager.getCameraForSceneType(CompositorSceneType.INVENTORY_PLAYER_INSPECTOR);
            //mCamera_.getParentNode().setPosition(-1, 10, 20);
            //mCamera_.lookAt(0, 0, 0);

            local characterGenerator = CharacterGenerator();
            local playerNode = _scene.getRootSceneNode().createChildSceneNode();
            local playerModel = characterGenerator.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, 50);
            //playerNode.setScale(0.5, 0.5, 0.5);
            playerModel.equipDataToCharacterModel(::Base.mPlayerStats.mPlayerCombatStats.mEquippedItems);
            mCharacterModel_ = playerModel;

            mCharacterModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
            mCharacterModel_.startAnimation(CharacterModelAnimId.BASE_ARMS_WALK);

            mModelAABB_ = playerModel.determineAABB();
            printf("Model aabb: %s", mModelAABB_.tostring());
        }
        function shutdown(){
            ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
            mCharacterModel_.destroy();
        }
        function getDatablock(){
            return mDatablock_;
        }
        function update(){
            mRotX += 0.005;

            local modelCentre = mModelAABB_.getCentre();
            local radius = mModelAABB_.getRadius();

            //local rot = PI * 0.1;
            local rot = sin(PI * mRotX)*0.4;
            local targetRad = radius * 1.5;
            local xPos = sin(rot)*targetRad;
            local yPos = cos(rot)*targetRad;
            local zPos = sin(PI*0.05)*targetRad;

            mCamera_.getParentNode().setPosition(modelCentre + Vec3(xPos, zPos, yPos));
            mCamera_.lookAt(modelCentre);
        }
    }

    constructor(){

    }

    function setup(parentWin){
        mParentWin_ = parentWin;
        mRenderPanel_ = mParentWin_.createPanel();
        mRenderPanel_.setMinSize(500, 500);

        mRenderManager_ = RenderManager();
    }

    function shutdown(){
        mRenderPanel_.setDatablock("unlitEmpty");
        mRenderManager_.shutdown();
    }

    function addToLayout(layout){
        layout.addCell(mRenderPanel_);
    }

    function notifyLayout(){
        mRenderManager_.setup(mRenderPanel_);
        mRenderPanel_.setDatablock(mRenderManager_.getDatablock());
    }

    function update(){
        mRenderManager_.update();
    }

};