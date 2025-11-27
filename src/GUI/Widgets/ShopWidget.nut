::ShopWidget <- class{

    mParent_ = null;

    mBackgroundPanel_ = null;
    mInnerPanel_ = null;
    mTitle_ = null;
    mBusCallbackId_ = null;
    mInventoryBus_ = null;

    mInventoryWidth_ = 5;
    mInventoryHeight_ = 5;

    mInventory_ = null;
    mInventoryGrid_ = null;

    constructor(parent){
        mParent_ = parent;
    }

    function setup(startPos){
        local yPos = startPos.y;

        mInventoryWidth_ = 5;
        mInventoryHeight_ = 3;
        local gridSize = calculateGridSize();

        mBackgroundPanel_ = mParent_.createPanel();
        mBackgroundPanel_.setSize(mParent_.getSizeAfterClipping().x, 230);
        mBackgroundPanel_.setDatablock("simpleGrey");
        mBackgroundPanel_.setPosition(0, yPos);

        local innerPadding = 5;

        mTitle_ = mParent_.createLabel();
        mTitle_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.1);
        mTitle_.setText("Shop");
        mTitle_.setPosition(innerPadding, yPos);

        yPos += mTitle_.getSize().y;

        mInnerPanel_ = mParent_.createPanel();
        local backgroundSize = mBackgroundPanel_.getSize();
        mInnerPanel_.setSize(backgroundSize.x - innerPadding * 2, backgroundSize.y - mTitle_.getSize().x - innerPadding);
        mInnerPanel_.setPosition(innerPadding, yPos);
        mInnerPanel_.setDatablock("placeMapIndicator");

        mInventoryBus_ = ::InventoryScreenObject.InventoryInfoBus();
        mBusCallbackId_ = mInventoryBus_.registerCallback(busCallback, this);

        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, null, null);
        mInventoryGrid_.initialise(mParent_, gridSize, null, mInventoryWidth_, mInventoryHeight_);
        mInventoryGrid_.setPosition(mInnerPanel_.getPosition());

        local items = array(mInventoryWidth_ * mInventoryHeight_, null);
        items[0] = ::Item(ItemId.APPLE);
        mInventory_ = items;
        mInventoryGrid_.setNewGridIcons(items);

    }

    function busCallback(event, data){
        if(event == InventoryBusEvents.ITEM_SELECTED){
            selectItem(data);
        }
    }

    //TODO reduce duplication.
    function selectItem(inventoryData){
        local idx = inventoryData.id;
        local selectedItem = null;
        local targetGrid = null;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            //TODO remove direct access, properly pass the player stats in some other point.
            selectedItem = mPlayerStats_.getEquippedItem(idx+1);
            targetGrid = mInventoryEquippedGrid_;
        }else if(inventoryData.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            selectedItem = mSecondaryItems_[idx];
            targetGrid = mSecondaryInventoryGrid_;
        }else{
            selectedItem = mInventory_[idx];
            targetGrid = mInventoryGrid_;
        }
        if(selectedItem == null) return;
        print("Selected item " + selectedItem.tostring());

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        local pos = null;
        local gridItemSize = targetGrid.getSizeForIdx(idx);
        local size = Vec2(::ScreenManager.calculateRatio(200), targetGrid.getSize().y);
        local posForIdx = targetGrid.getPositionForIdx(idx);
        if(mobile){
            //size = ::drawable * 0.75;
            size = Vec2();
            //pos = ::drawable / 2 - size / 2;
            pos = posForIdx.copy();
            pos.x += gridItemSize.x;
        }else{
            pos = Vec2(posForIdx.x + ::ScreenManager.calculateRatio(calculateGridSize()), posForIdx.y);
        }

        local data = {
            "pos": pos,
            "size": size,
            "gridItemPos": posForIdx,
            "gridItemSize": gridItemSize,
            "item": selectedItem,
            "idx": idx,
            "gridType": inventoryData.gridType,
            "bus": mInventoryBus_,
            "secondaryGrid": false
        };
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_ITEM_HELPER_SCREEN, data), null, 3);
    }

    function calculateGridSize(){
        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        return mobile ? (::drawable.x / (mInventoryWidth_+2)) : 64;
    }

    function shutdown(){
        mInventoryBus_.deregisterCallback(mBusCallbackId_);
    }

};