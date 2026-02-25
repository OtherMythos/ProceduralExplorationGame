::ScreenManager.Screens[Screen.GUI_TEST_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mTestRenderIcon_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow("TestScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local buttonSkin = [
            "Button_idle_1",
            "Button_idle_2",
            "Button_idle_3",
            "Button_idle_4",
            "Button_idle_5",
        ];

        foreach(i,c in buttonSkin){
            local button = mWindow_.createButton();
            //button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText("button");
            button.setSkin(c);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 50);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();
    }

    function update(){

    }
};