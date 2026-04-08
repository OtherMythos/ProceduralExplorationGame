//Base class for all screen transition effects.
::Transition <- class{
    mTransitionData_ = null;
    mIncomingScreen_ = null;
    mOutgoingScreen_ = null;

    constructor(transitionData){
        mTransitionData_ = transitionData;
    }

    /**
     * Called once when the transition begins.
     * @param incomingScreen The screen animating in.
     * @param outgoingScreen The screen animating out (may be null if no prior screen existed).
     * @param data Optional per-transition parameterisation data.
     */
    function setup(incomingScreen, outgoingScreen, data){
        mIncomingScreen_ = incomingScreen;
        mOutgoingScreen_ = outgoingScreen;
    }

    function update(){
    }

    //Returns true when the transition has finished and should be destroyed.
    function isComplete(){
        return true;
    }

    //Finalises the transition and destroys the outgoing screen.
    function shutdown(){
        if(mOutgoingScreen_ != null){
            mOutgoingScreen_.shutdown();
            mOutgoingScreen_ = null;
        }
    }
};
