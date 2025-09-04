::GuiWidgets.GameplayInventoryWidget <- class{

    mWindow_ = null;

    mIconPanel_ = null;
    mIconBackground_ = null;

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

            mRenderWorkspace_ = _compositor.addWorkspace([texture], _camera.getCamera(), "compositor/GamplayInventoryRingWorkspace", true);
            //mRenderWorkspace_.update();

            local blendBlock = _hlms.getBlendblock({
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA
            });
            local datablock = _hlms.unlit.createDatablock("gameplayInventoryWidgetDatablock", blendBlock);
            datablock.setTexture(0, texture);
            mIconBackground_.setDatablock(datablock);
        }

        mIconPanel_ = mWindow_.createPanel();
        mIconPanel_.setDatablock("bagIcon");
        mIconPanel_.setSize(size * 0.9);
    }

    function setPosition(pos){
        mIconPanel_.setPosition(pos + mIconPanel_.getSize() * 0.05);
        mIconBackground_.setPosition(pos);
    }

}