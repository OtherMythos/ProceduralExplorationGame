::GuiWidgets.InventoryEXPCounter <- class extends ::GuiWidgets.InventoryBaseCounter{

    constructor(parent, parentObj=null){
        mBaseLabel_ = "EXP orbs";
        setup(parent, parentObj);

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