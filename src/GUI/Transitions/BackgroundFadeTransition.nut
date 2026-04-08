::ScreenManager.Transitions[ScreenTransition.BACKGROUND_FADE] = class extends ::Transition{

    mSkipAnimation_ = false;

    constructor(transitionData){
        base.constructor(transitionData);
    }

    function setup(incomingScreen, outgoingScreen, data){
        base.setup(incomingScreen, outgoingScreen, data);
        //Only animate if the incoming screen has a background window to fade.
        mSkipAnimation_ = (mIncomingScreen_.mBackgroundWindow_ == null);
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
