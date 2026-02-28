::BankWidget <- class{

    mParent_ = null;

    mBackgroundPanel_ = null;
    mInnerPanel_ = null;
    mTitle_ = null;

    mSavingsCounter_ = null;

    constructor(parent){
        mParent_ = parent;
    }

    function setup(){
        mBackgroundPanel_ = mParent_.createPanel();

        mBackgroundPanel_.setSize(mParent_.getSizeAfterClipping().x, 200);
        mBackgroundPanel_.setDatablock("simpleGrey");
        mBackgroundPanel_.setSkinPack("Panel_darkGrey");

        local innerPadding = 10;

        mTitle_ = mParent_.createLabel();
        mTitle_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.1);
        mTitle_.setText("Bank");
        mTitle_.setPosition(innerPadding, 0);

        local yPos = 0;
        yPos += mTitle_.getSize().y;

        mInnerPanel_ = mParent_.createPanel();
        local backgroundSize = mBackgroundPanel_.getSize();
        mInnerPanel_.setSize(backgroundSize.x - innerPadding * 2, backgroundSize.y - yPos - innerPadding);
        mInnerPanel_.setPosition(innerPadding, yPos);
        mInnerPanel_.setDatablock("placeMapIndicator");
        mInnerPanel_.setSkinPack("Panel_lightGrey");

        local xPos = mInnerPanel_.getPosition().x;
        local yPos = mInnerPanel_.getPosition().y;

        mSavingsCounter_ = mParent_.createLabel();
        mSavingsCounter_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.8);
        setMoneyCount_(::Base.mPlayerStats.getBankMoney());
        mSavingsCounter_.setPosition(xPos, yPos);

        local moneyIcon = mParent_.createPanel();
        moneyIcon.setDatablock("coinsIcon");
        local moneySize = mSavingsCounter_.getSize().y * 0.8;
        moneyIcon.setSize(moneySize, moneySize);
        moneyIcon.setPosition(xPos, yPos);
        mSavingsCounter_.setPosition(mSavingsCounter_.getPosition() + Vec2(moneySize, -5));
        mSavingsCounter_.setShadowOutline(true, ColourValue(0.05, 0.05, 0.05, 1.0), Vec2(1, 1));

        yPos += moneySize;

        {
            local withdrawButton = mParent_.createButton();
            withdrawButton.setText("Withdraw");
            withdrawButton.setPosition(xPos, yPos - 5);
            withdrawButton.setDefaultFontSize(withdrawButton.getDefaultFontSize() * 1.8);
            local size = withdrawButton.getSize();
            withdrawButton.setSize(mInnerPanel_.getSize().x / 2, size.y * 1.5);
            withdrawButton.setSkinPack("Panel_blue");
            withdrawButton.attachListenerForEvent(function(widget, action){
                ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.BANK_DEPOSIT_WITHDRAW_SCREEN, {"deposit": false}), null, 3);
            }, _GUI_ACTION_PRESSED, this);

            local depositButton = mParent_.createButton();
            depositButton.setText("Deposit");
            depositButton.setPosition(xPos + mInnerPanel_.getSize().x / 2, yPos - 5);
            depositButton.setDefaultFontSize(depositButton.getDefaultFontSize() * 1.8);
            local size = depositButton.getSize();
            depositButton.setSize(mInnerPanel_.getSize().x / 2, size.y * 1.5);
            depositButton.setSkinPack("Panel_blue");
            depositButton.attachListenerForEvent(function(widget, action){
                ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.BANK_DEPOSIT_WITHDRAW_SCREEN, {"deposit": true}), null, 3);
            }, _GUI_ACTION_PRESSED, this);

            ::evenOutButtonsForHeight([withdrawButton, depositButton]);

            foreach(i in [withdrawButton, depositButton]){
                local start = i.getCentre();
                local size = i.getSize();
                size.y *= 0.8;
                size.x -= 5;
                i.setSize(size);
                i.setCentre(start);
            }
        }

        _event.subscribe(Event.BANK_MONEY_CHANGED, receiveBankMoneyChanged, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.BANK_MONEY_CHANGED, receiveBankMoneyChanged, this);
    }

    function receiveBankMoneyChanged(id, data){
        setMoneyCount_(data);
    }

    function setMoneyCount_(money){
        mSavingsCounter_.setText(money.tostring());
    }

    function getPosition(){
        return mBackgroundPanel_.getPosition();
    }

    function getSize(){
        return mBackgroundPanel_.getSize();
    }

};