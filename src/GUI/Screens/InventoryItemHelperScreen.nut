::ScreenManager.Screens[Screen.INVENTORY_ITEM_HELPER_SCREEN] = class extends ::Screen{

    mData_ = null;

    function setup(data){
        mData_ = data;

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();
        mBackgroundWindow_.setColour(ColourValue(1, 1, 1, 0.8));

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(data.size);
        mWindow_.setPosition(data.pos);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setZOrder(61);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        //title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText(data.item.getName());
        //title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        local buttonData = getButtonOptionsForType(data.item.getType());
        foreach(i,c in buttonData[0]){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.1);
            button.setText(c);
            button.attachListenerForEvent(buttonData[1][i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            layoutLine.addCell(button);
        }

        layoutLine.layout();
    }

    function getButtonOptionsForType(itemType){
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
                mData_.bus.notifyEvent(InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP, mData_.idx);
                closeScreen();
            },
            function(widget, action){
                closeScreen();
            }
        ];

        if(itemType == ItemType.EQUIPPABLE){
            buttonOptions[0] = "Equip";
        }

        return [buttonOptions, buttonFunctions];
    }

    function closeScreen(){
        ::ScreenManager.backupScreen(mLayerIdx);
    }
}