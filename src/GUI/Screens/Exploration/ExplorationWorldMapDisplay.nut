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
        mMapViewerWindow_.setHidden(true);
        mMapViewer_.setLabelWindow(mMapViewerWindow_);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mExplorationScenePanel_);
        mExplorationScenePanel_.setExpandVertical(true);
        mExplorationScenePanel_.setExpandHorizontal(true);
        mExplorationScenePanel_.setProportionVertical(2);
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
    }
    function setupCompositor(){
        local winSize = mExplorationScenePanel_.getSize();

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture30Workspace", winSize, CompositorSceneType.EXPLORATION);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mExplorationScenePanel_.setDatablock(datablock);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        mBillboardManager_ = ::BillboardManager(camera, winSize);
    }

    function update(){
        mBillboardManager_.update();
    }


    function notifyNewMapData(data){
        mMapViewer_.displayMapData(data, false);
    }

    function notifyResize(){
        setupCompositor();

        local winSize = mExplorationScenePanel_.getSize();
        local basePos = mExplorationScenePanel_.getPosition();
        local targetSize = winSize * 0.3;
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