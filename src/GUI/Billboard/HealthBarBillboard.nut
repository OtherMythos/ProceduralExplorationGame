::BillboardManager.HealthBarBillboard <- class extends ::BillboardManager.Billboard{

    HEALTH_LEVELS = 200;

    mPanelWidth_ = 0;
    mMaxHealth_ = null;

    constructor(parent, mask, totalHealth){
        mMaxHealth_ = totalHealth;
        base.constructor(parent, mask);
        local panel = ::GuiWidgets.GameplayProgressBar(parent);
        panel.setBorder(0);
        //panel.setHidden(false);
        //local width = 2 + ((totalHealth * totalHealth) *0.002);
        local width = 2 + (totalHealth / 2);
        if(width >= 100) width = 100;
        mPanelWidth_ = width;
        panel.setSize(width.tointeger(), 4);
        mPanel_ = panel;

        //setPercentage(1.0);
        setHealth(totalHealth);

        panel.setZOrder(BillboardZOrder.HEALTH_BAR);

        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mPanel_.setVisible(false);
        }
    }

    function destroy(){
        mPanel_.destroy();
    }

    function setPosition(pos){
        mPanel_.setCentre(pos.x, pos.y);
    }

    function setPercentage(percentage){
        mPanel_.setPercentage(percentage);
    }

    function setHealth(newHealth){
        local level = (newHealth / HEALTH_LEVELS).tointeger();
        local remainder = (newHealth.tofloat() % HEALTH_LEVELS.tofloat());
        local percentage = remainder.tofloat() / HEALTH_LEVELS.tofloat();
        if(level >= 1 && remainder == 0){
            percentage = 1.0;
            level-=1;
        }
        if(level == 0){
            if(mMaxHealth_ != null){
                if(mMaxHealth_ <= HEALTH_LEVELS){
                    percentage = newHealth.tofloat() / mMaxHealth_.tofloat();
                }
            }
        }
        setPercentage(percentage);
        mPanel_.setLevel(level);
    }

}