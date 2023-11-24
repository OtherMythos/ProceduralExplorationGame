function start(){
    _doFile("res://src/Versions.nut");
    _doFile("res://src/Constants.nut");
    _doFile("res://src/MapGen/Exploration/Generator/MapConstants.nut");

    _doFile("res://src/System/CompositorManager.nut");
    ::CompositorManager.setup();

    _doFile("res://src/Util/StateMachine.nut");
    _doFile("res://src/Util/CombatStateMachine.nut");

    _gui.setScrollSpeed(5.0);

    local winSize = Vec2(_window.getWidth(), _window.getHeight());
    _gui.setCanvasSize(winSize, winSize);

    _doFile("res://src/Base.nut");
    ::Base.setup();
}

function update(){
    ::Base.update();
}

function end(){

}

function sceneSafeUpdate(){
    if(::Base.mExplorationLogic != null){
        //::Base.mExplorationLogic.sceneSafeUpdate();
        //::Base.mExplorationLogic.mCurrentWorld_.sceneSafeUpdate();
        ::Base.mExplorationLogic.sceneSafeUpdate();
    }
}