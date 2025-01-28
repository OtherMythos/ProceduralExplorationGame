::ScreenManager.Screens[Screen.INVENTORY_ITEM_HELPER_SCREEN] = class extends ::Screen{

    mData_ = null;

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
        mWindow_.setZOrder(61);

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
        mWindow_.setSize(childrenSize.x, data.size.y);

        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_BEGAN, null);
    }

    function shutdown(){
        base.shutdown();
        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_HELPER_SCREEN_ENDED, null);
    }

    function getButtonOptionsForItem(item){
        local itemType = item.getType();

        local buttonOptions = [
            "Use",
            "Scrap",
            "Cancel"
        ];
        local buttonFunctions = [
            function(widget, action){
                mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_USE, mData_.idx);
                closeScreen();
            },
            function(widget, action){
                local data = {"idx": mData_.idx, "gridType": mData_.gridType};
                mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP, data);
                closeScreen();
            },
            function(widget, action){
                closeScreen();
            },
            function(widget, action){
                mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP, mData_.idx);
                closeScreen();
            },
            function(widget, action){
                mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_UNEQUIP, mData_.idx);
                closeScreen();
            },
            function(widget, action){
                ::Base.mExplorationLogic.readLoreContent(item);
                closeScreen();
            },
        ];

        if(itemType == ItemType.EQUIPPABLE){
            if(mData_.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
                buttonOptions[0] = "UnEquip";
                buttonFunctions[0] = buttonFunctions[buttonFunctions.len()-2];
            }else{
                local equipData = ::Equippables[item.getEquippableData()];
                local equipSlot = equipData.getEquippedSlot();
                if(equipSlot == EquippedSlotTypes.HAND){
                    //Give the option of which hand to equip to.
                    buttonOptions[0] = "Equip Left Hand"
                    buttonOptions.insert(1, "Equip Right Hand");
                    buttonFunctions[0] = function(widget, action){
                        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_LEFT_HAND, mData_.idx);
                        closeScreen();
                    };
                    buttonFunctions.insert(1, function(widget, action){
                        mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND, mData_.idx);
                        closeScreen();
                    });
                }else{
                    buttonOptions[0] = "Equip";
                    buttonFunctions[0] = buttonFunctions[buttonFunctions.len()-3];
                }
            }
        }
        else if(itemType == ItemType.LORE_CONTENT){
            buttonOptions[0] = "Read";
            buttonFunctions[0] = buttonFunctions[buttonFunctions.len()-1];
        }

        return [buttonOptions, buttonFunctions];
    }

    function closeScreen(){
        ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
    }
}