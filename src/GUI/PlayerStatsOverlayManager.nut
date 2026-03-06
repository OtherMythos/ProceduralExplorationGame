//Manages the PlayerBasicStatsWidget in its own overlay window, allowing its Z order
//to be updated dynamically based on which screen is currently at the foreground.
//ExplorationScreen calls setup/shutdown to own the widget lifecycle. Both ExplorationScreen
//and InventoryScreen register/unregister themselves so the overlay Z stays above
//whichever registered screen is currently on top.
::PlayerStatsOverlayManager <- {

    mOverlayWindow_ = null
    mStatsWidget_ = null
    mScreenStack_ = null

    function setup(){
        mScreenStack_ = [];
        mOverlayWindow_ = _gui.createWindow("PlayerStatsOverlay");
        mOverlayWindow_.setSize(_window.getWidth(), _window.getHeight());
        mOverlayWindow_.setPosition(0, 0);
        mOverlayWindow_.setVisualsEnabled(false);
        mOverlayWindow_.setSkinPack("WindowSkinNoBorder");
        mOverlayWindow_.setClickable(false);

        mStatsWidget_ = ::GuiWidgets.PlayerBasicStatsWidget();
        mStatsWidget_.setup(mOverlayWindow_);
    }

    function shutdown(){
        if(mStatsWidget_ != null){
            mStatsWidget_.shutdown();
            mStatsWidget_ = null;
        }
        if(mOverlayWindow_ != null){
            _gui.destroy(mOverlayWindow_);
            mOverlayWindow_ = null;
        }
        mScreenStack_ = null;
    }

    //Register or update a screen in the Z order stack.
    //If the screen name is already present, its Z value is updated in place.
    //Otherwise the screen is pushed onto the top of the stack.
    function registerScreen(name, z){
        if(mScreenStack_ == null) return;
        foreach(entry in mScreenStack_){
            if(entry.name == name){
                entry.z = z;
                updateWidgetZ_();
                return;
            }
        }
        mScreenStack_.append({name = name, z = z});
        updateWidgetZ_();
    }

    //Unregister a screen from the Z order stack.
    //Prints a warning if the screen being removed is not at the top of the stack,
    //indicating an unexpected shutdown order.
    function unregisterScreen(name){
        if(mScreenStack_ == null || mScreenStack_.len() == 0){
            print("PlayerStatsOverlayManager: WARNING - unregisterScreen called on empty stack for: " + name);
            return;
        }
        local top = mScreenStack_.top();
        if(top.name != name){
            print("PlayerStatsOverlayManager: WARNING - expected top screen '" + top.name + "' but got '" + name + "'");
        }
        mScreenStack_.pop();
        updateWidgetZ_();
    }

    function getWidget(){
        return mStatsWidget_;
    }

    function updateWidgetZ_(){
        if(mOverlayWindow_ == null) return;
        if(mScreenStack_ == null || mScreenStack_.len() == 0) return;
        mOverlayWindow_.setZOrder(mScreenStack_.top().z + 1);
    }
}
