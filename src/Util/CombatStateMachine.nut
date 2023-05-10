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

    function notify(id, e, data = null){
        if("notify" in currentState) currentState.notify(this, id, e, data);
    }
};
