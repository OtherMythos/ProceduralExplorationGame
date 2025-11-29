enum InventoryItemHelperScreenFunctions{
    USE,
    SCRAP,
    CANCEL,
    EQUIP,
    EQUIP_LEFT_HAND,
    EQUIP_RIGHT_HAND,
    UNEQUIP,
    READ,
    MOVE_TO_INVENTORY,
    MOVE_OUT_OF_INVENTORY,
    BUY,

    MAX
};

::ScreenManager.Screens[Screen.INVENTORY_ITEM_HELPER_SCREEN] = class extends ::Screen{

    mData_ = null;

    mPanelContainerWindow_ = null;

    mItemInfoPanel_ = null;

    mButtonFunctions_ = array(InventoryItemHelperScreenFunctions.MAX);

    function setup(data){
        mData_ = data;
        mCustomPosition_ = true;

        local winWidth = ::drawable.x * 0.8;
        local winHeight = ::drawable.y * 0.8;

        local showItemInfo = data.rawin("showItemInfo") && data.showItemInfo;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();
        createBackgroundCloseButton_();
        mBackgroundWindow_.setColour(ColourValue(1, 1, 1, 0.8));

        //Do this first so the icon has a lower z position.
        createIconPanel(mData_.item);

        mWindow_ = _gui.createWindow("InventoryItemHelperScreen");
        //Start it quite big so that labels or buttons expand as expected.
        mWindow_.setSize(800, 800);
        //mWindow_.setPosition(data.pos);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local layoutLine = _gui.createLayoutLine();

        if(!showItemInfo){
            local title = mWindow_.createLabel();
            title.setText(data.item.getName());
            title.sizeToFit(mWindow_.getSizeAfterClipping().x);
            title.setTextColour(0, 0, 0, 1);
            layoutLine.addCell(title);
        }

        local buttonData = getButtonOptionsForItem(data.item);
        local buttonOptions = buttonData[0];
        local buttonFunctions = buttonData[1];
        local buttonEnabled = buttonData[2];

        local firstEnabledButton = null;
        foreach(c,i in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.1);
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setTextHorizontalAlignment(_TEXT_ALIGN_LEFT);
            layoutLine.addCell(button);

            if(!buttonEnabled[c]){
                button.setDisabled(true);
            }else if(firstEnabledButton == null){
                firstEnabledButton = button;
            }
        }

        if(firstEnabledButton != null){
            firstEnabledButton.setFocus();
        }

        layoutLine.layout();

        local windowSize = mWindow_.calculateChildrenSize();
        //mWindow_.setSize(childrenSize.x, childrenSize.y >= data.size.y ? childrenSize.y : data.size.y);
        mWindow_.setSize(windowSize);

        // Create item info panel if enabled
        if(showItemInfo){
            local isShop = mData_.rawin("isShop") && mData_.isShop;
            mItemInfoPanel_ = ::InventoryHoverItemInfo(null, isShop);
            mItemInfoPanel_.setItem(data.item);
            mItemInfoPanel_.setVisible(true);
        }

        local targetPos = data.gridItemPos.copy();
        targetPos.x += data.gridItemSize.x;
        //Check if the window is now over the end of the screen.
        local screenPosData = determinePositionForScreen_(targetPos, windowSize, data);
        local winPos = screenPosData[0];
        local itemInfoPos = screenPosData[1];
        mWindow_.setPosition(winPos);

        if(mItemInfoPanel_){
            mItemInfoPanel_.setPosition(itemInfoPos.x, itemInfoPos.y);
        }

        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_BEGAN, null);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mPanelContainerWindow_.setZOrder(idx);
    }

    function createIconPanel(item){
        local panelContainerWindow = _gui.createWindow("InventoryItemHelperScreenPanelContainer");
        panelContainerWindow.setClipBorders(0, 0, 0, 0);
        panelContainerWindow.setVisualsEnabled(false);
        panelContainerWindow.setClickable(false);

        local panelSize = mData_.gridItemSize;
        local gridPadding = panelSize * 0.125;
        local iconSize = panelSize * 0.75;

        local background = panelContainerWindow.createPanel();
        background.setSize(panelSize);
        background.setSkin("inventory_slot");
        background.setClickable(false);

        local iconPanel = panelContainerWindow.createPanel();
        iconPanel.setSize(panelSize * 0.75);
        iconPanel.setPosition(gridPadding);
        iconPanel.setSkin(item.getIcon());
        iconPanel.setClickable(false);

        panelContainerWindow.setSize(panelSize);
        panelContainerWindow.setPosition(mData_.gridItemPos);
        mPanelContainerWindow_ = panelContainerWindow;
    }

    function determinePositionForScreen_(targetPos, windowSize, data){
        local windowBottomRight = targetPos + windowSize;
        local newPos = targetPos.copy();
        local itemInfoPos = newPos.copy();

        local repositionX = (windowBottomRight.x >= _window.getWidth());
        local repositionY = (windowBottomRight.y >= _window.getHeight());
        if(repositionX){
            local newX = data.gridItemPos.x - windowSize.x;
            if(newX < 0){
                newX = 0;
            }
            newPos.x = newX;
        }
        if(repositionY){
            local newY = data.gridItemPos.y - windowSize.y;
            newPos.y = newY;

            itemInfoPos.y = newY;
        }

        if(repositionX && repositionY){
            newPos.x += data.gridItemSize.x;
        }else if(repositionY){
            newPos.x -= data.gridItemSize.x;
        }

        // Position the info panel to the right of the buttons
        //local infoPanelPos = Vec2(maxButtonWidth + 20, 20);
        itemInfoPos.y -= mItemInfoPanel_.getSize().y;
        itemInfoPos.x -= mData_.gridItemSize.x;
        if(repositionX || repositionY){
            itemInfoPos.x = newPos.x;
        }

        return [newPos, itemInfoPos];
    }

    function shutdown(){
        base.shutdown();
        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_ENDED, null);
        _gui.destroy(mPanelContainerWindow_);
        if(mItemInfoPanel_){
            mItemInfoPanel_.destroy();
        }
    }

    function getButtonOptionsForItem(item){
        local itemType = item.getType();

        local buttonOptions = [];
        local buttonFunctions = [];
        local buttonEnabled = [];

        local isShop = mData_.rawin("isShop") && mData_.isShop;

        if(isShop){
            buttonOptions.append(UNICODE_COINS + " Buy");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.BUY]);
            // Check if player can afford the item
            local itemPrice = mData_.item.mData_;
            local playerMoney = mData_.rawin("playerMoney") ? mData_.playerMoney : 0;
            buttonEnabled.append(playerMoney >= itemPrice);
        }else if(itemType == ItemType.EQUIPPABLE){
            if(mData_.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
                buttonOptions.append(UNICODE_HELMET + " UnEquip");
                buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.UNEQUIP]);
                buttonEnabled.append(true);
            }else{
                local equipData = ::Equippables[item.getEquippableData()];
                local equipSlot = equipData.getEquippedSlot();
                if(equipSlot == EquippedSlotTypes.HAND){
                    buttonOptions.append(UNICODE_LEFT_HAND + " Equip Left Hand");
                    buttonOptions.append(UNICODE_RIGHT_HAND + " Equip Right Hand");
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP_LEFT_HAND]);
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP_RIGHT_HAND]);
                    buttonEnabled.append(true);
                    buttonEnabled.append(true);
                }else{
                    buttonOptions.append(UNICODE_HELMET + " Equip");
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP]);
                    buttonEnabled.append(true);
                }
            }
        }else if(itemType == ItemType.LORE_CONTENT){
            buttonOptions.append("Read");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.READ]);
            buttonEnabled.append(true);
        }else{
            buttonOptions.append(UNICODE_EAT + " Use");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.USE]);
            buttonEnabled.append(true);
        }

        if(!isShop){
            buttonOptions.append(UNICODE_COINS + " Scrap");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.SCRAP]);
            buttonEnabled.append(true);

            if(mData_.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                buttonOptions.append(UNICODE_INTO_INVENTORY + " Move to Inventory");
                buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.MOVE_TO_INVENTORY]);
                buttonEnabled.append(true);
            }

            if(mData_.secondaryGrid && mData_.gridType == InventoryGridType.INVENTORY_GRID){
                buttonOptions.append(UNICODE_LEAVE_INVENTORY + " Move out of Inventory");
                buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.MOVE_OUT_OF_INVENTORY]);
                buttonEnabled.append(true);
            }
        }


        buttonOptions.append(UNICODE_CROSS + " Cancel");
        buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.CANCEL]);
        buttonEnabled.append(true);

        return [buttonOptions, buttonFunctions, buttonEnabled];
    }
}

local b = ::ScreenManager.Screens[Screen.INVENTORY_ITEM_HELPER_SCREEN].mButtonFunctions_;

b[InventoryItemHelperScreenFunctions.USE] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_USE, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.SCRAP] =function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.CANCEL] = function(widget, action){
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.EQUIP] = function(widget, action){
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP, mData_.idx);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.EQUIP_LEFT_HAND] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_LEFT_HAND, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.EQUIP_RIGHT_HAND] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.UNEQUIP] = function(widget, action){
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_UNEQUIP, mData_.idx);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.READ] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_READ, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.MOVE_TO_INVENTORY] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_TO_INVENTORY, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.MOVE_OUT_OF_INVENTORY] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_OUT_OF_INVENTORY, data);
    closeScreen();
};
b[InventoryItemHelperScreenFunctions.BUY] = function(widget, action){
    local data = {"idx": mData_.idx, "gridType": mData_.gridType};
    mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_BUY, data);
    closeScreen();
};