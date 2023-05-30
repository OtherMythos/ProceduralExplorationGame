//Base class
::Screen <- class{
    mWindow_ = null;
    mScreenData_ = null;
    mLayerIdx = 0;

    mBackgroundWindow_ = null;

    /**
     * A class to facilitate communication between the parts of the screen systems.
     *
     * Objects are provided this bus class which deals with facilitating callbacks.
     * This object is more local than the global event system, as these events only effect the specific screen.
     * Classes will override this for any further functionality requirements.
     * Separating logic out through this bus allows much easier automated testing as well as a decoupled architecture.
     */
    ScreenBus = class{
        mCallbacks_ = null;

        constructor(){
            mCallbacks_ = [];
        }

        function notifyEvent(busEvent, data){
            foreach(i in mCallbacks_){
                i(busEvent, data);
            }
        }

        function registerCallback(callback, env=null){
            local target = callback;
            if(env){
                target = callback.bindenv(env);
            }
            mCallbacks_.append(target);
        }
    };

    constructor(screenData){
        mScreenData_ = screenData;
    }

    function getScreenData(){
        return mScreenData_;
    }

    function start(){

    }

    function update(){

    }

    function shutdown(){
        _gui.destroy(mWindow_);
    }

    function createBackgroundScreen_(){
        local win = _gui.createWindow();
        win.setSize(_window.getWidth(), _window.getHeight());
        win.setVisualsEnabled(true);

        return win;
    }

    function setZOrder(idx){
        if(mBackgroundWindow_) mBackgroundWindow_.setZOrder(idx-1);
        mWindow_.setZOrder(idx);
    }
};