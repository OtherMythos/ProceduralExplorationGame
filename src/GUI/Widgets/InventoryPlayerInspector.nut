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

        mLeftPos_ = null;
        mRightPos_ = null;

        constructor(){

        }

        function setup(parentPanel){
            local winSize = parentPanel.getSize();

            local compId = ::CompositorManager.createCompositorWorkspace("renderTextureInventoryWorkspace", winSize * ::resolutionMult, CompositorSceneType.INVENTORY_PLAYER_INSPECTOR, false, false);
            mDatablock_ = ::CompositorManager.getDatablockForCompositor(compId);
            mCompositorId_ = compId;

            mCamera_ = ::CompositorManager.getCameraForSceneType(CompositorSceneType.INVENTORY_PLAYER_INSPECTOR);
            //mCamera_.getParentNode().setPosition(-1, 10, 20);
            //mCamera_.lookAt(0, 0, 0);

            local characterGenerator = CharacterGenerator();
            local playerNode = _scene.getRootSceneNode().createChildSceneNode();
            mCharacterModel_ = characterGenerator.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, RENDER_QUEUE_INVENTORY_PREVIEW);
            //playerNode.setScale(0.5, 0.5, 0.5);
            local combatStats = ::Base.mPlayerStats.mPlayerCombatStats;
            updateForEquipChange(combatStats.mEquippedItems, combatStats.mWieldActive);

            mCharacterModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
            mCharacterModel_.startAnimation(CharacterModelAnimId.BASE_ARMS_WALK);

            mModelAABB_ = mCharacterModel_.determineAABB();
            printf("Model aabb: %s", mModelAABB_.tostring());

            {
                local centre = mModelAABB_.getCentre();
                local radius = mModelAABB_.getRadius();
                local left = centre + Vec3(-radius * 0.5, 0, 0);
                local right = centre + Vec3(radius * 0.5, 0, 0);

                update();

                local l = mCamera_.getWorldPosInWindow(left);
                local r = mCamera_.getWorldPosInWindow(right);

                mLeftPos_ = Vec2((l.x + 1) / 2, (-l.y + 1) / 2) * winSize;
                mRightPos_ = Vec2((r.x + 1) / 2, (-r.y + 1) / 2) * winSize;
            }
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
        function updateForEquipChange(equippedItems, wieldActive){
            mCharacterModel_.equipDataToCharacterModel(equippedItems, wieldActive);
        }

        function getLeftPos(){
            return mLeftPos_;
        }
        function getRightPos(){
            return mRightPos_;
        }
    }

    constructor(){

    }

    function setup(parentWin){
        mParentWin_ = parentWin;
        mRenderPanel_ = mParentWin_.createPanel();
        local sizeRatio = ::ScreenManager.calculateRatio(200);
        mRenderPanel_.setMinSize(sizeRatio, sizeRatio);

        _event.subscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent, this);

        mRenderManager_ = RenderManager();
    }

    function shutdown(){
        mRenderPanel_.setDatablock("unlitEmpty");
        mRenderManager_.shutdown();
        _event.unsubscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent, this);
    }

    function getPosition(){
        return mRenderPanel_.getPosition();
    }

    function receivePlayerEquipChangedEvent(id, data){
        mRenderManager_.updateForEquipChange(data.items, data.wieldActive);
    }

    function getModelExtentRight(){
        return mRenderManager_.getRightPos();
    }
    function getModelExtentLeft(){
        return mRenderManager_.getLeftPos();
    }

    function setSize(size){
        mRenderPanel_.setSize(size);
    }

    function getSize(){
        return mRenderPanel_.getSize();
    }

    function setPosition(x, y){
        mRenderPanel_.setPosition(x, y);
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