::CombatStateMachine <- class{
    currentState = null;
    entity = null;

    function update(e, data){
        if(currentState == null) return;
        currentState.update(this, e, data);
    }

    function switchState(newState){
        if(currentState != null && "end" in currentState) currentState.end(this, entity);
        currentState = newState;
        if("start" in newState) newState.start(this, entity);
    }

    //TODO remove the 'e'
    function notify(id, e=null, data = null){
        if("notify" in currentState) currentState.notify(this, id, entity, data);
    }
};
