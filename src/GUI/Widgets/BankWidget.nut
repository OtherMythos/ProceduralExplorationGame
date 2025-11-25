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

        local innerPadding = 5;

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

        local xPos = mInnerPanel_.getPosition().x;
        local yPos = mInnerPanel_.getPosition().y;

        mSavingsCounter_ = mParent_.createLabel();
        mSavingsCounter_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.8);
        mSavingsCounter_.setText("£100");
        mSavingsCounter_.setPosition(xPos, yPos);

        local moneyIcon = mParent_.createPanel();
        moneyIcon.setDatablock("coinsIcon");
        local moneySize = mSavingsCounter_.getSize().y * 0.8;
        moneyIcon.setSize(moneySize, moneySize);
        moneyIcon.setPosition(xPos, yPos);
        mSavingsCounter_.setPosition(mSavingsCounter_.getPosition() + Vec2(moneySize, -5));

        yPos += moneySize;

        {
            local withdrawButton = mParent_.createButton();
            withdrawButton.setText("Withdraw");
            withdrawButton.setPosition(xPos, yPos);
            withdrawButton.setDefaultFontSize(withdrawButton.getDefaultFontSize() * 1.8);
            local size = withdrawButton.getSize();
            withdrawButton.setSize(mInnerPanel_.getSize().x / 2, size.y * 1.5);
            withdrawButton.attachListenerForEvent(function(widget, action){
                print("withdrawing");
            }, _GUI_ACTION_PRESSED, this);

            local depositButton = mParent_.createButton();
            depositButton.setText("Deposit");
            depositButton.setPosition(xPos + mInnerPanel_.getSize().x / 2, yPos);
            depositButton.setDefaultFontSize(depositButton.getDefaultFontSize() * 1.8);
            local size = depositButton.getSize();
            depositButton.setSize(mInnerPanel_.getSize().x / 2, size.y * 1.5);

            ::evenOutButtonsForHeight([withdrawButton, depositButton]);
        }

    }

};