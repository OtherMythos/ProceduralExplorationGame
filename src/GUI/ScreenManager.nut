::ScreenManager <- {

    "mTargetScreen_": null,

    function setup(){

    }

    /**
     * Transition to a new screen.
     */
    function transitionToScreen(screenObject, transitionEffect = null){
        if(mTargetScreen_ != null){
            mTargetScreen_.shutdown();
        }
        mTargetScreen_ = screenObject();

        mTargetScreen_.setup();
    }
};