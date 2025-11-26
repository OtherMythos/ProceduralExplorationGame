enum BankDepositWithdrawAmount{
    VAL_100,
    VAL_200,
    VAL_500,
    VAL_1000,
    EVERYTHING,

    MAX
};

::ScreenManager.Screens[Screen.BANK_DEPOSIT_WITHDRAW_SCREEN] = class extends ::Screen{

    mSettingsWidgets_ = null;
    mDeposit_ = false;
    mCalculationLabel_ = null;
    mActionButton_ = null;

    mSelectedAmount_ = BankDepositWithdrawAmount.EVERYTHING;

    function setup(data){

        mDeposit_ = data.deposit;

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        createBackgroundScreen_();
        createBackgroundCloseButton_();

        mWindow_ = _gui.createWindow("SettingsScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setBreadthFirst(true);
        mWindow_.setZOrder(61);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText(getTitleString_());
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        layoutLine.addCell(title);

        local description = mWindow_.createLabel();
        description.setText(getDescriptionString_());
        description.sizeToFit(mWindow_.getSizeAfterClipping().x);
        layoutLine.addCell(description);

        for(local i = 0; i < BankDepositWithdrawAmount.MAX; i++){
            local button = mWindow_.createButton();
            button.setText(wrapOptionLabel_(i));
            button.attachListenerForEvent(depositAmountButtonCallback, _GUI_ACTION_PRESSED, this);
            button.setUserId(i);

            local hasEnoughMoney = checkIsOptionAvailable_(i);

            button.setDisabled(!hasEnoughMoney);
            layoutLine.addCell(button);
            if(i==0) button.setFocus();
        }

        local calculationLabel = mWindow_.createLabel();
        mCalculationLabel_ = calculationLabel;
        updateCalculationLabel_();
        layoutLine.addCell(calculationLabel);

        local actionButton = mWindow_.createButton();
        actionButton.setText(getTitleString_());
        actionButton.attachListenerForEvent(actionButtonCallback, _GUI_ACTION_PRESSED, this);
        actionButton.setSize(mWindow_.getSizeAfterClipping().x, actionButton.getSize().y * 1.4);
        actionButton.setPosition(0, mWindow_.getSizeAfterClipping().y - actionButton.getSize().y);
        mActionButton_ = actionButton;

        layoutLine.setSize(mWindow_.getSizeAfterClipping());
        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.layout();

        updateActionButtonActive_();
    }

    function checkIsOptionAvailable_(option){
        local amount = getAmountForOption_(option);
        local moneyVal = getCurrentMoneyValue();
        local hasEnoughMoney = (moneyVal >= amount);
        if(moneyVal == 0 && amount == 0){
            hasEnoughMoney = false;
        }
        return hasEnoughMoney;
    }

    function getCurrentMoneyValue(){
        if(mDeposit_){
            return ::Base.mPlayerStats.getMoney();
        }else{
            return ::Base.mPlayerStats.getBankMoney();
        }
    }

    function depositAmountButtonCallback(widget, action){
        mSelectedAmount_ = widget.getUserId();
        printf("Changing withdraw deposit amount %i", mSelectedAmount_);

        updateActionButtonActive_();
        updateCalculationLabel_();
    }

    function updateActionButtonActive_(){
        local hasEnoughMoney = checkIsOptionAvailable_(mSelectedAmount_);
        mActionButton_.setDisabled(!hasEnoughMoney);
    }

    function getAmountForOption_(option){
        switch(option){
            case BankDepositWithdrawAmount.VAL_100: return 100;
            case BankDepositWithdrawAmount.VAL_200: return 200;
            case BankDepositWithdrawAmount.VAL_500: return 500;
            case BankDepositWithdrawAmount.VAL_1000: return 1000;
            case BankDepositWithdrawAmount.EVERYTHING:{
                if(mDeposit_){
                    print(::Base.mPlayerStats.getMoney());
                    return ::Base.mPlayerStats.getMoney();
                }else{
                    return ::Base.mPlayerStats.getBankMoney();
                }
            }
            default:
                return 0;
        };
    }
    function getLabelForOption_(option){
        if(option == BankDepositWithdrawAmount.EVERYTHING){
            return "Everything";
        }
        return getAmountForOption_(option).tostring();
    }
    function wrapOptionLabel_(option){
        local ret = getLabelForOption_(option);
        if(option == BankDepositWithdrawAmount.EVERYTHING){
            return ret;
        }
        return "£" + ret;
    }

    function getStringForCalculationLabel_(){
        if(!checkIsOptionAvailable_(mSelectedAmount_)){
            return format("You don't have enough money to %s anything.", getTitleString_().tolower());
        }

        local text = format("%s %s?", getTitleString_(), wrapOptionLabel_(mSelectedAmount_).tolower());
        if(mDeposit_){
            text += "\n";
            text += "+ £100 deposit fee"
        }

        return text;
    }
    function updateCalculationLabel_(){
        local text = getStringForCalculationLabel_();

        mCalculationLabel_.setText(text);
        mCalculationLabel_.sizeToFit(mWindow_.getSizeAfterClipping().x);
    }

    function actionButtonCallback(widget, action){
        _actuateBankAction();
        closeScreen();
    }

    function _bankAction(amount){
        if(mDeposit_){
            ::Base.mPlayerStats.moveMoneyFromInventoryToBank(amount);
        }else{
            ::Base.mPlayerStats.moveMoneyFromBankToInventory(amount);
        }
    }
    function _actuateBankAction(){
        _bankAction(getAmountForOption_(mSelectedAmount_));
    }

    function getTitleString_(){
        return mDeposit_ ? "Deposit" : "Withdraw";
    }

    function getDescriptionString_(){
        return mDeposit_ ?
            "Choose how much you'd like to deposit. £100 charge is applied when depositing money." :
            "Choose how much you'd like to withdraw.";
    }
}