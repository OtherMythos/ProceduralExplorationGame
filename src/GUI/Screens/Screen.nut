//Base class
::Screen <- class{
    mWindow_ = null;
    mScreenData_ = null;
    mLayerIdx = 0;
    mCustomSize_ = false;
    mCustomPosition_ = false;

    mBackgroundWindow_ = null;
    mCloseButtonWindow_ = null;

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
        //if(mBackgroundWindow_) _gui.destroy(mBackgroundWindow_);
        if(mBackgroundWindow_){
            //To workaround some lifecycle issues, destruction is scheduled.
            ::ScreenManager.scheduleDestruction(mBackgroundWindow_);
            mBackgroundWindow_.setPosition(-2000, -2000);
        }
        if(mCloseButtonWindow_){
            ::ScreenManager.scheduleDestruction(mCloseButtonWindow_);
            mCloseButtonWindow_.setPosition(-2000, -2000);
        }
        _gui.destroy(mWindow_);

        mBackgroundWindow_ = null;
        mCloseButtonWindow_ = null;
        mWindow_ = null;
    }

    function createBackgroundScreen_(){
        local win = _gui.createWindow("ScreenBackgroundScreen");
        win.setSize(_window.getWidth(), _window.getHeight());
        win.setVisualsEnabled(true);

        mBackgroundWindow_ = win;
    }

    function createBackgroundCloseButton_(){
        assert(mBackgroundWindow_ != null);
        local backgroundCloseButton = mBackgroundWindow_.createButton();
        backgroundCloseButton.setSize(mBackgroundWindow_.getSize());
        backgroundCloseButton.setVisualsEnabled(false);
        backgroundCloseButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.SELECTION);
            closeScreen();
        }, _GUI_ACTION_PRESSED, this);
    }

    function createScreenCloseButton(options=null){
        if(mCloseButtonWindow_ != null){
            return null; // Already created
        }

        local margin = 10;
        local insets = _window.getScreenSafeAreaInsets();
        local buttonSize = Vec2(64, 64);

        // Allow options to override defaults
        if(options != null){
            if(options.rawin("margin")) margin = options.rawget("margin");
            if(options.rawin("size")) buttonSize = options.rawget("size");
            if(options.rawin("iconSize")) iconSize = options.rawget("iconSize");
        }

        // Create a separate window for the close button
        mCloseButtonWindow_ = _gui.createWindow("ScreenCloseButtonWindow");
        mCloseButtonWindow_.setSize(buttonSize);
        mCloseButtonWindow_.setClipBorders(0, 0, 0, 0);
        mCloseButtonWindow_.setVisualsEnabled(false);

        local closeButton = ::IconButtonComplex(mCloseButtonWindow_, {
            "icon": "closeCrossIcon",
            "iconSize": Vec2(48, 48),
            "iconPosition": Vec2(8, 8),
            "usePanelForButton": false,
            "skinPack": "Button_red"
        });

        closeButton.setSize(buttonSize);
        closeButton.setPosition(Vec2(0, 0));
        local topRightPos = Vec2(::drawable.x - buttonSize.x - margin, margin + insets.top);
        //closeButton.setPosition(topRightPos);

        closeButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            closeScreen();
        }, _GUI_ACTION_PRESSED, this);

        return closeButton;
    }

    function setZOrder(idx){
        if(mBackgroundWindow_) mBackgroundWindow_.setZOrder(idx-1);
        if(mWindow_ != null) mWindow_.setZOrder(idx);
        if(mCloseButtonWindow_ != null) mCloseButtonWindow_.setZOrder(idx+1);
    }

    function setPositionCentre(x, y){
        if(mWindow_ == null) return;
        mWindow_.setCentre(x, y);
        positionCloseButton_();
    }
    function setSize(width, height){
        if(mWindow_ == null) return;
        mWindow_.setSize(width, height);
    }

    function positionCloseButton_(){
        if(mCloseButtonWindow_ == null) return;
        local closeSize = mCloseButtonWindow_.getSize();
        local offsetSize = closeSize * 0.25;
        local pos = mWindow_.getPosition();
        pos.x += mWindow_.getSize().x;
        pos.x -= offsetSize.x;
        pos.y += offsetSize.y;
        mCloseButtonWindow_.setCentre(pos);
    }

    function notifyResize(){
        if(mWindow_ != null) _gui.destroy(mWindow_);
        if(mBackgroundWindow_ != null) _gui.destroy(mBackgroundWindow_);
        mWindow_ = null;

        recreate_();
    }

    function closeScreen(){
        ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
    }

    function recreate_(){
        recreate();
    }
    function recreate(){

    }
};