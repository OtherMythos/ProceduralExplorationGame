
::GuiWidgets.InventoryGrid <- class{
    mInventoryType_ = null;
    mResolvedPos_ = null;
    mBus_ = null;

    EQUIP_GRID_VALUES = [
        "inventory_slot_head",
        "inventory_slot_body",
        "inventory_slot_left_hand",
        "inventory_slot_right_hand",
        "inventory_slot_legs",
        "inventory_slot_feet",
        "inventory_slot_accessory",
        "inventory_slot_accessory"
    ];

    mHoverInfo_ = null;
    mButtonCover_ = null;
    mWindow_ = null;
    mOverlayWin_ = null;

    mBackgrounds_ = null;
    mWidgets_ = null;
    mItemIcons_ = null;

    mLayout_ = null;
    //mItemHovered_ = false;

    constructor(inventoryType, bus, hoverInfo, buttonCover){
        mInventoryType_ = inventoryType;
        mBus_ = bus;
        mHoverInfo_ = hoverInfo;
        mButtonCover_ = buttonCover;

        mWidgets_ = [];
        mBackgrounds_ = [];
    }

    /**
    Update the grid with icons based on an array of items.
    */
    function setNewGridIcons(inv){
        //Skip the NONE
        local offset = 0;
        if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
            offset = 1;
        }

        for(local i = offset; i < inv.len() - offset; i++){
            local widget = mItemIcons_[i - offset];
            local item = inv[i];

            if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
                local background = mBackgrounds_[i - offset];
                setSkinForBackgroundEquippables(background, i-offset, item != null);
            }
            if(item == null){
                widget.setVisible(false);
                //Skip this to save a bit of time.
                //widget.setSkin("item_none");
                continue;
            }
            widget.setVisible(true);
            widget.setSkin(item.getIcon());
        }
    }

    function setSkinForBackgroundEquippables(backgroundWidget, idx, populated){
        backgroundWidget.setSkin(populated ? "inventory_slot" : EQUIP_GRID_VALUES[idx]);
    }

    function initialise(parentWin, overlayWin, inventoryWidth, inventoryHeight){
        mWindow_ = parentWin.createWindow();
        mWindow_.setClipBorders(0, 0, 0, 0);

        if(mInventoryType_ == InventoryGridType.INVENTORY_GRID){
            mItemIcons_ = array(inventoryWidth * inventoryHeight);
        }else{
            inventoryWidth = 1;
            inventoryHeight = EquippedSlotTypes.MAX-2;
            mItemIcons_ = array(inventoryHeight);
        }

        for(local y = 0; y < inventoryHeight; y++){
            for(local x = 0; x < inventoryWidth; x++){
                local background = mWindow_.createPanel();
                background.setSize(64, 64);
                background.setPosition(x * 64, y * 64);
                background.setSkin("inventory_slot");
                mBackgrounds_.append(background);

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

        if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
            for(local i = 0; i < inventoryHeight; i++){
                setSkinForBackgroundEquippables(mBackgrounds_[i], i, false);
            }
        }
    }

    function inventoryItemListener(widget, action){
        //if(actionMenu_.menuActive_) return;

        local idx = widget.getUserId();
        local wrappedData = {"gridType": mInventoryType_, "id": idx};
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
            mBus_.notifyEvent(InventoryBusEvents.ITEM_HOVER_BEGAN, wrappedData);
            //local success = setToMenuItem(targetItemIndex);
            //if(!success) mItemHovered_ = false
        }else if(action == _GUI_ACTION_CANCEL){ //hover ended
            mButtonCover_.setHidden(true);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_HOVER_ENDED, wrappedData);
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
            mBus_.notifyEvent(InventoryBusEvents.ITEM_SELECTED, wrappedData);
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