::GuiWidgets.InventoryMoneyCounter <- class{
    mMoneyLabel_ = null;

    mMoneyCurrentAnim_ = 0;
    mMoneyAnimTo_ = 0;
    mMoneyAnimating_ = false;

    constructor(parent){
        mMoneyLabel_ = parent.createLabel();
        mMoneyCurrentAnim_ = ::Base.mInventory.getMoney();
        mMoneyAnimTo_ = mMoneyCurrentAnim_;
        setLabelTo(mMoneyCurrentAnim_);

        mMoneyLabel_.setZOrder(100);

        _event.subscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
    }

    function receiveMoneyAnimFinished(id, data){
        addMoneyForAnimation(data);
    }

    function setLabelTo(moneyVal){
        mMoneyLabel_.setText(format("money: %i", moneyVal));
        //TODO do this properly with layouts.
        mMoneyLabel_.setPosition(_window.getWidth() - mMoneyLabel_.getSize().x, 200);
    }

    function shutdown(){
        _event.unsubscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
    }

    function addToLayout(layout){
        layout.addCell(mMoneyLabel_);
    }

    function addMoneyForAnimation(amount){
        mMoneyAnimTo_ += amount;
        mMoneyAnimating_ = true;
    }

    function getPosition(){
        return ::EffectManager.getWorldPositionForWindowPos(mMoneyLabel_.getCentre());
    }

    function update(){
        if(mMoneyAnimTo_ > mMoneyCurrentAnim_){
            mMoneyCurrentAnim_+=4;
            if(mMoneyCurrentAnim_ > mMoneyAnimTo_){
                mMoneyCurrentAnim_ = mMoneyAnimTo_;
            }
            setLabelTo(mMoneyCurrentAnim_);
        }
    }
};