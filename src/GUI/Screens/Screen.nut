//Base class
::Screen <- class{
    mWindow_ = null;
    mScreenData_ = null;
    mLayerIdx = 0;
    mCustomSize_ = false;
    mCustomPosition_ = false;

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
                if(i == null) continue;
                i(busEvent, data);
            }
        }

        function registerCallback(callback, env=null){
            local target = callback;
            if(env){
                target = callback.bindenv(env);
            }
            local id = mCallbacks_.len();
            mCallbacks_.append(target);
            return id;
        }

        function deregisterCallback(id){
            mCallbacks_[id] = null;
        }
    };

    constructor(screenData){
        mScreenData_ = screenData;
    }

    function setup(data){
        recreate();
    }

    function getScreenData(){
        return mScreenData_;
    }

    function start(){

    }

    function update(){

    }

    function shutdown(){
        if(mBackgroundWindow_) _gui.destroy(mBackgroundWindow_);
        _gui.destroy(mWindow_);

        mBackgroundWindow_ = null;
        mWindow_ = null;
    }

    function createBackgroundScreen_(){
        local win = _gui.createWindow("ScreenBackgroundScreen");
        win.setSize(_window.getWidth(), _window.getHeight());
        win.setVisualsEnabled(true);

        mBackgroundWindow_ = win;
    }

    function setZOrder(idx){
        if(mBackgroundWindow_) mBackgroundWindow_.setZOrder(idx-1);
        if(mWindow_ != null) mWindow_.setZOrder(idx);
    }

    function setPositionCentre(x, y){
        if(mWindow_ == null) return;
        mWindow_.setCentre(x, y);
    }
    function setSize(width, height){
        if(mWindow_ == null) return;
        mWindow_.setSize(width, height);
    }

    function notifyResize(){
        if(mWindow_ != null) _gui.destroy(mWindow_);
        if(mBackgroundWindow_ != null) _gui.destroy(mBackgroundWindow_);
        mWindow_ = null;

        recreate_();
    }

    function recreate_(){
        recreate();
    }
    function recreate(){

    }
};