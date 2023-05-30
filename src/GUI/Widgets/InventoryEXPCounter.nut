::GuiWidgets.InventoryEXPCounter <- class extends ::GuiWidgets.InventoryBaseCounter{

    constructor(parent){
        mBaseLabel_ = "EXP orbs";
        setup(parent);

        mCurrentAnim_ = 0;

        _event.subscribe(Event.EXP_ORBS_ADDED, receiveEXPAnimFinished, this);
    }

    function receiveEXPAnimFinished(id, data){
        addForAnimation(data);
    }

    function shutdown(){
        _event.unsubscribe(Event.EXP_ORBS_ADDED, receiveEXPAnimFinished, this);
    }
};