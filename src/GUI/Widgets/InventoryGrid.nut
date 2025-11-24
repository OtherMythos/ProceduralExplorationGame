
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
    mGridPadding_ = null;

    mLayout_ = null;
    //mItemHovered_ = false;

    mInventoryWidth_ = null;
    mInventoryHeight_ = null;

    constructor(inventoryType, bus, hoverInfo, buttonCover){
        mInventoryType_ = inventoryType;
        mBus_ = bus;
        mHoverInfo_ = hoverInfo;
        mButtonCover_ = buttonCover;
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

        //assert(mInventoryWidth_ * mInventoryHeight_ == inv.len());
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

    function initialise(parentWin, gridSize, overlayWin, inventoryWidth, inventoryHeight){
        mWindow_ = parentWin.createWindow("InventoryGrid");
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClickable(false);

        if(mInventoryType_ == InventoryGridType.INVENTORY_GRID || mInventoryType_ == InventoryGridType.INVENTORY_GRID_SECONDARY){
            mItemIcons_ = array(inventoryWidth * inventoryHeight);
        }else if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
            inventoryWidth = 1;
            inventoryHeight = EquippedSlotTypes.MAX-1;
            mItemIcons_ = array(inventoryHeight);
        }
        mWidgets_ = array(inventoryWidth*inventoryHeight);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        //Get the size of a grid relative to some universal metric.
        local gridRatio = ::ScreenManager.calculateRatio(gridSize);
        local gridPadding = gridRatio * 0.125;
        mGridPadding_ = gridPadding;
        local iconSize = ::ScreenManager.calculateRatio(gridSize.tofloat() * 0.75);
        mButtonCover_.setSize(gridRatio, gridRatio);
        for(local y = 0; y < inventoryHeight; y++){
            for(local x = 0; x < inventoryWidth; x++){
                local background = mWindow_.createPanel();
                background.setSize(gridRatio, gridRatio);
                background.setPosition(x * gridRatio, y * gridRatio);
                background.setSkin("inventory_slot");
                mBackgrounds_.append(background);

                local iconPanel = mWindow_.createPanel();
                iconPanel.setSize(iconSize, iconSize);
                iconPanel.setPosition(x * gridRatio + gridPadding, y * gridRatio + gridPadding);
                iconPanel.setSkin("item_none");
                iconPanel.setVisible(false);
                mItemIcons_[x + y * inventoryWidth] = iconPanel;

                local item = mWindow_.createButton();
                item.setHidden(false);
                //item.setSize(48, 48);
                //item.setPosition(x * 64 + 8, y * 64 + 8);
                item.setSize(gridRatio, gridRatio);
                item.setPosition(x * gridRatio, y * gridRatio);
                //item.setSkin("Invisible");
                item.setVisualsEnabled(false);
                //item.setUserId(x | (y << 10));
                item.setUserId(x + (y * inventoryWidth));
                item.attachListener(inventoryItemListener, this);
                mWidgets_[x + y * inventoryWidth] = item;
                //if(x == 1 && y == 1 && mInventoryType_ == InventoryGridType.INVENTORY_GRID) item.setFocus();
            }
        }

        if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
            for(local i = 0; i < inventoryHeight; i++){
                setSkinForBackgroundEquippables(mBackgrounds_[i], i, false);
            }
        }

        mInventoryWidth_ = inventoryWidth;
        mInventoryHeight_ = inventoryHeight;
    }

    function connectNeighbours(neighbourGridMultiple, backButton){
        local borders = [
            _GUI_BORDER_TOP,
            _GUI_BORDER_BOTTOM,
            _GUI_BORDER_LEFT,
            _GUI_BORDER_RIGHT,
        ];

        local neighbourGrid = neighbourGridMultiple;
        local secondaryGrid = null;
        if(typeof neighbourGrid == "array"){
            neighbourGrid = neighbourGridMultiple[0];
            secondaryGrid = neighbourGridMultiple[1];
        }

        for(local y = 0; y < mInventoryHeight_; y++){
            for(local x = 0; x < mInventoryWidth_; x++){
                local targetWidget = mWidgets_[x + y * mInventoryWidth_];
                foreach(i in borders){
                    local widget = null;
                    {
                        local xx = 0;
                        local yy = 0;
                        if(i == _GUI_BORDER_LEFT) xx = -1;
                        else if(i == _GUI_BORDER_RIGHT) xx = 1;
                        else if(i == _GUI_BORDER_TOP) yy = -1;
                        else if(i == _GUI_BORDER_BOTTOM) yy = 1;
                        local xa = x + xx;
                        local ya = y + yy;
                        if(xa < 0 || ya < 0){
                            local backButtonWidget = null;
                            if(backButton != null){
                                backButtonWidget = backButton.getWidget();
                            }
                            if(mInventoryType_ == InventoryGridType.INVENTORY_GRID){
                                widget = backButtonWidget;
                            }else if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
                                widget = ya < 0 ? backButtonWidget : neighbourGrid.getNeighbourWidgetForIdx(y);
                            }else if(mInventoryType_ == InventoryGridType.INVENTORY_GRID_SECONDARY){
                                widget = ya < 0 ? backButtonWidget : neighbourGrid.getNeighbourWidgetForIdx(y);
                            }
                        }else if(xa >= mInventoryWidth_){
                            if(mInventoryType_ == InventoryGridType.INVENTORY_GRID){
                                widget = neighbourGrid.getNeighbourWidgetForIdx(y);
                            }else if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
                                if(secondaryGrid != null){
                                    widget = secondaryGrid.getNeighbourWidgetForIdx(y);
                                }else{
                                    widget = null;
                                }
                            }else if(mInventoryType_ == InventoryGridType.INVENTORY_GRID_SECONDARY){
                                widget = null;
                            }
                        }else if(ya >= mInventoryHeight_){
                            widget = null;
                        }else{
                            widget = mWidgets_[xa + ya * mInventoryWidth_];
                        }
                    }
                    targetWidget.setNextWidget(widget, i);
                    //targetWidget.setNextWidget(backButton, i);
                }
            }
        }
    }

    function getNeighbourWidgetForIdx(idx){
        local xa = 0;
        local ya = 0;
        if(mInventoryType_ == InventoryGridType.INVENTORY_GRID){
            xa = mInventoryWidth_ - 1;
            ya = idx;
        }else if(mInventoryType_ == InventoryGridType.INVENTORY_EQUIPPABLES){
            xa = 0;
            ya = idx;
        }else if(mInventoryType_ == InventoryGridType.INVENTORY_GRID_SECONDARY){
            xa = 0;
            ya = idx;
        }

        local idx = xa + ya * mInventoryWidth_;
        if(idx < 0 || idx >= mWidgets_.len()) return null;

        return mWidgets_[idx];
    }

    function highlightForIdx(idx){
        if(idx < 0 || idx >= mWidgets_.len()) return;
        mWidgets_[idx].setFocus();
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
            setButtonCoverHidden(false);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_HOVER_BEGAN, wrappedData);
            //local success = setToMenuItem(targetItemIndex);
            //if(!success) mItemHovered_ = false
        }else if(action == _GUI_ACTION_CANCEL){ //hover ended
            setButtonCoverHidden(true);
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
            setButtonCoverHidden(true);
            mBus_.notifyEvent(InventoryBusEvents.ITEM_SELECTED, wrappedData);
        }


        //mHoverInfo_.setItem(::Item(ItemId.SIMPLE_SWORD));

        //mHoverInfo_.setVisible(mItemHovered_);
        //mButtonCover_.setVisible(mItemHovered_);
    }

    function setButtonCoverHidden(hidden){
        local target = hidden;
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            target = true;
        }
        mButtonCover_.setHidden(target);
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
    function setPosition(pos){
        mWindow_.setPosition(pos);
    }
    function setSize(size){
        mWindow_.setSize(size);
    }
    function calculateChildrenSize(){
        return mWindow_.calculateChildrenSize();
    }
    function getPositionForIdx(idx){
        return mWidgets_[idx].getDerivedPosition();
    }
    function getSizeForIdx(idx){
        return mWidgets_[idx].getSize();
    }
    function getWidgetSize(){
        if(mBackgrounds_.len() < 0){
            return ::Vec2_ZERO.copy();
        }
        return mBackgrounds_[0].getSize();
    }
    function setPositionForIdx(idx, pos){
        mWidgets_[idx].setPosition(pos);
        mItemIcons_[idx].setPosition(pos + mGridPadding_);
        mBackgrounds_[idx].setPosition(pos);
    }
};