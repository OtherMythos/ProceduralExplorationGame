
/**
A class to handle actions which can be executed by the player.
These actions might be things like 'talk', 'buy things from', etc.
*/
::ActionManager <- class{

    mActionSlots_ = null

    /**
    Abstract a single action slot.
    Slots can store many actions, for instance if the player has multiple talkable entities within their collision radius.
    */
    ActionSlot = class{
        mData = null
        mTypes = null
        mIds = null

        constructor(){
            mData = [];
            mTypes = [];
            mIds = [];
        }

        function register(type, data, id){
            mData.append(data);
            mTypes.append(type);
            mIds.append(id);
        }

        function unset(id){
            for(local i = 0; i < mIds.len(); i++){
                if(mIds[i] == id){
                    mData.remove(i);
                    mTypes.remove(i);
                    mIds.remove(i);
                    return;
                }
            }
        }

        function populated(){
            return mData.len() > 0;
        }

        function _tostring(){
            if(mData.len() <= 0) return " ";

            return ::ActionSlotTypeString[mTypes[0]];
        }
    }

    constructor(){
        mActionSlots_ = array(ACTION_MANAGER_NUM_SLOTS);
        for(local i = 0; i < ACTION_MANAGER_NUM_SLOTS; i++){
            mActionSlots_[i] = ActionSlot();
        }
    }

    /**
    Register an action to a specific slot.
    */
    function registerAction(type, slot, data, uniqueId){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);

        mActionSlots_[slot].register(type, data, uniqueId);
        notifyActionChange();
    }

    /**
    Remove the action in the requested slot.
    */
    function unsetAction(slot, id){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);

        mActionSlots_[slot].unset(id);
        notifyActionChange();
    }

    /**
    Execute whatever action is in the target slot.
    */
    function executeSlot(slot){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);
        local target = mActionSlots_[slot];
        if(!target.populated()) return;

        local data = target.mData[0];
        switch(target.mTypes[0]){
            case ActionSlotType.TALK_TO:{
                //::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog");
                ::Base.mExplorationLogic.beginDialog(data.path, data.block);
                break;
            }
            default:{
                throw "Attempted to execute an invalid action slot.";
            }
        }
    }

    /**
    Notify any interested parties that the actions changed
    */
    function notifyActionChange(){
        _event.transmit(Event.ACTIONS_CHANGED, this.mActionSlots_);
    }
};