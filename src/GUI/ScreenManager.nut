::ScreenManager <- {

    "mActiveScreen_": null,

    function setup(){

    }

    /**
     * Transition to a new screen.
     */
    function transitionToScreen(screenObject, transitionEffect = null){
        if(mActiveScreen_ != null){
            mActiveScreen_.shutdown();
        }
        mActiveScreen_ = screenObject;

        mActiveScreen_.setup();
    }

    function update(){
        if(mActiveScreen_ != null) mActiveScreen_.update();
    }
};