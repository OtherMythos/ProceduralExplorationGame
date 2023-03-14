::WorldGenTool <- {

    mControlsWindow_ = null
    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null
    mSeedLabel_ = null

    mMapViewer_ = null

    mPerlinTexture_ = null

    mWinWidth_ = 1920
    mWinHeight_ = 1080

    function setup(){
        setupGui();

        generate();
    }

    function update(){

    }

    function setupGui(){
        mMapViewer_ = ::MapViewer();

        local winWidth = 0.4;

        mControlsWindow_ = _gui.createWindow();
        mControlsWindow_.setSize(mWinWidth_ * winWidth, mWinHeight_);

        local layout = _gui.createLayoutLine();

        local title = mControlsWindow_.createLabel();
        title.setText("World Gen Tool");
        layout.addCell(title);

        local seedLabel = mControlsWindow_.createLabel();
        seedLabel.setText("Seed");
        layout.addCell(seedLabel);
        mSeedLabel_ = seedLabel;

        local newGenButton = mControlsWindow_.createButton();
        newGenButton.setText("Generate")
        newGenButton.attachListenerForEvent(function(widget, action){
            ::WorldGenTool.generate();
        }, _GUI_ACTION_PRESSED);
        layout.addCell(newGenButton);

        local waterCheckbox = mControlsWindow_.createCheckbox();
        waterCheckbox.setText("Draw water");
        waterCheckbox.setValue(false);
        waterCheckbox.attachListenerForEvent(function(widget, action){
            mMapViewer_.setDrawWater(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(waterCheckbox);

        local showGroundVoxelCheckbox = mControlsWindow_.createCheckbox();
        showGroundVoxelCheckbox.setText("Draw ground voxels");
        showGroundVoxelCheckbox.setValue(false);
        showGroundVoxelCheckbox.attachListenerForEvent(function(widget, action){
            mMapViewer_.setDrawGroundVoxels(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(showGroundVoxelCheckbox);

        local showWaterGroupCheckbox = mControlsWindow_.createCheckbox();
        showWaterGroupCheckbox.setText("Show water group");
        showWaterGroupCheckbox.setValue(false);
        showWaterGroupCheckbox.attachListenerForEvent(function(widget, action){
            mMapViewer_.setDrawWaterGroups(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(showWaterGroupCheckbox);

        local showRiverDataCheckbox = mControlsWindow_.createCheckbox();
        showRiverDataCheckbox.setText("Show river data");
        showRiverDataCheckbox.setValue(false);
        showRiverDataCheckbox.attachListenerForEvent(function(widget, action){
            mMapViewer_.setDrawRiverData(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(showRiverDataCheckbox);

        local showLandGroupCheckbox = mControlsWindow_.createCheckbox();
        showLandGroupCheckbox.setText("Show land group");
        showLandGroupCheckbox.setValue(false);
        showLandGroupCheckbox.attachListenerForEvent(function(widget, action){
            mMapViewer_.setDrawLandGroups(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(showLandGroupCheckbox);

        layout.layout();


        local renderWindow = _gui.createWindow();
        renderWindow.setSize(mWinWidth_ * (1.0 - winWidth), mWinHeight_);
        renderWindow.setPosition(mWinWidth_ * winWidth, 0);
        renderWindow.setClipBorders(0, 0, 0, 0);
        local renderPanel = renderWindow.createPanel();
        renderPanel.setPosition(0, 0);
        renderPanel.setSize(renderWindow.getSize());
        renderPanel.setDatablock(mMapViewer_.getDatablock());
    }

    function generate(){
        local gen = ::MapGen();
        local data = {
            "seed": _random.randInt(0, 100000),
            "width": 400,
            "height": 400,
            "numRivers": 4,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100]
        };
        local outData = gen.generate(data);
        mSeedLabel_.setText("Seed: " + data.seed.tostring());

        mMapViewer_.displayMapData(outData);
    }
};