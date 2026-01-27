::RenderIconManager <- {

    RenderIcon = class{
        mParentNode_ = null;
        mMesh_ = null;
        mMeshItem_ = null;
        mNode_ = null;
        mMeshNode_ = null;

        mCurrentScreenPos_ = null;
        mCurrentScreenSize_ = null;
        mCentreMesh_ = false;
        mDebugPanel_ = null;
        mDebugWindow_ = null;
        mCutoutMaterial_ = false;
        mDatablock_ = null;
        mAnimMatrix_ = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ];

        constructor(parentNode, centreMesh=false, debugWindow=null, cutoutMaterial=false){
            mParentNode_ = parentNode;
            mCentreMesh_ = centreMesh;
            mDebugWindow_ = debugWindow;
            mCutoutMaterial_ = cutoutMaterial;
            //this.mParentNode_.setVisible(false);
        }

        function setMesh(mesh){
            mMesh_ = mesh;
            if(mMesh_ == null){
                if(mNode_) mNode_.destroyNodeAndChildren();
                mNode_ = null;
                mMeshNode_ = null;
                return;
            }

            if(mNode_){
                //The node already exists, so re-create only the item.
                if(mCentreMesh_){
                    mNode_.getChild(0).destroyNodeAndChildren();
                }else{
                    mNode_.recursiveDestroyAttachedObjects();
                }
            }else{
                mNode_ = mParentNode_.createChildSceneNode();
            }

            local item = _gameCore.createVoxMeshItem(mesh);
            item.setRenderQueueGroup(RENDER_QUEUE_RENDER_ICONS);

            //Create a child node for the mesh if centring is enabled
            if(mCentreMesh_){
                mMeshNode_ = mNode_.createChildSceneNode();
                mMeshNode_.attachObject(item);

                //Calculate the centre offset from the AABB
                local aabb = item.getLocalAabb();
                local halfSize = aabb.getHalfSize();
                local centre = aabb.getCentre();
                mMeshNode_.setPosition(-centre.x, -centre.y, -centre.z);
            }else{
                mNode_.attachObject(item);
                mMeshNode_ = null;
            }

            mMeshItem_ = item;

            if(mCurrentScreenSize_ != null){
                setSize(mCurrentScreenSize_.x, mCurrentScreenSize_.y);
                setPosition(mCurrentScreenPos_);
            }
        }

        function destroy(){
            if(mNode_) mNode_.destroyNodeAndChildren();

            mNode_ = null;
            mMesh_ = null;
            mMeshItem_ = null;

            if(mDebugPanel_){
                _gui.destroy(mDebugPanel_);
                mDebugPanel_ = null;
            }

            if(mDatablock_ != null){
                _hlms.destroyDatablock(mDatablock_);
                mDatablock_ = null;
            }
        }

        function setPosition(pos){
            if(!mNode_) return;
            mCurrentScreenPos_ = pos.copy();
            local objectPos = ::EffectManager.getWorldPositionForWindowPos(mCurrentScreenPos_);
            print("objet post" + objectPos);
            mNode_.setPosition(objectPos.x, objectPos.y, 70);

            //Update holepunch matrix if using cutout material
            if(mCutoutMaterial_ && mCurrentScreenSize_ != null){
                updateHolepunchMatrix_();
            }

            if(mDebugPanel_){
                mDebugPanel_.setCentre(mCurrentScreenPos_.x, mCurrentScreenPos_.y);
            }
        }

        function setVisible(visible){
            if(!mNode_) return;
            mNode_.setVisible(visible);
        }

        /**
         * Set the size of the render icon.
         * The icon will be scaled in its aspect ratio according to fit within the bounds.
         */
        function setSize(width, height){
            if(!mNode_) return;

            mCurrentScreenSize_ = Vec2(width, height);
            mNode_.setScale(1, 1, 1);

            local aabb = mMeshItem_.getLocalAabb();
            local sizeVec = aabb.getHalfSize();
            local y = sizeVec.y > sizeVec.x;
            local intended = mCurrentScreenPos_ + Vec2(width, height);
            local foundPos = ::EffectManager.getWorldPositionForWindowPos(intended);
            local posDiff = foundPos - mNode_.getPositionVec3().xy();
            local percentage = posDiff / sizeVec.xy();

            local newScale = y ? -percentage.y : percentage.x;

            newScale *= 0.5;
            newScale *= 0.75;
            mNode_.setScale(newScale, newScale, newScale);

            //Update holepunch matrix if using cutout material
            if(mCutoutMaterial_ && mCurrentScreenPos_ != null){
                updateHolepunchMatrix_();
            }

            if(mDebugPanel_){
                mDebugPanel_.setSize(width, height);
                mDebugPanel_.setCentre(mCurrentScreenPos_.x, mCurrentScreenPos_.y);
            }
        }

        function setOrientation(orientation){
            if(!mNode_) return;
            mNode_.setOrientation(orientation);
        }

        function getDatablock(){
            return mDatablock_;
        }

        function setDatablock(datablock){
            mDatablock_ = datablock;
        }

        function setHolepunchMatrix(screenPos, screenSize, textureSize){
            if(mDatablock_ == null) return;

            //Calculate the normalized position and size within the texture
            local normalizedX = (screenPos.x - screenSize.x / 2) / textureSize.x;
            local normalizedY = (screenPos.y - screenSize.y / 2) / textureSize.y;
            local normalizedWidth = screenSize.x / textureSize.x;
            local normalizedHeight = screenSize.y / textureSize.y;

            //Set up the animation matrix to display only the holepunched region
            mAnimMatrix_[0] = normalizedWidth;
            mAnimMatrix_[5] = normalizedHeight;
            mAnimMatrix_[3] = normalizedX;
            mAnimMatrix_[7] = normalizedY;

            //assert (false);
            mDatablock_.setAnimationMatrix(0, mAnimMatrix_);
        }

        function updateHolepunchMatrix_(){
            if(mDatablock_ == null || mCurrentScreenPos_ == null || mCurrentScreenSize_ == null) return;

            local textureSize = _window.getSize();

            setHolepunchMatrix(mCurrentScreenPos_, mCurrentScreenSize_, textureSize);
        }

        function _tostring(){
            return ::wrapToString(::RenderIconManager.RenderIcon, "RenderIcon", mMesh_);
        }
    }

    mActiveIcons_ = []
    mParentNode_ = null
    mDebugPanelsEnabled_ = false
    mDebugWindow_ = null
    mRenderIconTexture_ = null
    mTotalDatablocks_ = 0
    mAnimMatrix_ = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    ]

    function setup(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        if(mDebugPanelsEnabled_){
            mDebugWindow_ = _gui.createWindow();
            mDebugWindow_.setZOrder(150);
            mDebugWindow_.setSize(_window.getSize().x, _window.getSize().y);
            mDebugWindow_.setClipBorders(0, 0, 0, 0);
            mDebugWindow_.setClickable(false);
            //mDebugWindow_.setVisualsEnabled(false);
        }
    }

    function update(){

    }

    function createIcon(mesh = null, centreMesh = false, cutoutMaterial = false){
        local newIcon = RenderIcon(mParentNode_, centreMesh, mDebugWindow_, cutoutMaterial);
        if(mesh != null){
            newIcon.setMesh(mesh);
        }

        if(cutoutMaterial){
            //Create a datablock for this icon
            local blendBlock = _hlms.getBlendblock({
                "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
                "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
                "dst_alpha_blend_factor": _HLMS_SBF_ONE
            });
            local datablock = _hlms.unlit.createDatablock("renderIconDatablock" + mTotalDatablocks_, blendBlock);
            newIcon.setDatablock(datablock);
            attachTextureToDatablock(datablock);
            mTotalDatablocks_++;
        }

        if(mDebugPanelsEnabled_ && mDebugWindow_){
            local debugPanel = mDebugWindow_.createPanel();
            local r = (_random.rand() % 100) / 100.0;
            local g = (_random.rand() % 100) / 100.0;
            local b = (_random.rand() % 100) / 100.0;
            debugPanel.setColour(ColourValue(r, g, b, 0.3));
            debugPanel.setClickable(false);
            newIcon.mDebugPanel_ = debugPanel;
        }

        newIcon.setPosition(_window.getSize() / 2);
        newIcon.setSize(100, 100);

        mActiveIcons_.append(newIcon);
        return newIcon;
    }

    function setRenderIconTexture(texture){
        mRenderIconTexture_ = texture;
    }

    function getRenderIconTexture(){
        return mRenderIconTexture_;
    }

    function attachTextureToDatablock(datablock){
        if(datablock != null){
            local texture = ::CompositorManager.mTextures_[CompositorSceneType.RENDER_ICONS];

            //local sampler = _hlms.getSamplerblock({
            //    "mag": "point"
            //});
            //datablock.setTexture(0, texture, sampler);
            datablock.setTexture(0, texture);
            datablock.setEnableAnimationMatrix(0, true);
        }
    }

    function createRenderIconDatablock(screenPos, screenSize){
        //Create a new datablock for rendering a holepunched region
        local blendBlock = _hlms.getBlendblock({
            "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
            "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
            "dst_alpha_blend_factor": _HLMS_SBF_ONE
        });
        local datablock = _hlms.unlit.createDatablock("renderIconPanelDatablock" + mTotalDatablocks_, blendBlock);
        attachTextureToDatablock(datablock);
        mTotalDatablocks_++;

        //Set up the holepunch matrix
        local textureSize = _window.getSize();

        local normalizedX = screenPos.x / textureSize.x;
        local normalizedY = screenPos.y / textureSize.y;
        local normalizedWidth = screenSize.x / textureSize.x;
        local normalizedHeight = screenSize.y / textureSize.y;

        mAnimMatrix_[0] = normalizedWidth;
        mAnimMatrix_[5] = normalizedHeight;
        mAnimMatrix_[3] = normalizedX;
        mAnimMatrix_[7] = normalizedY;

        datablock.setAnimationMatrix(0, mAnimMatrix_);

        return datablock;
    }

}