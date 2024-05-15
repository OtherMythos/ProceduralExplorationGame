::VersionInfoWindow <- class{

    mWindow_ = null
    mLabel_ = null

    constructor(versionData){
        mWindow_ = _gui.createWindow("VersionInfo");
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setVisualsEnabled(false);
        mWindow_.setConsumeCursor(false);

        local label = mWindow_.createLabel();

        local totalText = versionData.info;
        label.setText(totalText);
        mLabel_ = label;

        processResize();
    }

    function processResize(){
        local winSize = _window.getSize();
        mWindow_.setSize(winSize);
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            local labelSize = mLabel_.getSize();
            mLabel_.setPosition(winSize.x / 2 - labelSize.x/2, winSize.y - labelSize.y);
        }else{
            mLabel_.setPosition(winSize - mLabel_.getSize());
        }

        mWindow_.setZOrder(200);
    }

};