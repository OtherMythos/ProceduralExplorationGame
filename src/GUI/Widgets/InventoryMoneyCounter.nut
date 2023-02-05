::GuiWidgets.InventoryMoneyCounter <- class{
    mMoneyLabel_ = null;

    constructor(parent){
        mMoneyLabel_ = parent.createLabel();
        setLabelTo(::Base.mInventory.getMoney());

        _event.subscribe(Event.MONEY_CHANGED, receiveMoneyChange, this);
    }

    function receiveMoneyChange(id, data){
        setLabelTo(data);
    }

    function setLabelTo(moneyVal){
        mMoneyLabel_.setText(format("money: %i", moneyVal));
    }

    function shutdown(){
        _event.unsubscribe(Event.MONEY_CHANGED, receiveMoneyChange, this);
    }

    function addToLayout(layout){
        layout.addCell(mMoneyLabel_);
    }

    function getPosition(){
        return ::EffectManager.getWorldPositionForWindowPos(mMoneyLabel_.getCentre())
    }
};