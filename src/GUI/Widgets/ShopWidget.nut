::ShopBuyAnimation <- class{

    mRenderIcon_ = null;
    mWindow_ = null;
    mIconPanel_ = null;
    mProgress_ = 0.0;
    mStartPos_ = null;
    mEndPos_ = null;
    mStartSize_ = null;
    mEndSize_ = null;

    static DURATION = 0.6;

    constructor(itemDef, startCentre, startSize, endCentre, endSize){
        mStartPos_ = startCentre;
        mEndPos_ = endCentre;
        mStartSize_ = startSize;
        mEndSize_ = endSize;

        local meshName = itemDef.getMesh();
        if(meshName == null) return;

        mRenderIcon_ = ::RenderIconManager.createIcon(meshName, true, true, 2);
        local datablock = mRenderIcon_.getDatablock();
        if(datablock != null){
            //Set initial orientation similar to inventory grid items
            local orientation = Quat();
            orientation += Quat(0.5, ::Vec3_UNIT_Y);
            orientation += Quat(-0.5, ::Vec3_UNIT_Z);
            orientation += Quat(1.0, ::Vec3_UNIT_X);
            mRenderIcon_.setOrientation(orientation);

            mWindow_ = _gui.createWindow("ShopBuyAnimation");
            mWindow_.setSize(::drawable.x, ::drawable.y);
            mWindow_.setVisualsEnabled(false);
            mWindow_.setClickable(false);

            mIconPanel_ = mWindow_.createPanel();
            mIconPanel_.setClickable(false);
            mIconPanel_.setDatablock(datablock);
        }
    }

    function update(){
        if(mRenderIcon_ == null) return true;

        mProgress_ += 1.0 / (DURATION * 60.0);
        if(mProgress_ > 1.0) mProgress_ = 1.0;

        local t = mProgress_;
        //X uses easeInQuart - slow start then accelerating snap across
        local easeX = ::Easing.easeOutBack(t);
        //Y uses easeOutBack - overshoots slightly for a looping arc feel
        local easeY = ::Easing.easeInCubic(t);
        local pos = Vec2(
            mStartPos_.x + (mEndPos_.x - mStartPos_.x) * easeX,
            mStartPos_.y + (mEndPos_.y - mStartPos_.y) * easeY
        );

        local easeSize = ::Easing.easeInQuart(t);
        local size = mStartSize_ + (mEndSize_ - mStartSize_) * easeSize;

        //Scale down to 0 in the final quarter as it hits the inventory icon
        local scaleMult = 1.0;
        if(t > 0.75){
            local scaleT = (t - 0.75) / 0.25;
            scaleMult = 1.0 - ::Easing.easeInQuad(scaleT);
        }
        size = size * scaleMult;

        mRenderIcon_.setPosition(pos);
        mRenderIcon_.setSize(size.x, size.y);

        if(mIconPanel_ != null){
            mIconPanel_.setPosition(Vec2(pos.x - size.x / 2, pos.y - size.y / 2));
            print(size);
            mIconPanel_.setSize(size.x, size.y);
            //Fade out in final quarter of animation
            local alpha = t > 0.75 ? 1.0 - (t - 0.75) / 0.25 : 1.0;
            mIconPanel_.setColour(ColourValue(1, 1, 1, alpha));
        }

        return mProgress_ >= 1.0;
    }

    function shutdown(){
        if(mIconPanel_ != null){
            _gui.destroy(mIconPanel_);
            mIconPanel_ = null;
        }
        if(mWindow_ != null){
            _gui.destroy(mWindow_);
            mWindow_ = null;
        }
        if(mRenderIcon_ != null){
            mRenderIcon_.destroy();
            mRenderIcon_ = null;
        }
    }
};

::ShopWidget <- class{

    mParent_ = null;

    mBackgroundPanel_ = null;
    mInnerPanel_ = null;
    mTitle_ = null;
    mBusCallbackId_ = null;
    mInventoryBus_ = null;

    mInventoryWidth_ = 5;
    mInventoryHeight_ = 5;

    INNER_PADDING = 10;
    GRID_PADDING = 5;

    mInventory_ = null;
    mPrices_ = null;
    mInventoryGrid_ = null;
    mBuyAnimations_ = null;
    mGetInventoryTabInfo_ = null;

    constructor(parent){
        mParent_ = parent;
    }

    function setup(startPos, layerIdx = 0){
        local yPos = startPos.y;

        mInventoryWidth_ = 5;
        mInventoryHeight_ = 3;
        local gridSize = calculateGridSize();

        mBackgroundPanel_ = mParent_.createPanel();
        mBackgroundPanel_.setSize(mParent_.getSizeAfterClipping().x, 230 + GRID_PADDING * 2);
        mBackgroundPanel_.setDatablock("simpleGrey");
        mBackgroundPanel_.setPosition(0, yPos);
        mBackgroundPanel_.setSkinPack("Panel_darkGrey");

        local innerPadding = INNER_PADDING;

        mTitle_ = mParent_.createLabel();
        mTitle_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.1);
        mTitle_.setText("Shop");
        mTitle_.setPosition(innerPadding, yPos);

        yPos += mTitle_.getSize().y;

        mInnerPanel_ = mParent_.createPanel();
        local backgroundSize = mBackgroundPanel_.getSize();
        mInnerPanel_.setSize(backgroundSize.x - innerPadding * 2, backgroundSize.y - mTitle_.getSize().x - GRID_PADDING);
        mInnerPanel_.setPosition(innerPadding, yPos);
        mInnerPanel_.setSkinPack("Panel_lightGrey");

        mInventoryBus_ = ::InventoryScreenObject.InventoryInfoBus();
        mBusCallbackId_ = mInventoryBus_.registerCallback(busCallback, this);

        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, null, null, false, false);
        mInventoryGrid_.initialise(mParent_, gridSize, null, mInventoryWidth_, mInventoryHeight_, layerIdx);
        mInventoryGrid_.setPosition(mInnerPanel_.getPosition() + GRID_PADDING);

        local distributor = ::FindableDistributor();
        local shopData = distributor.determineShopItems(mInventoryWidth_, mInventoryHeight_);
        mInventory_ = shopData["items"];
        mPrices_ = shopData["prices"];
        mBuyAnimations_ = [];
        refreshGrid_()

    }

    function busCallback(event, data){
        if(event == InventoryBusEvents.ITEM_SELECTED){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            selectItem(data);
        }else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_BUY){
            handleBuyEvent(data);
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
            "gridItemDatablock": targetGrid.getDatablockForIdx(idx),
            "item": selectedItem,
            "idx": idx,
            "gridType": inventoryData.gridType,
            "bus": mInventoryBus_,
            "secondaryGrid": false,
            "isShop": true,
            "itemPrice": mPrices_[idx],
            "playerMoney": ::Base.mPlayerStats.getMoney(),
            "inventoryFull": ::Base.mPlayerStats.mInventory_.getNumSlotsFree() == 0,
            "showItemInfo": true
        };
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_ITEM_HELPER_SCREEN, data), null, 3);
    }

    function notifyPositionChanged(){
        mInventoryGrid_.notifyPositionChanged(INNER_PADDING);
    }

    function handleBuyEvent(data){
        local idx = data.idx;
        local shopItem = mInventory_[idx];
        if(shopItem == null) return;

        local price = mPrices_[idx];
        local playerMoney = ::Base.mPlayerStats.getMoney();

        if(playerMoney < price) return;

        ::Base.mPlayerStats.mInventory_.changeMoney(-price);
        ::Base.mPlayerStats.addToInventory(shopItem);
        mInventory_[idx] = null;
        mPrices_[idx] = null;
        refreshGrid_();

        //Start fly-to-inventory animation
        if(mGetInventoryTabInfo_ != null){
            local tabInfo = mGetInventoryTabInfo_();
            local gridPos = mInventoryGrid_.getPositionForIdx(idx);
            local gridSize = mInventoryGrid_.getSizeForIdx(idx);
            local startCentre = gridPos + gridSize / 2;
            local anim = ::ShopBuyAnimation(shopItem, startCentre, gridSize, tabInfo.pos, tabInfo.size);
            mBuyAnimations_.append(anim);
        }
    }

    function calculateGridSize(){
        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        return mobile ? (::drawable.x / (mInventoryWidth_+2)) : 64;
    }

    function refreshGrid_(){
        mInventoryGrid_.setNewGridIcons(mInventory_);
    }

    function update(){
        mInventoryGrid_.update();

        //Update active buy animations
        local i = 0;
        while(i < mBuyAnimations_.len()){
            if(mBuyAnimations_[i].update()){
                mBuyAnimations_[i].shutdown();
                mBuyAnimations_.remove(i);
                //Emit event when buy animation completes
                _event.transmit(Event.SHOP_ITEM_ACQUIRED, null);
            }else{
                i++;
            }
        }
    }

    function shutdown(){
        mInventoryBus_.deregisterCallback(mBusCallbackId_);

        mInventoryGrid_.shutdown();

        foreach(anim in mBuyAnimations_){
            anim.shutdown();
        }
        mBuyAnimations_.clear();
    }

};