::ScreenManager.Screens[Screen.GUI_TEST_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mPages_ = [];
    mCurrentPage_ = 0;
    mLeftButton_ = null;
    mRightButton_ = null;
    mPageLabel_ = null;

    function setup(data){
        //Create main navigation window
        mWindow_ = _gui.createWindow("TestScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setPosition(0, 0);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local defaultPage = 1;
        if(data != null && "page" in data){
            defaultPage = data.page;
        }

        //Create navigation buttons
        mLeftButton_ = mWindow_.createButton();
        mLeftButton_.setText("<");
        mLeftButton_.setSize(50, 50);
        mLeftButton_.setPosition(10, 5);
        mLeftButton_.attachListenerForEvent(function(widget, action){
            mNavigatePrevious_();
        }, _GUI_ACTION_PRESSED, this);

        mRightButton_ = mWindow_.createButton();
        mRightButton_.setText(">");
        mRightButton_.setSize(50, 50);
        mRightButton_.setPosition(_window.getWidth() - 60, 5);
        mRightButton_.attachListenerForEvent(function(widget, action){
            mNavigateNext_();
        }, _GUI_ACTION_PRESSED, this);

        mPageLabel_ = mWindow_.createLabel();
        mPageLabel_.setText("Page 0");
        mPageLabel_.setPosition(_window.getWidth() * 0.5 - 30, 15);

        mPages_.push(createPage0());
        mPages_.push(createPage1());

        mCurrentPage_ = defaultPage;
        mCurrentPage_ = mCurrentPage_ % mPages_.len();
        mCurrentPage_ = (mCurrentPage_ + mPages_.len()) % mPages_.len();
        mUpdatePageVisibility_();
    }

    function update(){

    }

    function mUpdatePageVisibility_(){
        foreach(i, page in mPages_){
            page.setVisible(i == mCurrentPage_);
        }
        mPageLabel_.setText("Page " + mCurrentPage_);
    }

    function mNavigatePrevious_(){
        mCurrentPage_ = (mCurrentPage_ - 1 + mPages_.len()) % mPages_.len();
        mUpdatePageVisibility_();
    }

    function mNavigateNext_(){
        mCurrentPage_ = (mCurrentPage_ + 1) % mPages_.len();
        mUpdatePageVisibility_();
    }



    function createPage0(){
        local page0Window = _gui.createWindow("TestScreen_Page0");
        page0Window.setSize(_window.getWidth(), _window.getHeight() - 70);
        page0Window.setPosition(0, 70);
        page0Window.setVisualsEnabled(false);
        page0Window.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local buttonSkin = [
            "Button_idle_1",
            "Button_idle_2",
            "Button_idle_3",
            "Button_idle_4",
            "Button_idle_5",
            "Button_idle_6",
            "Button_idle_7",
            "Button_idle_8",
            "Button_idle_9",
            "Button_idle_10",
        ];

        foreach(i, c in buttonSkin){
            local button = page0Window.createButton();
            button.setText("button");
            button.setSkin(c);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 50);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, 0);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() - 70);
        layoutLine.layout();

        return page0Window;
    }

    function createPage1(){
        local page1Window = _gui.createWindow("TestScreen_Page1");
        page1Window.setSize(_window.getWidth(), _window.getHeight() - 70);
        page1Window.setPosition(0, 70);
        page1Window.setVisualsEnabled(false);
        page1Window.setSkinPack("WindowSkinNoBorder");

        local buttonSkin = [
            "Button_idle_1",
            "Button_idle_2",
            "Button_idle_3",
            "Button_idle_4",
            "Button_idle_5",
            "Button_idle_6",
            "Button_idle_7",
            "Button_idle_8",
            "Button_idle_9",
            "Button_idle_10",
        ];

        local panelSize = 120;
        local margin = 5;
        local padding = 10;
        local cols = 3;

        foreach(i, skinName in buttonSkin){
            local row = i / cols;
            local col = i % cols;

            local x = padding + col * (panelSize + margin);
            local y = padding + row * (panelSize + margin);

            local panel = page1Window.createPanel();
            panel.setSize(panelSize, panelSize);
            panel.setPosition(x, y);
            panel.setSkin(skinName);
        }

        return page1Window;
    }
};