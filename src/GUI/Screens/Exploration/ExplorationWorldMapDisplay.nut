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

        mMapViewerWindow_ = parentWin.createWindow("ExplorationWorldMapDisplay");
        mMapViewerPanel_ = mMapViewerWindow_.createPanel();
        mMapViewerWindow_.setVisualsEnabled(false);
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mMapViewerWindow_.setVisible(false);
        }

        _event.subscribe(Event.ACTIVE_WORLD_CHANGE, processActiveWorldChange, this);
        _event.subscribe(Event.PLACE_DISCOVERED, notifyPlaceDiscovered, this);
    }

    function switchMapViewer(world){
        local worldType = world.getWorldType();
        local data = world.getMapData();

        local oldViewer = mMapViewer_;
        if(worldType == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
            mMapViewer_ = ExplorationMapViewer(world.getCurrentFoundRegions());
        }
        else if(worldType == WorldTypes.PROCEDURAL_DUNGEON_WORLD){
            mMapViewer_ = DungeonMapViewer();
        }
        else if(worldType == WorldTypes.VISITED_LOCATION_WORLD){
            mMapViewer_ = VisitedLocationMapViewer();
        }
        else if(worldType == WorldTypes.TESTING_WORLD){
            mMapViewer_ = MapViewer();
        }else{
            assert(false);
        }
        mMapViewer_.displayMapData(data, false, true);
        mMapViewer_.setLabelWindow(mMapViewerWindow_);
        local mapDatablock = mMapViewer_.getDatablock();
        if(mapDatablock != null){
            mMapViewerPanel_.setDatablock(mapDatablock);
        }
        if(oldViewer != null) oldViewer.shutdown();
        mMapViewerPanel_.setVisible(worldType != WorldTypes.TESTING_WORLD);

        //Have to do this later so it doesn't try and re-generate without the map data.
        if(worldType == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
            mMapViewer_.setDrawOption(DrawOptions.VISIBLE_REGIONS, true);
        }
    }

    function notifyPlaceDiscovered(id, data){
        mMapViewer_.notifyNewPlaceFound(data.id, data.pos);
    }

    function processActiveWorldChange(id, data){
        switchMapViewer(data);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mExplorationScenePanel_);
        mExplorationScenePanel_.setExpandVertical(true);
        mExplorationScenePanel_.setExpandHorizontal(true);
        mExplorationScenePanel_.setProportionVertical(6);
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
        _event.unsubscribe(Event.PLACE_DISCOVERED, notifyPlaceDiscovered, this);
    }
    function setupCompositor(){
        local winSize = mExplorationScenePanel_.getSize() * ::resolutionMult;
        local winPos = mExplorationScenePanel_.getPosition();

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture30Workspace", winSize, CompositorSceneType.EXPLORATION);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mExplorationScenePanel_.setDatablock(datablock);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        mBillboardManager_ = ::BillboardManager(camera, mExplorationScenePanel_.getSize(), winPos);
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
        mMapViewerWindow_.setSkinPack("WindowSkinNoBorder");
        mMapViewerWindow_.setSize(targetSize);
        mMapViewerWindow_.setPosition((basePos.x + winSize.x) - mMapViewerWindow_.getSize().x, basePos.y);
        mMapViewerPanel_.setSize(targetSize);
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