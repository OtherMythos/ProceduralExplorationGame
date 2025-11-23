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

    MAX
};

::ScreenManager.Screens[Screen.INVENTORY_ITEM_HELPER_SCREEN] = class extends ::Screen{

    mData_ = null;

    mButtonFunctions_ = array(InventoryItemHelperScreenFunctions.MAX);

    function setup(data){
        mData_ = data;
        mCustomPosition_ = true;

        local winWidth = ::drawable.x * 0.8;
        local winHeight = ::drawable.y * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();
        mBackgroundWindow_.setColour(ColourValue(1, 1, 1, 0.8));

        mWindow_ = _gui.createWindow("InventoryItemHelperScreen");
        //Start it quite big so that labels or buttons expand as expected.
        mWindow_.setSize(800, 800);
        mWindow_.setPosition(data.pos);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        //title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText(data.item.getName());
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        local buttonData = getButtonOptionsForItem(data.item);
        foreach(c,i in buttonData[0]){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.1);
            button.setText(i);
            button.attachListenerForEvent(buttonData[1][c], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            layoutLine.addCell(button);
            if(c == 0) button.setFocus();
        }

        layoutLine.layout();

        local childrenSize = mWindow_.calculateChildrenSize();
        mWindow_.setSize(childrenSize.x, childrenSize.y >= data.size.y ? childrenSize.y : data.size.y);

        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_BEGAN, null);
    }

    function shutdown(){
        base.shutdown();
        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_ENDED, null);
    }

    function getButtonOptionsForItem(item){
        local itemType = item.getType();

        local buttonOptions = [];
        local buttonFunctions = [];

        if(itemType == ItemType.EQUIPPABLE){
            if(mData_.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
                buttonOptions.append("UnEquip");
                buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.UNEQUIP]);
            }else{
                local equipData = ::Equippables[item.getEquippableData()];
                local equipSlot = equipData.getEquippedSlot();
                if(equipSlot == EquippedSlotTypes.HAND){
                    buttonOptions.append("Equip Left Hand");
                    buttonOptions.append("Equip Right Hand");
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP_LEFT_HAND]);
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP_RIGHT_HAND]);
                }else{
                    buttonOptions.append("Equip");
                    buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.EQUIP]);
                }
            }
        }else if(itemType == ItemType.LORE_CONTENT){
            buttonOptions.append("Read");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.READ]);
        }else{
            buttonOptions.append("Use");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.USE]);
        }

        buttonOptions.append("Scrap");
        buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.SCRAP]);

        if(mData_.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            buttonOptions.append("Move to Inventory");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.MOVE_TO_INVENTORY]);
        }

        if(mData_.secondaryGrid && mData_.gridType == InventoryGridType.INVENTORY_GRID){
            buttonOptions.append("Move out of Inventory");
            buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.MOVE_OUT_OF_INVENTORY]);
        }

        buttonOptions.append("Cancel");
        buttonFunctions.append(mButtonFunctions_[InventoryItemHelperScreenFunctions.CANCEL]);

        return [buttonOptions, buttonFunctions];
    }

    function closeScreen(){
        ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
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