//Direction the incoming screen slides from.
enum TransitionDirection{
    UP,
    DOWN,
    LEFT,
    RIGHT
};

::ScreenManager.Transitions[ScreenTransition.SLIDE] = class extends ::Transition{

    constructor(transitionData){
        base.constructor(transitionData);
    }

    function setup(incomingScreen, outgoingScreen, data){
        base.setup(incomingScreen, outgoingScreen, data);
        //Animation implementation deferred to next batch.
    }

    function update(){
    }

    function isComplete(){
        return true;
    }

    function shutdown(){
        base.shutdown();
    }
};
