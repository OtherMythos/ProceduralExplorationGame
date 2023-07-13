::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].WorldMapDisplay <- class{

    mExplorationScenePanel_ = null;
    mCompositorId_ = null;

    mMapViewerPanel_ = null;
    mMapViewer_ = null;
    mMapViewerWindow_ = null;

    mBillboardManager_ = null;

    constructor(parentWin){
        mExplorationScenePanel_ = parentWin.createPanel();
        mExplorationScenePanel_.setPosition(0, 0);

        mMapViewerWindow_ = parentWin.createWindow();
        mMapViewerPanel_ = mMapViewerWindow_.createPanel();
        mMapViewer_ = MapViewer();
        mMapViewer_.setLabelWindow(mMapViewerWindow_);
        mMapViewerWindow_.setVisualsEnabled(false);

        _event.subscribe(Event.ACTIVE_WORLD_CHANGE, processActiveWorldChange, this);
    }

    function processActiveWorldChange(id, data){
        mMapViewer_.displayMapData(data.getMapData(), false);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mExplorationScenePanel_);
        mExplorationScenePanel_.setExpandVertical(true);
        mExplorationScenePanel_.setExpandHorizontal(true);
        mExplorationScenePanel_.setProportionVertical(4);
        mExplorationScenePanel_.setMargin(4, 4);
    }

    function shutdownCompositor_(){
        mBillboardManager_.shutdown();
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function shutdown(){
        mMapViewerPanel_.setDatablock("playerMapIndicator");
        mExplorationScenePanel_.setDatablock("playerMapIndicator");
        //_gui.destroy(mMapViewerPanel_);
        //_gui.destroy(mExplorationScenePanel_);
        shutdownCompositor_();
        mMapViewer_.shutdown();

        _event.unsubscribe(Event.ACTIVE_WORLD_CHANGE, processActiveWorldChange, this);
    }
    function setupCompositor(){
        local winSize = mExplorationScenePanel_.getSize();
        local winPos = mExplorationScenePanel_.getPosition();

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture30Workspace", winSize, CompositorSceneType.EXPLORATION);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mExplorationScenePanel_.setDatablock(datablock);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        mBillboardManager_ = ::BillboardManager(camera, winSize, winPos);
    }

    function update(){
        mBillboardManager_.update();
    }

    function notifyResize(){
        setupCompositor();

        local winSize = mExplorationScenePanel_.getSize();
        local basePos = mExplorationScenePanel_.getPosition();
        local offset = ::Base.getTargetInterface() == TargetInterface.MOBILE ? 0.4 : 0.2;
        local targetSize = winSize * offset;
        targetSize.y = targetSize.x;
        mMapViewerWindow_.setClipBorders(0, 0, 0, 0);
        mMapViewerWindow_.setSize(targetSize);
        mMapViewerWindow_.setPosition((basePos.x + winSize.x) - mMapViewerWindow_.getSize().x, basePos.y);
        mMapViewerPanel_.setSize(targetSize);
        mMapViewerPanel_.setDatablock(mMapViewer_.getDatablock());
    }

    function getPosition(){
        return mExplorationScenePanel_.getPosition();
    }
    function getSize(){
        return mExplorationScenePanel_.getSize();
    }

    function getWorldPositionInScreenSpace(pos){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        local worldPos = camera.getWorldPosInWindow(pos);

        local winSize = mExplorationScenePanel_.getSize();
        local width = winSize.x / 2;
        local height = winSize.y / 2;
        local posX = width + (width * worldPos.x);
        local posY = height + (height * -worldPos.y);

        return mExplorationScenePanel_.getPosition() + Vec2(posX, posY);
    }
};