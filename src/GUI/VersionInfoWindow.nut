::VersionInfoWindow <- class{

    mWindow_ = null

    constructor(versionData){
        mWindow_ = _gui.createWindow();
        mWindow_.setClipBorders(0, 0, 0, 0);
        local winSize = Vec2(_window.getWidth(), _window.getHeight());
        mWindow_.setSize(winSize);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setConsumeCursor(false);
        mWindow_.setZOrder(200);

        local label = mWindow_.createLabel();

        local totalText = versionData.info;
        label.setText(totalText);

        label.setPosition(winSize - label.getSize());
    }

};