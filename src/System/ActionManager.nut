
/**
A class to handle actions which can be executed by the player.
These actions might be things like 'talk', 'buy things from', etc.
*/
::ActionManager <- class{

    mActionSlots_ = null
    mActiveActions_ = null

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
        mActionSlots_ = {};
    }

    function setup(){
        _event.subscribe(Event.WORLD_DESTROYED, processWorldDestroyed, this);
        _event.subscribe(Event.ACTIVE_WORLD_CHANGE, processActiveWorldChange, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.WORLD_DESTROYED, processWorldDestroyed, this);
        _event.unsubscribe(Event.ACTIVE_WORLD_CHANGE, processActiveWorldChange, this);
    }

    function processWorldDestroyed(id, data){
        destroySlotsForWorld(data.getWorldId());
    }
    function processActiveWorldChange(id, data){
        createSlotsForWorld(data.getWorldId());
    }

    function createSlotsForWorld(worldId){
        local actionSlots = array(ACTION_MANAGER_NUM_SLOTS);
        for(local i = 0; i < ACTION_MANAGER_NUM_SLOTS; i++){
            actionSlots[i] = ActionSlot();
        }
        mActionSlots_.rawset(worldId, actionSlots);
        mActiveActions_ = actionSlots;
        notifyActionChange();
    }
    function destroySlotsForWorld(worldId){
        mActionSlots_.rawdelete(worldId);
    }

    /**
    Register an action to a specific slot.
    */
    function registerAction(type, slot, data, uniqueId){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);

        mActiveActions_[slot].register(type, data, uniqueId);
        notifyActionChange();
    }

    /**
    Remove the action in the requested slot.
    */
    function unsetAction(slot, id){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);

        mActiveActions_[slot].unset(id);
        notifyActionChange();
    }

    /**
    Execute whatever action is in the target slot.
    */
    function executeSlot(slot){
        assert(slot >= 0 && slot < ACTION_MANAGER_NUM_SLOTS);
        local target = mActiveActions_[slot];
        if(!target.populated()) return;

        local data = target.mData[0];
        switch(target.mTypes[0]){
            case ActionSlotType.TALK_TO:{
                //::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog");
                ::Base.mExplorationLogic.beginDialog(data.path, data.block);
                break;
            }
            case ActionSlotType.VISIT:{
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                if(world.getWorldType() == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
                    local targetMap = ::getMapNameForPlace_(data);
                    world.visitPlace(targetMap);
                }
                break;
            }
            case ActionSlotType.ENTER:
            case ActionSlotType.ASCEND:
            case ActionSlotType.DESCEND:{
                if(data.rawin("popWorld")){
                    ::Base.mExplorationLogic.popWorld();
                }else{
                    local worldType = data.worldType;
                    local worldInstance = ::Base.mExplorationLogic.createWorldInstance(worldType, data);
                    ::Base.mExplorationLogic.pushWorld(worldInstance);
                }
                break;
            }
            case ActionSlotType.END_EXPLORATION:{
                ::Base.mExplorationLogic.gatewayEndExploration();
                break;
            }
            case ActionSlotType.ITEM_SEARCH:{
                //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, data), null, 2);
                ::Base.mExplorationLogic.mCurrentWorld_.showInventory(data);
                break;
            }
            case ActionSlotType.PICK:{
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                local manager = world.getEntityManager();
                if(manager.entityValid(data)){
                    manager.destroyEntity(data, EntityDestroyReason.CONSUMED);
                }
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
        _event.transmit(Event.ACTIONS_CHANGED, this.mActiveActions_);
    }
};
