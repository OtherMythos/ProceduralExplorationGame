
::GuiWidgets.InventoryGrid <- class{
    mResolvedPos_ = null;
    mBus_ = null;

    mHoverInfo_ = null;
    mButtonCover_ = null;
    mWindow_ = null;
    mOverlayWin_ = null;

    mWidgets_ = null;
    mItemIcons_ = null;

    mLayout_ = null;
    //mItemHovered_ = false;

    constructor(bus, hoverInfo, buttonCover){
        mBus_ = bus;
        mHoverInfo_ = hoverInfo;
        mButtonCover_ = buttonCover;

        mWidgets_ = [];
    }

    /**
    Update the grid with icons based on an array of items.
    */
    function setNewGridIcons(inv){
        foreach(c,i in inv){
            local widget = mItemIcons_[c];
            if(i == null){
                widget.setVisible(false);
                //Skip this to save a bit of time.
                //widget.setSkin("item_none");
                continue;
            }
            widget.setVisible(true);
            widget.setSkin(i.getIcon());
        }
    }

    function initialise(parentWin, overlayWin, inventoryWidth, inventoryHeight){
        mWindow_ = parentWin.createWindow();
        mWindow_.setClipBorders(0, 0, 0, 0);

        mItemIcons_ = array(inventoryWidth * inventoryHeight);

        for(local y = 0; y < inventoryHeight; y++){
            for(local x = 0; x < inventoryWidth; x++){
                local background = mWindow_.createPanel();
                background.setSize(64, 64);
                background.setPosition(x * 64, y * 64);
                background.setSkin("inventory_slot");

                local iconPanel = mWindow_.createPanel();
                iconPanel.setSize(48, 48);
                iconPanel.setPosition(x * 64 + 8, y * 64 + 8);
                iconPanel.setSkin("item_none");
                iconPanel.setVisible(false);
                mItemIcons_[x + y * inventoryWidth] = iconPanel;

                local item = mWindow_.createButton();
                item.setHidden(false);
                //item.setSize(48, 48);
                //item.setPosition(x * 64 + 8, y * 64 + 8);
                item.setSize(64, 64);
                item.setPosition(x * 64, y * 64);
                //item.setSkin("Invisible");
                item.setVisualsEnabled(false);
                //item.setUserId(x | (y << 10));
                item.setUserId(x + (y * inventoryWidth));
                item.attachListener(inventoryItemListener, this);
                mWidgets_.append(item);
            }
        }
    }

    function inventoryItemListener(widget, action){
        //if(actionMenu_.menuActive_) return;

        local id = widget.getUserId();
        //local x = id & 0xF;
        //local y = id >> 10;
        //local targetItemIndex = x + y * INVENTORY_WIDTH;

        if(action == _GUI_ACTION_HIGHLIGHTED){ //Hovered
            //mItemHovered_ = true;
            //mButtonCover_.setPosition(mResolvedPos_.x + x * 64, mResolvedPos_.y + y * 64);
            local derivedPos = widget.getDerivedPosition();
            mButtonCover_.setPosition(derivedPos);
            //buttonCover_.setPosition(0, 0);
            mButtonCover_.setHidden(false);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_HOVER_BEGAN, id);
            //local success = setToMenuItem(targetItemIndex);
            //if(!success) mItemHovered_ = false
        }else if(action == _GUI_ACTION_CANCEL){ //hover ended
            mButtonCover_.setHidden(true);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_HOVER_ENDED, id);
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
            mButtonCover_.setHidden(true);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_SELECTED, id);
        }


        //mHoverInfo_.setItem(::Item(ItemId.SIMPLE_SWORD));

        //mHoverInfo_.setVisible(mItemHovered_);
        //mButtonCover_.setVisible(mItemHovered_);
    }

    function setToMenuItem(idx){
        //local targetArray = ::gui.InventoryScreen.getArrayForInventoryType(parentGridType_);
        //local item = targetArray[idx];
        //if(item == InventoryItems.NONE) return false;
        //hoverInfo_.setItem(item);
        //return true;
    }

    function addToLayout(layout){
        mLayout_ = layout;
        mLayout_.addCell(mWindow_);
    }

    function notifyLayout(){
        mResolvedPos_ = mWindow_.getDerivedPosition();
    }

    function shutdown(){

    }

    function busCallback(event, data){

    }

    function getSize(){
        return mWindow_.getSize();
    }
    function getPosition(){
        return mWindow_.getPosition();
    }
    function getPositionForIdx(idx){
        return mWidgets_[idx].getDerivedPosition();
    }
};