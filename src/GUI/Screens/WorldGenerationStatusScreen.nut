::ScreenManager.Screens[Screen.WORLD_GENERATION_STATUS_SCREEN] = class extends ::Screen{

    mProgressBar_ = null;
    mProgressLabels_ = null;
    mLabelLayout_ = null;

    function setup(data){
        mProgressLabels_ = [];

        mWindow_ = _gui.createWindow("WorldGenerationStatusScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setZOrder(61);
        mWindow_.setDatablock("unlitBlack");

        createBackgroundScreen_();
        mBackgroundWindow_.setDatablock("unlitBlack");

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Generating world", false);
        title.sizeToFit(::drawable.x * 0.9);
        layoutLine.addCell(title);

        local progressBar = ::GuiWidgets.ProgressBar(mWindow_);
        local ratio = ::ScreenManager.calculateRatio(50);
        progressBar.setSize(::drawable.x * 0.5, ratio < 40 ? 40 : ratio);
        progressBar.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(::drawable.x * 0.05, ::drawable.y * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y);
        layoutLine.layout();

        progressBar.notifyLayout();
        progressBar.setPercentage(0.0);
        mProgressBar_ = progressBar;

        mLabelLayout_ = _gui.createLayoutLine();

        _event.subscribe(Event.WORLD_PREPARATION_GENERATION_PROGRESS, receiveGenerationProgress, this);

        title.setZOrder(50);
        progressBar.setZOrder(50);
    }

    function update(){
    }

    function shutdown(){
        base.shutdown();
        _event.unsubscribe(Event.WORLD_PREPARATION_GENERATION_PROGRESS, receiveGenerationProgress);
    }

    function pushProgressLabel(labelText){
        local label = mWindow_.createLabel();
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setDefaultFontSize(label.getDefaultFontSize() * 1.5);
        label.setText(labelText, false);
        label.sizeToFit(::drawable.x);
        label.setZOrder(40);
        mLabelLayout_.addCell(label);

        mProgressLabels_.append(label);

        mLabelLayout_.setSize(::drawable);
        mLabelLayout_.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        mLabelLayout_.layout();

        local totalSize = 0;
        foreach(c,i in mProgressLabels_){
            totalSize += i.getSize().y
        }

        local offset = ::drawable.y - totalSize;
        foreach(c,i in mProgressLabels_){
            local pos = i.getPosition();
            local newY = pos.y + offset;
            i.setPosition(pos.x, newY);

            local animVal = newY / ::drawable.y;
            i.setTextColour(1, 1, 1, tan(animVal)/2);
        }

    }

    function receiveGenerationProgress(id, data){
        mProgressBar_.setPercentage(data.percentage);
        pushProgressLabel(data.name);
    }

};
