::GuiWidgets.GameplayInventoryWidget <- class{

    mWindow_ = null;

    mIconPanel_ = null;
    mIconBackground_ = null;
    mIconLabel_ = null;
    mIconButton_ = null;

    mTexture_ = null;
    mDatablock_ = null;

    mRenderWorkspace_ = null;

    constructor(parentWindow, size){
        mWindow_ = parentWindow;

        mIconBackground_ = mWindow_.createPanel();
        //mIconBackground_.setDatablock("bagIcon");
        mIconBackground_.setSize(size);

        {
            local texture = _graphics.createTexture("inventoryWidgetTexture");
            texture.setResolution((size.x * ::resolutionMult.x).tointeger(), (size.y.tointeger() * ::resolutionMult.y).tointeger());
            texture.setPixelFormat(_PFG_RGBA8_UNORM);
            texture.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);

            mTexture_ = texture;
            mRenderWorkspace_ = _compositor.addWorkspace([texture], _camera.getCamera(), "compositor/GamplayInventoryRingWorkspace", true);
            //mRenderWorkspace_.update();

            local blendBlock = _hlms.getBlendblock({
                "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
                "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
                "dst_alpha_blend_factor": _HLMS_SBF_ONE
            });
            local datablock = _hlms.unlit.createDatablock("gameplayInventoryWidgetDatablock", blendBlock);
            datablock.setTexture(0, texture);
            mIconBackground_.setDatablock(datablock);
            mDatablock_ = datablock;
        }

        mIconPanel_ = mWindow_.createPanel();
        mIconPanel_.setDatablock("bagIcon");
        mIconPanel_.setSize(size * 0.9);

        mIconLabel_ = mWindow_.createLabel();
        mIconLabel_.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        setInventoryCount(20, 30);

        mIconButton_ = mWindow_.createButton();
        mIconButton_.setSize(mIconBackground_.getSize());
        mIconButton_.setVisualsEnabled(false);
        mIconButton_.attachListenerForEvent(function(widget, action){
            ::Base.mExplorationLogic.mCurrentWorld_.showInventory();
        }, _GUI_ACTION_PRESSED, this);

        mIconPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
        mIconLabel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
        mIconButton_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
    }

    function shutdown(){
        _compositor.removeWorkspace(mRenderWorkspace_);
        _gui.destroy(mIconBackground_);
        _hlms.destroyDatablock(mDatablock_);
        _graphics.destroyTexture(mTexture_);
    }

    function setPosition(pos){
        mIconPanel_.setPosition(pos + mIconPanel_.getSize() * 0.05);
        mIconBackground_.setPosition(pos);
        local pos = mIconBackground_.getCentre();
        pos.y += mIconBackground_.getSize().y * 0.35;
        mIconLabel_.setCentre(pos);

        mIconButton_.setPosition(mIconBackground_.getPosition());
    }

    function getPosition(){
        return mIconButton_.getPosition();
    }

    function setColour(colour){
        mIconPanel_.setColour(colour);
        mIconBackground_.setColour(colour);
        mIconLabel_.setColour(colour);
    }

    function setVisible(vis){
        mIconPanel_.setVisible(vis);
        mIconBackground_.setVisible(vis);
        mIconLabel_.setVisible(vis);
    }

    function setInventoryCount(count, total){
        mIconLabel_.setText(format("%i/%i", count, total));
    }

}