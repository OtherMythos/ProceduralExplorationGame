//Widget to display a single found item with a 3D mesh and label

::GuiWidgets.FoundItemWidget <- class{

    mParentWindow_ = null;
    mRenderIcon_ = null;
    mLabel_ = null;
    mItemDef_ = null;
    mDebugPanel_ = null;
    mDebugMeshPanel_ = null;
    mGradientPanel_ = null;

    mPosition_ = Vec2(0, 0);
    mMeshSize_ = null;
    mFullSize_ = Vec2(98, 98);
    mAnimationRotation_ = 0.0;
    mAnimationRotationX_ = 0.0;

    static ITEM_MESH_Z = 5;
    static LABEL_OFFSET_Y = -10;
    static ANIMATION_SPEED = 0.02;
    static ANIMATION_SPEED_X = 0.005;

    constructor(parentWindow, itemDef, scale=1.0){
        mParentWindow_ = parentWindow;
        mItemDef_ = itemDef;

        mMeshSize_ = mFullSize_ * 0.75;

        createRenderIcon_();
        createLabel_();
        createDebugPanel_();

        mDebugPanel_.setVisible(false);
        mDebugMeshPanel_.setVisible(false);
    }

    function createRenderIcon_(){
        local meshName = mItemDef_.getMesh();
        if(meshName == null){
            //Items without meshes won't be displayed
            return;
        }

        mRenderIcon_ = ::RenderIconManager.createIcon(meshName, true);
    }

    function createLabel_(){
        mLabel_ = mParentWindow_.createLabel();
        mLabel_.setText(mItemDef_.getName(), false);
        //mLabel_.setText("this is some long and complicated text", false);
        mLabel_.setTextHorizontalAlignment( _TEXT_ALIGN_CENTER );
        //mLabel_.setText("this is", false);
        mLabel_.sizeToFit(mFullSize_.x * 0.9);
        mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
        mLabel_.setClickable(false);
    }

    function createDebugPanel_(){
        mGradientPanel_ = mParentWindow_.createPanel();
        mGradientPanel_.setSize(mMeshSize_);
        mGradientPanel_.setClickable(false);
        mGradientPanel_.setDatablock("simpleGradient");
        mGradientPanel_.setColour(ColourValue(1, 1, 1, 0.5));

        mDebugPanel_ = mParentWindow_.createPanel();
        mDebugPanel_.setSize(mFullSize_);
        mDebugPanel_.setClickable(false);
        mDebugPanel_.setColour(ColourValue(0.2, 0.5, 0.8, 0.3));
        mDebugPanel_.setSize(getSize());

        mDebugMeshPanel_ = mParentWindow_.createPanel();
        mDebugMeshPanel_.setSize(mMeshSize_);
        mDebugMeshPanel_.setClickable(false);
        mDebugMeshPanel_.setColour(ColourValue(0.8, 0.2, 0.2, 0.4));
    }

    function getSize(){
        /*
        local outPos = mDebugPanel_.getSize();
        local startPos = mDebugPanel_.getPosition();
        outPos.y = (mLabel_.getPosition().y + mLabel_.getSize().y) - startPos.y;
        return outPos;
        */

        local outSize = mDebugPanel_.getSize();
        outSize.y = mMeshSize_.y + mLabel_.getSize().y + LABEL_OFFSET_Y;
        return outSize;
    }

    function setPosition(pos){
        mPosition_ = pos;

        //Position the debug panel at the position
        if(mDebugPanel_ != null){
            mDebugPanel_.setPosition(pos);
        }

        //Position the mesh debug panel centered at the top
        if(mDebugMeshPanel_ != null){
            local meshPanelPos = pos + (mFullSize_ - mMeshSize_) / 2;
            meshPanelPos.y = pos.y;
            mDebugMeshPanel_.setPosition(meshPanelPos);
        }

        //Position the gradient panel centered at the top
        if(mGradientPanel_ != null){
            local gradientPanelPos = pos + (mFullSize_ - mMeshSize_) / 2;
            gradientPanelPos.y = pos.y;
            mGradientPanel_.setPosition(gradientPanelPos);
        }

        //Position the label below the mesh
        local labelPos = mPosition_ + mMeshSize_;
        labelPos.y += LABEL_OFFSET_Y;
        labelPos.x = (mFullSize_.x - mLabel_.getSize().x) / 2;
        mLabel_.setPosition(labelPos);

        //Position the render icon
        if(mRenderIcon_ != null){
            local meshPanelCentre = Vec2(pos.x + mFullSize_.x / 2, pos.y + mMeshSize_.y / 2);
            mRenderIcon_.setPosition(meshPanelCentre);
            mRenderIcon_.setSize(mMeshSize_.x * 0.5, mMeshSize_.y * 0.5);
        }
    }

    function setVisible(visible){
        if(mLabel_ != null){
            mLabel_.setVisible(visible);
        }
        if(mDebugPanel_ != null){
            mDebugPanel_.setVisible(visible);
        }
        if(mDebugMeshPanel_ != null){
            mDebugMeshPanel_.setVisible(visible);
        }
        if(mGradientPanel_ != null){
            mGradientPanel_.setVisible(visible);
        }
        if(mRenderIcon_ != null){
            //RenderIconManager doesn't expose setVisible, but we can control via parent node visibility
            //For now, leaving this as a placeholder
        }
    }

    function shutdown(){
        if(mLabel_ != null){
            _gui.destroy(mLabel_);
            mLabel_ = null;
        }
        if(mDebugPanel_ != null){
            _gui.destroy(mDebugPanel_);
            mDebugPanel_ = null;
        }
        if(mDebugMeshPanel_ != null){
            _gui.destroy(mDebugMeshPanel_);
            mDebugMeshPanel_ = null;
        }
        if(mGradientPanel_ != null){
            _gui.destroy(mGradientPanel_);
            mGradientPanel_ = null;
        }
        if(mRenderIcon_ != null){
            mRenderIcon_.destroy();
            mRenderIcon_ = null;
        }
    }

    function getPosition(){
        return mPosition_;
    }

    function getItemDef(){
        return mItemDef_;
    }

    function update(){
        if(mRenderIcon_ != null){
            //Update rotation animation
            mAnimationRotation_ += ANIMATION_SPEED;
            if(mAnimationRotation_ >= (PI * 2)){
                mAnimationRotation_ -= (PI * 2);
            }

            mAnimationRotationX_ -= ANIMATION_SPEED_X;
            if(mAnimationRotationX_ <= -(PI)){
                mAnimationRotationX_ += (PI * 2);
            }

            //Create rotation around Y axis
            local rotQuatY = Quat(mAnimationRotation_, ::Vec3_UNIT_Y);
            //Create rotation around X axis
            local rotQuatX = Quat(mAnimationRotationX_, ::Vec3_UNIT_X * 0.5);
            //Combine rotations
            local combinedQuat = rotQuatY * rotQuatX;
            mRenderIcon_.setOrientation(combinedQuat);
        }
    }
};
