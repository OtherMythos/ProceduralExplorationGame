::GuiWidgets.InventoryMoneyCounter <- class extends ::GuiWidgets.InventoryBaseCounter{

    constructor(parent){
        mBaseLabel_ = "Money";
        mCurrentAnim_ = ::Base.mInventory.getMoney();
        setup(parent);

        _event.subscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.subscribe(Event.MONEY_CHANGED, receiveMoneyChanged, this);
    }

    function receiveMoneyAnimFinished(id, data){
        addForAnimation(data);
    }
    function receiveMoneyChanged(id, data){
        setValueCancelAnim(data);
    }

    function shutdown(){
        _event.unsubscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.unsubscribe(Event.MONEY_CHANGED, receiveMoneyAnimFinished, this);
    }
};