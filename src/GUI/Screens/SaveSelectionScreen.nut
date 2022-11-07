::SaveSelectionScreen <- class extends ::Screen{

    mWindow_ = null;

    constructor(){

    }

    function saveSelectionCallback_(widget, action){
        print(format("Selected save %i", widget.getUserId()));
    }

    function setup(){
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setText("Select a save");
        layoutLine.addCell(title);

        for(local i = 0; i < 3; i++){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(format("Save %i", i));
            button.setSize(_window.getWidth() * 0.9, buttonSize.y);
            button.setUserId(i);
            button.attachListenerForEvent(saveSelectionCallback_, _GUI_ACTION_PRESSED, this);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, 100);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();
    }

    function shutdown(){
        _gui.destroy(mWindow_);
    }
};