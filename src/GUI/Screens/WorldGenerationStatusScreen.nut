::ScreenManager.Screens[Screen.WORLD_GENERATION_STATUS_SCREEN] = class extends ::Screen{

    mHealthBar_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setPosition(0, 0);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setZOrder(61);
        mWindow_.setDatablock("unlitBlack");

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Generating world", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        local healthBar = ::GuiWidgets.ProgressBar(mWindow_);
        healthBar.setSize(_window.getWidth() * 0.5, 50);
        healthBar.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();

        healthBar.notifyLayout();
        healthBar.setPercentage(0.0);
        mHealthBar_ = healthBar;

        _event.subscribe(Event.WORLD_GENERATION_PROGRESS, receiveGenerationProgress, this);
    }

    function update(){
    }

    function shutdown(){
        base.shutdown();
        _event.unsubscribe(Event.WORLD_GENERATION_PROGRESS, receiveGenerationProgress);
    }

    function receiveGenerationProgress(id, data){
        mHealthBar_.setPercentage(data.percentage);
        if(data.percentage >= 1.0){
            ::ScreenManager.queueTransition(null, null, mLayerIdx);
        }
    }

};
