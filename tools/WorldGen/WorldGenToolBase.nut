::WorldGenTool <- {

    mControlsWindow_ = null
    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null
    mSeedLabel_ = null
    mSeedEditbox_ = null
    mMoistureSeedLabel_ = null
    mMoistureSeedEditbox_ = null
    mVariationSeedEditbox_ = null
    mGenerationPopup_ = null

    mMapViewer_ = null

    mModelViewWindow_ = null
    mModelViewPanel_ = null
    mModelViewDatablock_ = null
    mModelViewCamera_ = null
    mModelViewTexture_ = null
    mModelViewWorkspace_ = null
    mModelFPSCamera_ = null

    mCurrentMapData_ = null
    mCurrentNativeMapData_ = null
    mTimerLabel_ = null

    mSeed_ = 0
    mMoistureSeed_ = 0
    mVariation_ = 0

    mGenerationInProgress_ = false

    mWinWidth_ = 1920
    mWinHeight_ = 1080

    GenerationPopup = class{
        mBackgroundWindow_ = null;
        mMainWindow_ = null;
        mProgressBar_ = null;
        constructor(){
            local layoutLine = _gui.createLayoutLine();

            local win = _gui.createWindow("GenerationPopupBackground");
            win.setSize(_window.getWidth(), _window.getHeight());
            win.setVisualsEnabled(true);
            mBackgroundWindow_ = win;

            win = _gui.createWindow("GenerationPopupWindow");
            win.setSize(_window.getWidth() * 0.5, _window.getHeight() * 0.5);
            win.setVisualsEnabled(true);
            mMainWindow_ = win;

            local mainWinSize = mMainWindow_.getSize();

            local label = win.createLabel();
            label.setDefaultFontSize(label.getDefaultFontSize() * 2.0);
            label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
            label.setText("Generating", false);
            label.sizeToFit(mainWinSize.x * 0.9);
            layoutLine.addCell(label);

            mProgressBar_ = ::GuiWidgets.ProgressBar(win);
            mProgressBar_.setSize(mainWinSize.x * 0.9, 50);
            mProgressBar_.setPosition(mainWinSize.x * 0.05, 150);
            mProgressBar_.addToLayout(layoutLine);

            layoutLine.setMarginForAllCells(0, 20);
            layoutLine.setPosition(mainWinSize.x * 0.05, 0);
            layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
            layoutLine.setSize(mainWinSize.x * 0.9, mainWinSize.y);
            layoutLine.layout();

            local calculatedSize = mMainWindow_.calculateChildrenSize();
            mMainWindow_.setSize(mMainWindow_.getSize().x, calculatedSize.y + 10);
            mMainWindow_.setCentre(_window.getSize() / 2);

            mProgressBar_.notifyLayout();
            _gui.reprocessMousePosition();
        }

        function shutdown(){
            _gui.destroy(mBackgroundWindow_);
            _gui.destroy(mMainWindow_);
            _gui.reprocessMousePosition();
        }

        function setPercentage(percentage){
            mProgressBar_.setPercentage(percentage);
        }
    }

    function setup(){
        checkForGameCorePlugin();

        setupGui();

        setRandomSeed();
        setVariation(0);
        generate();
    }

    function update(){
        if(mModelFPSCamera_) mModelFPSCamera_.update();
        if(mGenerationInProgress_){
            local stage = _gameCore.getMapGenStage();
            local result = _gameCore.checkClaimMapGen();
            mCurrentNativeMapData_ = result;
            if(result != null){
                setGenerationInProgress(false);

                mCurrentMapData_ = result.explorationMapDataToTable();
                print(mCurrentMapData_);
                print(mCurrentMapData_.width);
                mMapViewer_.displayMapData(mCurrentMapData_, mCurrentNativeMapData_);
                updateTimeData(mCurrentMapData_);
            }else{
                assert(mGenerationPopup_ != null);
                local percentage = _gameCore.getMapGenStage().tofloat() / _gameCore.getTotalMapGenStages().tofloat();
                mGenerationPopup_.setPercentage(percentage);
            }
        }
    }

    function setupGui(){
        mMapViewer_ = ::ExplorationMapViewer();

        mWinWidth_ = _window.getWidth();
        mWinHeight_ = _window.getHeight();
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

        local seedEditbox = mControlsWindow_.createEditbox();
        seedEditbox.setSize(300, 50);
        layout.addCell(seedEditbox);
        mSeedEditbox_ = seedEditbox;


        local moistureSeedLabel = mControlsWindow_.createLabel();
        moistureSeedLabel.setText("Moisture seed");
        layout.addCell(moistureSeedLabel);
        mMoistureSeedLabel_ = moistureSeedLabel;

        local moistureSeedEditbox = mControlsWindow_.createEditbox();
        moistureSeedEditbox.setSize(300, 50);
        layout.addCell(moistureSeedEditbox);
        mMoistureSeedEditbox_ = moistureSeedEditbox;

        local variationLabel = mControlsWindow_.createLabel();
        variationLabel.setText("Variation");
        layout.addCell(variationLabel);

        local variationSeedEditbox = mControlsWindow_.createEditbox();
        variationSeedEditbox.setSize(300, 50);
        layout.addCell(variationSeedEditbox);
        mVariationSeedEditbox_ = variationSeedEditbox;

        local generateButton = mControlsWindow_.createButton();
        generateButton.setText("Generate")
        generateButton.attachListenerForEvent(function(widget, action){
            local text = mSeedEditbox_.getText();
            print("Input text: " + text.tostring());
            local intText = text.tointeger();
            ::WorldGenTool.setSeed(intText);

            local moistureText = mMoistureSeedEditbox_.getText();
            print("Input moisture text: " + moistureText.tostring());
            local moistureIntText = moistureText.tointeger();
            ::WorldGenTool.setMoistureSeed(moistureIntText);

            local variationText = mVariationSeedEditbox_.getText();
            print("Variation text: " + variationText.tostring());
            local varIntText = variationText.tointeger();
            ::WorldGenTool.setVariation(varIntText);

            ::WorldGenTool.generate();
        }, _GUI_ACTION_PRESSED, this);
        layout.addCell(generateButton);

        local newGenButton = mControlsWindow_.createButton();
        newGenButton.setText("Random Seed")
        newGenButton.attachListenerForEvent(function(widget, action){
            ::WorldGenTool.setRandomSeed();
            ::WorldGenTool.generate();
        }, _GUI_ACTION_PRESSED);
        layout.addCell(newGenButton);

        local checkboxes = [
            "Draw water",
            "Draw ground voxels",
            "Show water group",
            "Show moisture map"
            "Show regions"
            "Show blue noise",
            "Show river data",
            "Show land group",
            "Show edge vals",
            "Show player start pos"
            "Show visible regions",
            "Show region seeds",
            "Show place locations",
        ];
        local checkboxListener = function(widget, action){
            mMapViewer_.setDrawOption(widget.getUserId(), widget.getValue());
        };
        foreach(c,i in checkboxes){
            local checkbox = mControlsWindow_.createCheckbox();
            checkbox.setText(i);
            checkbox.setValue(mMapViewer_.getDrawOption(c));
            checkbox.setUserId(c);
            checkbox.attachListenerForEvent(checkboxListener, _GUI_ACTION_RELEASED, this);
            layout.addCell(checkbox);
        }

        local locationTitle = mControlsWindow_.createLabel();
        locationTitle.setText("Show Location Types");
        layout.addCell(locationTitle);

        local locationCheckboxListener = function(widget, action){
            mMapViewer_.setLocationDrawOption(widget.getUserId(), widget.getValue());
        };
        local placeTypeNames = [
            "None",
            "Gateway",
            "City",
            "Town",
            "Village",
            "Location",
            "MAX"
        ];
        assert(placeTypeNames.len() == PlaceType.MAX+1);
        for(local i = 0; i < PlaceType.MAX; i++){
            local checkbox = mControlsWindow_.createCheckbox();
            checkbox.setText(placeTypeNames[i]);
            checkbox.setValue(mMapViewer_.getLocationDrawOption(i));
            checkbox.setUserId(i);
            checkbox.attachListenerForEvent(locationCheckboxListener, _GUI_ACTION_RELEASED, this);
            layout.addCell(checkbox);
        }

        local visualisationLabel = mControlsWindow_.createLabel();
        visualisationLabel.setText("Visualisation");
        layout.addCell(visualisationLabel);

        local viewAsModelButton = mControlsWindow_.createButton();
        viewAsModelButton.setText("View as model")
        viewAsModelButton.attachListenerForEvent(function(widget, action){
            ::WorldGenTool.viewCurrentMapAsModel();
        }, _GUI_ACTION_PRESSED);
        layout.addCell(viewAsModelButton);

        local timingLabel = mControlsWindow_.createLabel();
        timingLabel.setText("Timing");
        layout.addCell(timingLabel);

        mTimerLabel_ = mControlsWindow_.createLabel();
        mTimerLabel_.setText("first ");
        layout.addCell(mTimerLabel_);

        layout.layout();

        mControlsWindow_.sizeScrollToFit();

        local renderWindow = _gui.createWindow();
        renderWindow.setSize(mWinWidth_ * (1.0 - winWidth), mWinHeight_);
        renderWindow.setPosition(mWinWidth_ * winWidth, 0);
        renderWindow.setClipBorders(0, 0, 0, 0);
        local renderPanel = renderWindow.createPanel();
        renderPanel.setPosition(0, 0);
        renderPanel.setSize(renderWindow.getSize());
        renderPanel.setDatablock(mMapViewer_.getDatablock());
        renderPanel.setClipBorders(0, 0, 0, 0);
        mMapViewer_.setLabelWindow(renderWindow);
    }

    function setRandomSeed(){
        local seed = _random.randInt(0, 100000);
        setSeed(seed);
        seed = _random.randInt(0, 100000);
        setMoistureSeed(seed);
    }

    function setSeed(seedValue){
        mSeedLabel_.setText("Seed: " + seedValue.tostring());
        mSeedEditbox_.setText(seedValue.tostring());
        mSeed_ = seedValue;
    }

    function setMoistureSeed(seedValue){
        mMoistureSeedLabel_.setText("Moisture seed: " + seedValue.tostring());
        mMoistureSeedEditbox_.setText(seedValue.tostring());
        mMoistureSeed_ = seedValue;
    }

    function setVariation(variation){
        mVariationSeedEditbox_.setText(variation.tostring());
        mVariation_ = variation;
    }

    function viewCurrentMapAsModel_setup(){
        mModelViewWindow_ = _gui.createWindow();
        mModelViewWindow_.setZOrder(100);
        mModelViewWindow_.setPosition(0, 0);
        mModelViewWindow_.setSize(1920, 1080);

        mModelViewPanel_ = mModelViewWindow_.createPanel();
        mModelViewPanel_.setPosition(0, 0);
        mModelViewPanel_.setSize(mModelViewWindow_.getSize());

        local newTex = _graphics.createTexture("mapViewer/modelViewerRenderTexture");
        newTex.setResolution(1920, 1080);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mModelViewTexture_ = newTex;

        local newCamera = _scene.createCamera("mapViewer/modelViewerCamera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);
        mModelViewCamera_ = newCamera;

        mModelViewWorkspace_ = _compositor.addWorkspace([mModelViewTexture_], mModelViewCamera_, "mapViewer/modelViewerWorkspace", true);

        mModelViewDatablock_ = _hlms.unlit.createDatablock("mapViewer/modelViewerRenderDatablock");
        mModelViewDatablock_.setTexture(0, newTex);

        mModelViewPanel_.setDatablock(mModelViewDatablock_);

        cameraNode.setPosition(0, 50, 200);
        mModelViewCamera_.lookAt(0, 0, 0);
        mModelFPSCamera_ = ::fpsCamera(mModelViewCamera_);
    }
    function viewCurrentMapAsModel(){
        viewCurrentMapAsModel_setup();

        local width = mCurrentMapData_.width;
        local height = mCurrentMapData_.height;
        local depth = 40;
        local voxData = array(width * height * depth, null);
        local buf = mCurrentMapData_.voxelBuffer;
        buf.seek(0);
        local voxVals = ::VoxelValues;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local vox = buf.readn('i')
                local voxFloat = (vox & 0xFF).tofloat();
                local altitude = ((voxFloat / 0xFF) * depth).tointeger();
                local voxelMeta = (vox >> 8) & MAP_VOXEL_MASK;
                if(voxFloat <= mCurrentMapData_.seaLevel) voxelMeta = 5;
                for(local i = 0; i < altitude; i++){
                    voxData[x + (y * width) + (i*width*height)] = voxVals[voxelMeta];
                }
            }
        }
        local vox = VoxToMesh(Timer(), 1 << 2);
        local meshObj = vox.createMeshForVoxelData("testVox", voxData, width, height, depth);

        local item = _gameCore.createVoxMeshItem(meshObj);
        local newNode = _scene.getRootSceneNode().createChildSceneNode();
        newNode.attachObject(item);
        newNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        vox.printStats();
    }

    function updateTimeData(mapData){
        //mTimerLabel_.setText(format("total seconds: %.5f", mapData.stats.totalSeconds));
    }

    function generate_(seed, variation, moisture){
        local gen = ::MapGen();
        local data = {
            "seed": seed,
            "variation": variation,
            "moistureSeed": moisture,
            "width": 400,
            "height": 400,
            "numRivers": 24,
            "numRegions": 16,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);
        return outData;
    }
    function generate(){
        local data = {
            "seed": mSeed_,
            "variation": mVariation_,
            "moistureSeed": mMoistureSeed_,
            "width": 400,
            "height": 400,
            "numRivers": 24,
            "numRegions": 16,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };

        _gameCore.beginMapGen(data);
        setGenerationInProgress(true);
        /*
        local thread = ::newthread(generate_);
        thread.call(mSeed_, mVariation_, mMoistureSeed_);

        local finishedData = null;
        while(thread.getstatus() != "idle"){
            finishedData = thread.wakeup();
        }

        mCurrentMapData_ = finishedData;
        mMapViewer_.displayMapData(mCurrentMapData_);
        updateTimeData(mCurrentMapData_);
        */
    }

    function checkForGameCorePlugin(){
        if(!getroottable().rawin("_gameCore")){
            //The gamecore namespace was not found, so assume the plugin was not loaded correctly.
            assert(false);
        }
    }

    function setGenerationInProgress(gen){
        mGenerationInProgress_ = gen;

        if(gen){
            assert(mGenerationPopup_ == null);
            mGenerationPopup_ = GenerationPopup();
        }else{
            assert(mGenerationPopup_ != null);
            mGenerationPopup_.shutdown();
            mGenerationPopup_ = null;
        }
    }
};