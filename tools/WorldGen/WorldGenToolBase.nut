::WorldGenTool <- {

    mControlsWindow_ = null
    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null
    mSeedLabel_ = null
    mSeedEditbox_ = null
    mVariationSeedEditbox_ = null

    mMapViewer_ = null

    mModelViewWindow_ = null
    mModelViewPanel_ = null
    mModelViewDatablock_ = null
    mModelViewCamera_ = null
    mModelViewTexture_ = null
    mModelViewWorkspace_ = null
    mModelFPSCamera_ = null

    mCurrentMapData_ = null
    mTimerLabel_ = null

    mSeed_ = 0
    mVariation_ = 0

    mWinWidth_ = 1920
    mWinHeight_ = 1080

    function setup(){
        setupGui();

        setRandomSeed();
        setVariation(0);
        generate();
    }

    function update(){
        if(mModelFPSCamera_) mModelFPSCamera_.update();
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

        local seedEditbox = mControlsWindow_.createEditbox();
        seedEditbox.setSize(300, 50);
        layout.addCell(seedEditbox);
        mSeedEditbox_ = seedEditbox;

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
            "Show river data",
            "Show land group",
            "Show edge vals",
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
    }

    function setSeed(seedValue){
        mSeedLabel_.setText("Seed: " + seedValue.tostring());
        mSeedEditbox_.setText(seedValue.tostring());
        mSeed_ = seedValue;
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
        local voxVals = [
            2, 112, 0, 192
        ]
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local vox = buf.readn('i')
                local voxFloat = (vox & 0xFF).tofloat();
                local altitude = ((voxFloat / 0xFF) * depth).tointeger();
                local voxelMeta = (vox >> 8) & 0x7F;
                if(voxFloat <= mCurrentMapData_.seaLevel) voxelMeta = 3;
                for(local i = 0; i < altitude; i++){
                    voxData[x + (y * width) + (i*width*height)] = voxVals[voxelMeta];
                }
            }
        }
        local vox = VoxToMesh(Timer(), 1 << 2);
        local meshObj = vox.createMeshForVoxelData("testVox", voxData, width, height, depth);

        local item = _scene.createItem(meshObj);
        local newNode = _scene.getRootSceneNode().createChildSceneNode();
        newNode.attachObject(item);
        newNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        vox.printStats();
    }

    function updateTimeData(mapData){
        mTimerLabel_.setText(format("total seconds: %.5f", mapData.stats.totalSeconds));
    }

    function generate(){
        local gen = ::MapGen();
        local data = {
            "seed": mSeed_,
            "variation": mVariation_,
            "width": 200,
            "height": 200,
            "numRivers": 24,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);
        mCurrentMapData_ = outData;

        mMapViewer_.displayMapData(outData);
        updateTimeData(outData);
    }
};