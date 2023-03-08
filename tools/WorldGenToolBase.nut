::WorldGenTool <- {

    mControlsWindow_ = null
    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mPerlinTexture_ = null

    mWinWidth_ = 1920
    mWinHeight_ = 1080

    function setup(){
        setupCompositor();
        setupGui();

        generate();
    }

    function update(){

    }

    function setupCompositor(){
        local newTex = _graphics.createTexture("compositor/renderTexture");
        newTex.setResolution(1920, 1080);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mCompositorTexture_ = newTex;

        local newCamera = _scene.createCamera("compositor/camera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);
        mCompositorCamera_ = newCamera;

        local datablock = _hlms.unlit.createDatablock("renderTextureDatablock");
        datablock.setTexture(0, newTex);
        mCompositorDatablock_ = datablock;
    }

    function setupGui(){
        local winWidth = 0.4;

        mControlsWindow_ = _gui.createWindow();
        mControlsWindow_.setSize(mWinWidth_ * winWidth, mWinHeight_);

        local layout = _gui.createLayoutLine();

        local title = mControlsWindow_.createLabel();
        title.setText("World Gen Tool");
        layout.addCell(title);

        local newGenButton = mControlsWindow_.createButton();
        newGenButton.setText("Generate")
        newGenButton.attachListenerForEvent(function(widget, action){
            ::WorldGenTool.generate();
        }, _GUI_ACTION_PRESSED);
        layout.addCell(newGenButton);

        layout.layout();


        local renderWindow = _gui.createWindow();
        renderWindow.setSize(mWinWidth_ * (1.0 - winWidth), mWinHeight_);
        renderWindow.setPosition(mWinWidth_ * winWidth, 0);
        renderWindow.setClipBorders(0, 0, 0, 0);
        local renderPanel = renderWindow.createPanel();
        renderPanel.setPosition(0, 0);
        renderPanel.setSize(renderWindow.getSize());
        renderPanel.setDatablock(mCompositorDatablock_);
    }

    function generate(){
        _random.seedPatternGenerator(_random.randInt(0, 100000));

        local width = 200;
        local height = 200;

        if(mPerlinTexture_ != null){
            _graphics.destroyTexture(mPerlinTexture_);
            mPerlinTexture_ = null;
        }
        mPerlinTexture_ = _graphics.genPerlinNoiseTexture("perlinNoiseTexture", width, height);

        if(mCompositorWorkspace_ != null){
            _compositor.removeWorkspace(mCompositorWorkspace_);
            mCompositorWorkspace_ = null;
        }
        //Re-generate the compositor so I can pass the new textures to it.
        mCompositorWorkspace_ = _compositor.addWorkspace([mCompositorTexture_, mPerlinTexture_], mCompositorCamera_, "renderTextureWorkspace", true);



        //I will want the actual rendering code to live in the main source.
        //Potentially even the viewer workspace should live somewhere else so I can use it in the game itself.
    }
};