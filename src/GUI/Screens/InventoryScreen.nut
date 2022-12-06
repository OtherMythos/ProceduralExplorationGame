enum InventoryBusEvents{
    ITEM_SELECTED,
};

::InventoryScreen <- class extends ::Screen{

    mWindow_ = null;
    mInventory_ = null;
    mMoneyCounter_ = null;

    mInventoryBus_ = null;

    /**
     * An entry in the inventory screen.
     */
    InventoryItem = class{
        mButtonObject_ = null;
        //TODO it's wasteful to keep a copy of this per instance.
        //Unfortunately I can't do what I need with static variables.
        //Find a way to improve this approach.
        mBus_ = null;

        constructor(parentWindow, id, bus){
            mBus_ = bus;

            mButtonObject_ = parentWindow.createButton();
            mButtonObject_.setText(" ");
            mButtonObject_.setUserId(id);
            mButtonObject_.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
        }

        function buttonPressed(widget, action){
            mBus_.notifyEvent(InventoryBusEvents.ITEM_SELECTED, widget.getUserId());
        }

        function setItem(item){
            if(item == Item.NONE){
                mButtonObject_.setHidden(true);
                return;
            }
            mButtonObject_.setText(::Items.itemToName(item));
            mButtonObject_.setHidden(false);
        }

        function addToLayout(layout){
            layout.addCell(mButtonObject_);
        }
    };

    InventoryContainer = class{
        mWindow_ = null;

        mLayoutTable_ = null;
        buttonThing = null;

        constructor(parentWindow, inventory, bus){

            mWindow_ = _gui.createWindow(parentWindow);
            mWindow_.setSize(100, 100);

            mLayoutTable_ = _gui.createLayoutLine();

            for(local i = 0; i < inventory.mInventoryItems_.len(); i++){
                local item = ::InventoryScreen.InventoryItem(mWindow_, i, bus);
                item.setItem(inventory.mInventoryItems_[i]);
                item.addToLayout(mLayoutTable_);
            }

            mLayoutTable_.layout();
            mWindow_.sizeScrollToFit();
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setProportionVertical(1);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
        }

        function sizeInner(){
            //mLayoutTable_.setSize(mWindow_.getSize());
            //mLayoutTable_.layout();
            //mWindow_.sizeScrollToFit();
            //mWindow_.setMaxScroll(mWindow_.getSize());

            //TODO make this sized programmatically.
            mWindow_.setSize(mWindow_.getSize().x, 600);
            //mWindow_.setMaxScroll(0, 1200);
            //mWindow_.sizeScrollToFit();
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

        local container = InventoryContainer(mWindow_, mInventory_, mInventoryBus_);
        container.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();

        container.sizeInner();
    }

    function busCallback(event, data){
        if(event == InventoryBusEvents.ITEM_SELECTED){
            local item = mInventory_.getItemForIdx(data);
            //TODO fill out with whatever info needs to be passed.
            ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, {}));
            //ItemInfoScreen(item, ItemInfoMode.USE, data));
        }
    }

    function shutdown(){
        mMoneyCounter_.shutdown();
        base.shutdown();
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent);
    }

    function update(){

    }
};