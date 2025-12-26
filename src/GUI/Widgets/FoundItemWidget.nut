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
    mFoundAnimationProgress_ = 0.0;
    mFoundAnimationActive_ = true;
    mFoundAnimationStartPos_ = null;
    mFoundAnimationFinalPos_ = null;
    mFoundAnimationFinalSize_ = null;
    mRemovalAnimationProgress_ = 0.0;
    mRemovalAnimationActive_ = false;

    static ITEM_MESH_Z = 5;
    static LABEL_OFFSET_Y = -10;
    static ANIMATION_SPEED = 0.02;
    static ANIMATION_SPEED_X = 0.005;
    static FOUND_ANIMATION_DURATION = 0.4;
    static FOUND_ANIMATION_START_SCALE = 0.1;
    static REMOVAL_ANIMATION_DURATION = 0.3;

    constructor(parentWindow, itemDef, scale=1.0){
        mParentWindow_ = parentWindow;
        mItemDef_ = itemDef;

        mFoundAnimationStartPos_ = Vec2_ZERO;
        mFoundAnimationFinalPos_ = Vec2_ZERO;
        mFoundAnimationFinalSize_ = Vec2_ZERO;

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

        //Calculate the centre position where the render icon should be
        local meshPanelCentre = Vec2(pos.x + mFullSize_.x / 2, pos.y + mMeshSize_.y / 2);

        //Update final position for animation without resetting animation state
        mFoundAnimationFinalPos_ = meshPanelCentre;
        mFoundAnimationFinalSize_ = Vec2(mMeshSize_.x * 0.5, mMeshSize_.y * 0.5);

        //Only initialise animation on first call (when progress is 0)
        if(mFoundAnimationProgress_ == 0.0){
            //Calculate start position from screen centre
            local screenCentre = (_window.getSize() / 2);
            mFoundAnimationStartPos_ = screenCentre;
            mFoundAnimationActive_ = true;
        }

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

        //Position the render icon at start of animation
        if(mRenderIcon_ != null){
            updateRenderIconPosition_();
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

    function startRemovalAnimation(){
        mRemovalAnimationProgress_ = 0.0;
        mRemovalAnimationActive_ = true;
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
            //Update found animation
            if(mFoundAnimationActive_){
                mFoundAnimationProgress_ += 1.0 / (FOUND_ANIMATION_DURATION * 60.0);
                if(mFoundAnimationProgress_ >= 1.0){
                    mFoundAnimationProgress_ = 1.0;
                    mFoundAnimationActive_ = false;
                }
                updateRenderIconPosition_();
            }

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

    function updateRenderIconPosition_(){
        if(mRenderIcon_ == null){
            return;
        }

        //Easing function for smooth animation (ease-out cubic)
        local easeProgress = 1.0 - pow(1.0 - mFoundAnimationProgress_, 3.0);
        local easeProgressY = ::Easing.easeOutBack(mFoundAnimationProgress_);

        //Interpolate position from start to final
        local animPos = mFoundAnimationStartPos_ + (mFoundAnimationFinalPos_ - mFoundAnimationStartPos_) * easeProgress;
        animPos.y = mFoundAnimationStartPos_.y + (mFoundAnimationFinalPos_.y - mFoundAnimationStartPos_.y) * easeProgressY;

        //Interpolate scale from start to final
        local startScale = FOUND_ANIMATION_START_SCALE;
        local endScale = 1.0;
        local animScale = startScale + (endScale - startScale) * easeProgress;
        local animSize = mFoundAnimationFinalSize_ * animScale;

        mRenderIcon_.setPosition(animPos);
        mRenderIcon_.setSize(animSize.x, animSize.y);

        //Animate opacity of gradient panel and label
        if(mGradientPanel_ != null){
            mGradientPanel_.setColour(ColourValue(1, 1, 1, easeProgress * 0.5));
        }
        if(mLabel_ != null){
            mLabel_.setTextColour(1, 1, 1, easeProgress);
        }
    }
};
