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

        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            local labelSize = label.getSize();
            label.setPosition(winSize.x / 2 - labelSize.x/2, winSize.y - labelSize.y);
        }else{
            label.setPosition(winSize - label.getSize());
        }
    }

};