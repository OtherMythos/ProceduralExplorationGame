enum InventoryBusEvents{
    ITEM_HOVER_BEGAN,
    ITEM_HOVER_ENDED,
    ITEM_SELECTED,
};

::ScreenManager.Screens[Screen.INVENTORY_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mOverlayWindow_ = null;
    mInventoryGrid_ = null;
    mHoverInfo_ = null;
    mInventory_ = null;
    mMoneyCounter_ = null;
    mPlayerStats_ = null;

    mInventoryBus_ = null;

    HoverItemInfo = class{
        mHoverWin_ = null;

        mTitleLabel_ = null;
        mDescriptionLabel_ = null;

        mActive_ = false;

        constructor(overlayWindow){
            mHoverWin_ = overlayWindow.createWindow();
            mHoverWin_.setSize(400, 200);
            mHoverWin_.setHidden(true);
            mHoverWin_.setPosition(0, 0);
            mHoverWin_.setZOrder(200);
            mHoverWin_.setClickable(false);
            mHoverWin_.setKeyboardNavigable(false);

            local layout = _gui.createLayoutLine();
            mTitleLabel_ = mHoverWin_.createLabel();
            mTitleLabel_.setText(" ");
            layout.addCell(mTitleLabel_);

            mDescriptionLabel_ = mHoverWin_.createLabel();
            mDescriptionLabel_.setText(" ");
            mDescriptionLabel_.setSize(350, 200-20);
            layout.addCell(mDescriptionLabel_);

            layout.layout();
        }

        function update(){
            if(mActive_){
                local xx = _input.getMouseX().tofloat() / _window.getWidth().tofloat();
                local yy = _input.getMouseY().tofloat() / _window.getHeight().tofloat();
                setPosition((1920*xx), (1080*yy));
            }
        }

        function destroy(){
            _gui.destroy(actionMenuWin_);
        }

        function setVisible(vis){
            mActive_ = vis;
            mHoverWin_.setVisible(vis);
        }

        function setPosition(x, y){
            mHoverWin_.setPosition(x, y);
        }

        function setItem(item){
            mTitleLabel_.setText(item.getName());
            mDescriptionLabel_.setText(item.getDescription());
        }
    };

    InventoryContainer = class{
        mWindow_ = null;

        mLayoutTable_ = null;

        constructor(parentWindow, inventory, bus){

            mWindow_ = _gui.createWindow(parentWindow);
            mWindow_.setSize(100, 100);

            //mLayoutTable_.layout();
            mWindow_.sizeScrollToFit();
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setProportionVertical(3);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
        }

        function sizeInner(){
        }
    };

    InventoryInfoBus = class extends ::Screen.ScreenBus{
        constructor(){
            base.constructor();

        }
    };

    function receiveInventoryChangedEvent(id, data){

    }

    function setup(data){
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);

        mInventory_ = data.inventory;
        mPlayerStats_ = data.equipStats;

        mInventoryBus_ = InventoryInfoBus();
        mInventoryBus_.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        {
            local inventoryButton = mWindow_.createButton();
            inventoryButton.setText("Back");
            inventoryButton.setPosition(5, 25);
            inventoryButton.attachListenerForEvent(function(widget, action){
                ::ScreenManager.backupScreen(0);
            }, _GUI_ACTION_PRESSED, this);
        }

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Inventory", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        mMoneyCounter_.addToLayout(layoutLine);

        //local playerEquip = InventoryPlayerEquip(mWindow_, mPlayerStats_, mInventoryBus_);
        //playerEquip.addToLayout(layoutLine);

        //local container = InventoryContainer(mWindow_, mInventory_, mInventoryBus_);
        //container.addToLayout(layoutLine);

        mOverlayWindow_ = _gui.createWindow();
        mOverlayWindow_.setPosition(0, 0);
        mOverlayWindow_.setSize(_window.getWidth(), _window.getHeight());
        mOverlayWindow_.setVisualsEnabled(false);
        mOverlayWindow_.setConsumeCursor(false);
        mOverlayWindow_.setClipBorders(0, 0, 0, 0);

        local buttonCover = createButtonCover(mOverlayWindow_);
        mHoverInfo_ = HoverItemInfo(mOverlayWindow_);

        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(mInventoryBus_, mHoverInfo_, buttonCover);
        local inventoryWidth = mInventory_.getInventorySize() / 5;
        local inventoryHeight = mInventory_.getInventorySize() / inventoryWidth;
        mInventoryGrid_.initialise(mWindow_, mOverlayWindow_, inventoryWidth, inventoryHeight);
        mInventoryGrid_.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();

        mInventoryGrid_.notifyLayout();
        mInventoryGrid_.setNewGridIcons(mInventory_.mInventoryItems_);
        //container.sizeInner();
    }

    function createButtonCover(win){
        local cover = win.createPanel();
        cover.setSize(64, 64);
        cover.setDatablock("gui/inventoryHighlightCover");
        cover.setHidden(true);
        cover.setZOrder(155);
        cover.setClickable(false);
        cover.setKeyboardNavigable(false);

        return cover;
    }

    function busCallback(event, data){
        if(event == InventoryBusEvents.ITEM_SELECTED){
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_BEGAN){
            processItemHover(data);
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_ENDED){
            processItemHover(null);
        }
    }

    function processItemHover(idx){
        if(idx == null){
            setHoverMenuToItem(null);
            return;
        }
        local item = mInventory_.getItemForIdx(idx);
        setHoverMenuToItem(item);
    }
    function setHoverMenuToItem(item){
        //TODO this might be getting called twice.
        //print(item);
        if(item == null){
            mHoverInfo_.setVisible(false);
            return;
        }
        mHoverInfo_.setItem(item);
        mHoverInfo_.setVisible(true);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mOverlayWindow_.setZOrder(idx+1);
    }

    function shutdown(){
        mMoneyCounter_.shutdown();
        base.shutdown();
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent);
    }

    function update(){
        //mInventoryGrid_.update();
        mHoverInfo_.update();
    }
};

_doFile("res://src/GUI/Widgets/InventoryGrid.nut");