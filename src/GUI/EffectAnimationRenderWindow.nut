::ScreenManager.EffectAnimationRenderWindow <- class{
    mWindow_ = null;
    mCompositorId_ = null;
    mWinSize_ = null;
    mCompositorPanel_ = null;
    mCompositorType_ = CompositorSceneType.BG_EFFECT;

    constructor(compositorType){
        mCompositorType_ = compositorType;
        mWindow_ = _gui.createWindow();
        //this.mWindow_.setPosition(0, 400);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWinSize_ = Vec2(_window.getWidth(), _window.getHeight());
        mWindow_.setSize(mWinSize_);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setConsumeCursor(false);

        mCompositorPanel_ = mWindow_.createPanel();
        mCompositorPanel_.setPosition(0, 0);
        mCompositorPanel_.setSize(mWinSize_);
        mCompositorPanel_.setClickable(false);
        mCompositorPanel_.setKeyboardNavigable(false);

        //Create compositor
        setupCompositor();
        setupCamera();
    }

    function shutdown(){
        //TODO see if this is ever actually called.
        mCombatScenePanel_.setDatablock("unlitEmpty");
        shutdownCompositor_();
    }

    function shutdownCompositor_(){
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function getCompositorTypeWorkspace(compType){
        if(compType == CompositorSceneType.BG_EFFECT){
            return "renderTexture60_65Workspace";
        }
        else if(compType == CompositorSceneType.FG_EFFECT){
            return "renderTexture65_70Workspace";
        }else{
            assert(false);
        }
    }

    function setupCompositor(){
        local compositorName = getCompositorTypeWorkspace(mCompositorType_);

        local compId = ::CompositorManager.createCompositorWorkspace(compositorName, mWinSize_, mCompositorType_);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mCompositorPanel_.setDatablock(datablock);
    }

    function setupCamera(){
        //TODO there will likely be a better place to put this.
        //The problem is that different effects might need different camera settings.
        local camera = ::CompositorManager.getCameraForSceneType(mCompositorType_);
        assert(camera);
        local node = camera.getParentNode();
        node.setPosition(0, 0, EFFECT_WINDOW_CAMERA_Z);
        camera.lookAt(0, 0, 0);
        camera.setAspectRatio(_window.getWidth().tofloat() / _window.getHeight().tofloat());
        camera.setProjectionType(_PT_ORTHOGRAPHIC);
        camera.setOrthoWindow(20, 20);
    }

    function setZOrder(idx){
        mWindow_.setZOrder(idx);
    }
}