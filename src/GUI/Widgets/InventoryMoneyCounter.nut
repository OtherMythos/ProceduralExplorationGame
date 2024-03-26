::GuiWidgets.InventoryMoneyCounter <- class extends ::GuiWidgets.InventoryBaseCounter{

    destroyed = false;
    constructor(parent){
        mBaseLabel_ = "Money";
        mCurrentAnim_ = ::Base.mPlayerStats.mInventory_.getMoney();
        setup(parent);

        _event.subscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.subscribe(Event.MONEY_CHANGED, receiveMoneyChanged, this);
    }

    function receiveMoneyAnimFinished(id, data){
        addForAnimation(data);
    }
    function receiveMoneyChanged(id, data){
        if(destroyed) return;
        setValueCancelAnim(data);
    }

    function shutdown(){
        _event.unsubscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.unsubscribe(Event.MONEY_CHANGED, receiveMoneyChanged, this);
        destroyed = true;
    }
};