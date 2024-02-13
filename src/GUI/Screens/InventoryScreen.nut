enum InventoryBusEvents{
    ITEM_SELECTED,
};

const INVENTORY_WIDTH = 5;
const INVENTORY_SIZE = 25; //5*5
const EQIPABLE_INVENTORY_SIZE = 5;

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

        function destroy(){
            _gui.destroy(actionMenuWin_);
        }

        function setVisible(vis){
            mHoverWin_.setHidden(!vis);
        }

        function setPosition(x, y){
            mHoverWin_.setPosition(x, y);
        }

        function setItem(item){
            mTitleLabel_.setText("test" + item.getName());
            //mTitleLabel_.setText(::_getInventoryItemName(item));
            //mDescriptionLabel_.setText( ::_itemContent[item][ItemContentType.DESCRIPTION], false );
        }
    };

    InventoryGrid = class{
        mResolvedPos_ = null;

        mHoverInfo_ = null;
        mButtonCover_ = null;
        mWindow_ = null;
        mOverlayWin_ = null;

        mWidgets_ = null;

        mSelectedX_ = 0;
        mSelectedY_ = 0;

        mLayout_ = null;
        mItemHovered_ = false;

        constructor(hoverInfo, buttonCover){
            //parentGridType_ = gridType;
            mHoverInfo_ = hoverInfo;
            mButtonCover_ = buttonCover;
            //actionMenu_ = actionMenu;

            mWidgets_ = [];
        }

        function getSelectedIdx(){
            return mSelectedX_ + mSelectedY_ * INVENTORY_WIDTH;
        }

        /**
        Update the grid with icons based on an array of items.
        */
        function setNewGridIcons(inv){
            for(local i = 0; i < INVENTORY_SIZE; i++){
                if(inv[i] == InventoryItems.NONE){
                    //mWidgets_[i].setHidden(false);
                    //mWidgets_[i].setSkin("Invisible");
                    continue;
                }
                //mWidgets_[i].setHidden(false);
                //mWidgets_[i].setSkin(::gui.InventoryScreen.getSkinForItem(inv[i]));
            }
        }

        function initialise(parentWin, overlayWin){
            mWindow_ = parentWin.createWindow();
            mWindow_.setClipBorders(0, 0, 0, 0);

            local numItems = 10;
            for(local y = 0; y < numItems; y++){
                for(local x = 0; x < numItems; x++){
                    local background = mWindow_.createPanel();
                    background.setSize(64, 64);
                    background.setPosition(x * 64, y * 64);
                    background.setSkin("inventory_slot");

                    local item = mWindow_.createButton();
                    item.setHidden(false);
                    //item.setSize(48, 48);
                    //item.setPosition(x * 64 + 8, y * 64 + 8);
                    item.setSize(64, 64);
                    item.setPosition(x * 64, y * 64);
                    //item.setSkin("Invisible");
                    item.setVisualsEnabled(false);
                    item.setUserId(x | (y << 10));
                    item.attachListener(inventoryItemListener, this);
                    mWidgets_.append(item);
                }
            }
        }

        function update(){
            if(mItemHovered_){
                local xx = _input.getMouseX().tofloat() / _window.getWidth().tofloat();
                local yy = _input.getMouseY().tofloat() / _window.getHeight().tofloat();
                mHoverInfo_.setPosition((1920*xx), (1080*yy));
            }
        }

        function inventoryItemListener(widget, action){
            //if(actionMenu_.menuActive_) return;

            local id = widget.getUserId();
            local x = id & 0xF;
            local y = id >> 10;
            local targetItemIndex = x + y * INVENTORY_WIDTH;

            if(action == _GUI_ACTION_HIGHLIGHTED){ //Hovered
                mItemHovered_ = true;
                mButtonCover_.setPosition(mResolvedPos_.x + x * 64, mResolvedPos_.y + y * 64);
                //buttonCover_.setPosition(0, 0);
                mButtonCover_.setHidden(false);
                local success = setToMenuItem(targetItemIndex);
                //if(!success) mItemHovered_ = false
            }else if(action == _GUI_ACTION_CANCEL){ //hover ended
                mItemHovered_ = false;
                mButtonCover_.setHidden(true);
            }else if(action == _GUI_ACTION_PRESSED){ //Pressed
                /*
                local targetArray = ::gui.InventoryScreen.getArrayForInventoryType(parentGridType_);
                local targetItem = targetArray[targetItemIndex];
                if(targetItem != InventoryItems.NONE){
                    print("pressed");
                    this.actionMenu_.setItem(targetItemIndex, parentGridType_);
                    this.actionMenu_.show(true);
                }
                */
            }


            mHoverInfo_.setItem(::Item(ItemId.SIMPLE_SWORD));

            mSelectedX_ = x;
            mSelectedY_ = y;
            mHoverInfo_.setVisible(mItemHovered_);
            //mButtonCover_.setVisible(mItemHovered_);
        }

        function setToMenuItem(idx){
            /*
            local targetArray = ::gui.InventoryScreen.getArrayForInventoryType(parentGridType_);
            local item = targetArray[idx];
            if(item == InventoryItems.NONE) return false;
            hoverInfo_.setItem(item);
            return true;
            */
        }

        function addToLayout(layout){
            mLayout_ = layout;
            mLayout_.addCell(mWindow_);
        }

        function notifyLayout(){
            mResolvedPos_ = mWindow_.getDerivedPosition();
        }
    }

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

        mInventoryGrid_ = InventoryGrid(mHoverInfo_, buttonCover);
        mInventoryGrid_.initialise(mWindow_, mOverlayWindow_);
        mInventoryGrid_.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();

        mInventoryGrid_.notifyLayout();
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
        /*
        if(event == InventoryBusEvents.ITEM_SELECTED){
            local item = mInventory_.getItemForIdx(data);
            ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, {
                "mode": ItemInfoMode.USE,
                "item": item,
                "slotIdx": data
            }));
        }
        */
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
        mInventoryGrid_.update();
    }
};