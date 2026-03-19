enum InventoryBusEvents{
    ITEM_HOVER_BEGAN,
    ITEM_HOVER_ENDED,
    ITEM_SELECTED,
    ITEM_GROUP_SELECTION_CHANGED,
    ITEM_HELPER_SCREEN_BEGAN,
    ITEM_HELPER_SCREEN_ENDED,

    ITEM_INFO_REQUEST_EQUIP,
    ITEM_INFO_REQUEST_EQUIP_LEFT_HAND,
    ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND,
    ITEM_INFO_REQUEST_UNEQUIP,
    ITEM_INFO_REQUEST_USE,
    ITEM_INFO_REQUEST_SCRAP,
    ITEM_INFO_REQUEST_SELL,
    ITEM_INFO_REQUEST_MOVE_TO_INVENTORY,
    ITEM_INFO_REQUEST_MOVE_OUT_OF_INVENTORY,
    ITEM_INFO_REQUEST_MOVE_TO_STORAGE,
    ITEM_INFO_REQUEST_MOVE_FROM_STORAGE,
    ITEM_INFO_REQUEST_READ,
    ITEM_INFO_REQUEST_BUY,
    ITEM_INFO_REQUEST_OPEN,
};

::ScreenManager.Screens[Screen.INVENTORY_SCREEN] = class extends ::Screen{

    mInventoryObj_ = null;

    mActionSetId_ = null;

    function setup(data){
        if( !(data.rawin("disableBackground") && data.disableBackground) ){
            createBackgroundScreen_();
        }

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        local disableBackgroundClose = false;
        if(data.rawin("disableBackgroundClose") && data.disableBackgroundClose){
            disableBackgroundClose = true;
        }
        if(mobile && !disableBackgroundClose){
            createBackgroundCloseButton_();
        }

        mWindow_ = _gui.createWindow("InventoryScreen");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClickable(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        mInventoryObj_ = ::InventoryScreenObject();
        mInventoryObj_.mLayerIdx = mLayerIdx;
        mInventoryObj_.setup(mWindow_, data);

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
    }

    function closeScreen(){
        mInventoryObj_.closeInventory();
    }

    function shutdown(){
        ::PlayerStatsOverlayManager.unregisterScreen("InventoryScreen");
        mInventoryObj_.shutdown();
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mInventoryObj_.setZOrder(idx);
        ::PlayerStatsOverlayManager.registerScreen("InventoryScreen", idx);
    }

    function update(){
        mInventoryObj_.update();
    }

};

::InventoryScreenObject <- class{

    mWindow_ = null;
    mOverlayWindow_ = null;
    mInventoryGrid_ = null;
    mInventoryEquippedGrid_ = null;
    mSecondaryInventoryGrid_ = null;
    mStorageGrid_ = null;
    mHoverInfo_ = null;
    mInventory_ = null;
    mItemStorage_ = null;
    //mMoneyCounter_ = null;
    mPlayerStats_ = null;
    mPlayerInspector_ = null;

    mEquippableLeftBg_ = null;
    mEquippableRightBg_ = null;
    mEquippableLeftGradient_ = null;
    mEquippableRightGradient_ = null;

    GRID_BACKGROUND_PADDING = 5;

    mLayerIdx = 0;

    mUseSecondaryGrid_ = false;
    mSecondaryItems_ = null;
    mSecondaryWidth_ = 0;
    mSecondaryHeight_ = 0;

    mSupportsStorage_ = false;
    mShowingStorage_ = false;

    mPreviousHighlight_ = null;

    mInventoryWidth = 5;

    mMultiSelection_ = false;

    mSellAvailable_ = false;

    mInventoryBus_ = null;
    mBusCallbackId_ = null;
    mStorageToggleButton_ = null;
    mAcceptButton_ = null;
    mRightSideHelperButtons_ = null;


    InventoryContainer = class{
        mWindow_ = null;

        mLayoutTable_ = null;

        constructor(parentWindow, inventory, bus){

            mWindow_ = _gui.createWindow("InventoryContainer", parentWindow);
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
        mInventoryGrid_.setNewGridIcons(data);
    }
    function receiveStorageChangedEvent(id, data){
        if(mStorageGrid_ != null){
            mStorageGrid_.setNewGridIcons(data);
        }
    }
    function receivePlayerEquipChangedEvent(id, data){
        mInventoryEquippedGrid_.setNewGridIcons(data.items.mItems);
    }

    function calculateGridSize(){
        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        return mobile ? (::drawable.x / (mInventoryWidth+2)) : 64;
    }

    function setup(window, data){
        mWindow_ = window;
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        _event.subscribe(Event.STORAGE_CONTENTS_CHANGED, receiveStorageChangedEvent, this);
        _event.subscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent, this);

        local startOffset = 0;
        if(data.rawin("startOffset")){
            startOffset = data.rawget("startOffset");
        }

        // Check if this inventory screen supports multi-selection
        mMultiSelection_ = false;
        if(data.rawin("multiSelection")){
            mMultiSelection_ = data.multiSelection;
        }

        // Check if this inventory screen supports storage
        mSupportsStorage_ = false;
        if(data.rawin("supportsStorage")){
            mSupportsStorage_ = data.supportsStorage;
        }

        // Check if this inventory screen allows selling items
        mSellAvailable_ = false;
        if(data.rawin("sellAvailable")){
            mSellAvailable_ = data.sellAvailable;
        }

        if(data.rawin("items")){
            //mSecondaryItems_ = array(4 * 4, null);
            //mSecondaryItems_[0] = ::Item(ItemId.APPLE);
            mSecondaryItems_ = data.items;
            mSecondaryWidth_ = data.width;
            mSecondaryHeight_ = data.height;
            mUseSecondaryGrid_ = true;
        }

        mPlayerStats_ = data.stats;
        mInventory_ = mPlayerStats_.mInventory_;
        mItemStorage_ = mPlayerStats_.mItemStorage_;

        mInventoryBus_ = InventoryInfoBus();
        mBusCallbackId_ = mInventoryBus_.registerCallback(busCallback, this);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        mRightSideHelperButtons_ = [];

        local inventoryButton = null;
        local backButtonDisabled = false;
        if(data.rawin("disableBackButton") && data.disableBackButton){
            backButtonDisabled = true;
        }
        if(!backButtonDisabled){
            /*
            inventoryButton.setText("Back");
            inventoryButton.setPosition(5, 25);
            inventoryButton.attachListenerForEvent(function(widget, action){
                closeInventory();
            }, _GUI_ACTION_PRESSED, this);
            */

            inventoryButton = ::IconButton(mWindow_, "backButtonIcon");
            inventoryButton.setSize(Vec2(64, 64));
            inventoryButton.attachListenerForEvent(function(widget, action){
                ::HapticManager.triggerSimpleHaptic(HapticType.SELECTION);
                closeInventory();
            }, _GUI_ACTION_PRESSED, this);
            inventoryButton.setSkinPack("Panel_blue");
            mRightSideHelperButtons_.append(inventoryButton);
        }

        if(mMultiSelection_){
            local multiSelectionLabel = "Accept";
            if(data.rawin("acceptButtonLabel")){
                multiSelectionLabel = data.acceptButtonLabel;
            }
            mAcceptButton_ = ::IconButtonComplex(mWindow_, {
                "icon": "greenTickX2",
                "iconSize": Vec2(48, 48),
                "iconCentre": Vec2(32, 22),
                "label": multiSelectionLabel,
                "labelCentre": Vec2(32, 50),
                "labelSizeModifier": 0.75,
                "skinPack": "Panel_green"
            });

            mAcceptButton_.setDisabled(true);
            mAcceptButton_.attachListenerForEvent(function(widget, action){
                ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
                acceptSelection_();
            }, _GUI_ACTION_PRESSED, this);
            mRightSideHelperButtons_.append(mAcceptButton_);
        }

        local layoutLine = _gui.createLayoutLine();

        /*
        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Inventory", false);
        title.sizeToFit(::drawable.x * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);
        */

        //mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        //mMoneyCounter_.addToLayout(layoutLine);

        //local playerEquip = InventoryPlayerEquip(mWindow_, mPlayerStats_, mInventoryBus_);
        //playerEquip.addToLayout(layoutLine);

        //local container = InventoryContainer(mWindow_, mInventory_, mInventoryBus_);
        //container.addToLayout(layoutLine);

        mOverlayWindow_ = _gui.createWindow("InventoryOverlayWindow");
        mOverlayWindow_.setPosition(0, 0);
        mOverlayWindow_.setSize(::drawable.x, ::drawable.y);
        mOverlayWindow_.setVisualsEnabled(false);
        mOverlayWindow_.setConsumeCursor(false);
        mOverlayWindow_.setSkinPack("WindowSkinNoBorder");

        local buttonCover = null;
        if(!mobile){
            buttonCover = createButtonCover(mOverlayWindow_);
        }
        mHoverInfo_ = ::InventoryHoverItemInfo(mOverlayWindow_);

        // Create equippable background panels and gradient overlays early
        mEquippableLeftBg_ = mWindow_.createPanel();
        mEquippableLeftBg_.setSize(0, 0);
        mEquippableLeftBg_.setPosition(-1000, -1000);
        mEquippableLeftBg_.setSkin("Panel_lightGrey");
        //mEquippableLeftBg_.setColour(ColourValue(0.1, 0.1, 0.1, 0.7));
        mEquippableLeftBg_.setClickable(false);

        mEquippableRightBg_ = mWindow_.createPanel();
        mEquippableRightBg_.setSize(0, 0);
        mEquippableRightBg_.setPosition(-1000, -1000);
        mEquippableRightBg_.setSkin("Panel_lightGrey");
        //mEquippableRightBg_.setColour(ColourValue(0.1, 0.1, 0.1, 0.7));
        mEquippableRightBg_.setClickable(false);

        //Add one for the equippables slot and another for general padding.
        local gridSize = calculateGridSize();

            mPlayerInspector_ = ::GuiWidgets.InventoryPlayerInspector();
            mPlayerInspector_.setup(mWindow_);

        local layoutHorizontal = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, mHoverInfo_, buttonCover, mMultiSelection_);
        local inventoryHeight = mInventory_.getInventorySize() / mInventoryWidth;
        mInventoryGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, mInventoryWidth, inventoryHeight);
        //mInventoryGrid_.addToLayout(layoutLine);
        mInventoryGrid_.addToLayout(layoutHorizontal);

        mInventoryEquippedGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_EQUIPPABLES, mInventoryBus_, mHoverInfo_, buttonCover, mMultiSelection_, false);
        mInventoryEquippedGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, null, null);
        //mInventoryEquippedGrid_.addToLayout(layoutLine);
        //mInventoryEquippedGrid_.addToLayout(layoutHorizontal);

        if(mUseSecondaryGrid_){
            mSecondaryInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID_SECONDARY, mInventoryBus_, mHoverInfo_, buttonCover, mMultiSelection_);
            mSecondaryInventoryGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, mSecondaryWidth_, mSecondaryHeight_);
            //mSecondaryInventoryGrid_.addToLayout(layoutLine);
            mSecondaryInventoryGrid_.addToLayout(layoutHorizontal);
        }

        if(mSupportsStorage_){
            mStorageGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, mHoverInfo_, buttonCover, mMultiSelection_);
            local storageHeight = mItemStorage_.getInventorySize() / mInventoryWidth;
            mStorageGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, mInventoryWidth, storageHeight);
            mStorageGrid_.addToLayout(layoutHorizontal);
        }

        mInventoryGrid_.connectNeighbours(mInventoryEquippedGrid_, mRightSideHelperButtons_.len() > 0 ? mRightSideHelperButtons_[0] : null);
        if(mSecondaryInventoryGrid_ != null){
            mInventoryEquippedGrid_.connectNeighbours([mInventoryGrid_, mSecondaryInventoryGrid_], mRightSideHelperButtons_.len() > 0 ? mRightSideHelperButtons_[0] : null);
            mSecondaryInventoryGrid_.connectNeighbours(mInventoryEquippedGrid_, mRightSideHelperButtons_.len() > 0 ? mRightSideHelperButtons_[0] : null);
        }else{
            mInventoryEquippedGrid_.connectNeighbours(mInventoryGrid_, mRightSideHelperButtons_.len() > 0 ? mRightSideHelperButtons_[0] : null);
        }

        if(mRightSideHelperButtons_.len() > 0){
            local inventoryButton = mRightSideHelperButtons_[0];
            inventoryButton.setNextWidget(mInventoryGrid_.mWidgets_[0], _GUI_BORDER_RIGHT);
            inventoryButton.setNextWidget(mInventoryGrid_.mWidgets_[0], _GUI_BORDER_BOTTOM);

            inventoryButton.setFocus();
        }

        //if(!mobile){
            //mPlayerInspector_.setPosition(mInventoryEquippedGrid_.calculateChildrenSize().x * 2, 0);
            //mPlayerInspector_.addToLayout(mobile ? layoutLine : layoutHorizontal);
        //}

        layoutHorizontal.setMarginForAllCells(10, 0);
        if(mUseSecondaryGrid_){
            //Add some spacing to make the chest contents more obvious.
            mSecondaryInventoryGrid_.mWindow_.setMargin(150, 0);
        }
        layoutLine.addCell(layoutHorizontal);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(::drawable.x * 0.05, 10);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.setHardMaxSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.layout();

        mInventoryGrid_.notifyLayout();
        mInventoryGrid_.setNewGridIcons(mInventory_.mInventoryItems_);
        mInventoryEquippedGrid_.setNewGridIcons(mPlayerStats_.mPlayerCombatStats.mEquippedItems.mItems);
        if(mUseSecondaryGrid_){
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }
        if(mSupportsStorage_){
            mStorageGrid_.setNewGridIcons(mItemStorage_.mInventoryItems_);
            mStorageGrid_.setHidden(true);
        }

        local inspectorSize = mPlayerInspector_.getSize();
        //inspectorSize.x = mInventoryGrid_.getSize().x
        local widgetSize = mInventoryEquippedGrid_.getWidgetSize();
        inspectorSize.x = ::drawable.x - widgetSize.x * 2 - GRID_BACKGROUND_PADDING * 2;
        mPlayerInspector_.setSize(inspectorSize);
        mPlayerInspector_.setPosition(widgetSize.x + GRID_BACKGROUND_PADDING * 3, startOffset);
        local inspectorSize = mPlayerInspector_.getSize();
        //container.sizeInner();
        //if(!mobile){
            repositionEquippablesGrid();

            inspectorSize.x -= GRID_BACKGROUND_PADDING * 4;
            inspectorSize.y = (mInventoryEquippedGrid_.getSize().y / 2) + GRID_BACKGROUND_PADDING * 2;
            mPlayerInspector_.setSize(inspectorSize);
            mPlayerInspector_.notifyLayout();
        //}

        local gridStart = mPlayerInspector_.getPosition() + mPlayerInspector_.getSize() + GRID_BACKGROUND_PADDING;
        local gridSize = mInventoryGrid_.getSize();
        gridStart.x = GRID_BACKGROUND_PADDING;
        local targetGridPos = gridStart + Vec2(GRID_BACKGROUND_PADDING, GRID_BACKGROUND_PADDING);
        mInventoryGrid_.setPosition(targetGridPos);
        if(mStorageGrid_ != null){
            mStorageGrid_.setPosition(targetGridPos);
        }

        if(mSupportsStorage_){
            mStorageToggleButton_ = ::IconButtonComplex(mWindow_, {
                "icon": "bagIcon",
                "iconSize": Vec2(64, 64),
                "iconCentre": Vec2(6, 0),
                "label": "",
                "labelCentre": Vec2(32, 45),
                "labelSizeModifier": 0.75,
                "skinPack": "Panel_blue"
            });
            mStorageToggleButton_.attachListenerForEvent(function(widget, action){
                toggleStorageVisibility();
                ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            }, _GUI_ACTION_PRESSED, this);
            mRightSideHelperButtons_.append(mStorageToggleButton_);
        }

        positionRightSideHelperButtons_();
        updateStorageToggleButtonText_();
    }

    function repositionEquippablesGrid(){
        local startPos = mPlayerInspector_.getPosition();
        local widgetSize = mInventoryEquippedGrid_.getWidgetSize();
        //mInventoryEquippedGrid_.setSize(mInventoryEquippedGrid_.calculateChildrenSize());
        //mInventoryEquippedGrid_.setSize(::drawable);
        //local rightPos = mPlayerInspector_.getModelExtentRight();
        //local leftPos = mPlayerInspector_.getModelExtentLeft();
        local leftPos = Vec2(GRID_BACKGROUND_PADDING * 2, GRID_BACKGROUND_PADDING * 2);
        local rightPos = mPlayerInspector_.getSize();
        rightPos.x += widgetSize.x;

        local leftGreatestY = startPos.y;
        local rightGreatestY = startPos.y;

        for(local i = 0; i < EquippedSlotTypes.MAX-1; i++){
            local target = (i < 4 ? leftPos : rightPos).copy();
            target.y = GRID_BACKGROUND_PADDING;
            target.y += (i % 4) * widgetSize.y;
            target.y += startPos.y;
            mInventoryEquippedGrid_.setPositionForIdx(i, target);
            if(i < 4){
                if(target.y + widgetSize.y > leftGreatestY) leftGreatestY = target.y + widgetSize.y;
            }else{
                if(target.y + widgetSize.y > rightGreatestY) rightGreatestY = target.y + widgetSize.y;
            }
        }

        // Update background panels behind the two equippable columns
        local colValue = ColourValue(0.1, 0.1, 0.1, 0.7);
        local leftBgPos = Vec2(leftPos.x - GRID_BACKGROUND_PADDING, startPos.y);
        local leftBgSize = Vec2(widgetSize.x + GRID_BACKGROUND_PADDING * 2, max(0, leftGreatestY - startPos.y) + GRID_BACKGROUND_PADDING);
        mEquippableLeftBg_.setPosition(leftBgPos);
        mEquippableLeftBg_.setSize(leftBgSize);
        //mEquippableLeftBg_.setColour(colValue);
        mEquippableLeftBg_.setSkinPack("Panel_lightGrey");
        mEquippableLeftBg_.setClickable(false);

        //local rightBg = mWindow_.createPanel();
        local rightBgPos = Vec2(rightPos.x - GRID_BACKGROUND_PADDING, startPos.y);
        local rightBgSize = Vec2(widgetSize.x + GRID_BACKGROUND_PADDING * 2, max(0, rightGreatestY - startPos.y) + GRID_BACKGROUND_PADDING);
        mEquippableRightBg_.setPosition(rightBgPos);
        mEquippableRightBg_.setSize(rightBgSize);
        //mEquippableRightBg_.setColour(colValue);
        mEquippableRightBg_.setSkinPack("Panel_lightGrey");
        mEquippableRightBg_.setClickable(false);

        // Add subtle gradients overlaying the backgrounds
        local gradientLeft = mWindow_.createPanel();
        local gradientLeftPos = Vec2(widgetSize.x + GRID_BACKGROUND_PADDING * 3, startPos.y);
        gradientLeft.setPosition(gradientLeftPos);
        gradientLeft.setSize(Vec2(64, max(0, leftGreatestY - startPos.y) + GRID_BACKGROUND_PADDING));
        gradientLeft.setColour(ColourValue(1, 1, 1, 0.5));
        gradientLeft.setDatablock("gui/linearGradientLeft");
        gradientLeft.setClickable(false);

        local gradientRight = mWindow_.createPanel();
        local gradientRightPos = Vec2(rightPos.x - 64 - GRID_BACKGROUND_PADDING, startPos.y);
        gradientRight.setPosition(gradientRightPos);
        gradientRight.setSize(Vec2(64, max(0, rightGreatestY - startPos.y) + GRID_BACKGROUND_PADDING));
        gradientRight.setColour(ColourValue(1, 1, 1, 0.5));
        gradientRight.setDatablock("gui/linearGradientRight");
        gradientRight.setClickable(false);
    }

    function toggleStorageVisibility(){
        if(mStorageGrid_ == null) return;

        mShowingStorage_ = !mShowingStorage_;

        mInventoryGrid_.setHidden(mShowingStorage_);
        mStorageGrid_.setHidden(!mShowingStorage_);
        mInventoryGrid_.notifyPositionChanged();
        mStorageGrid_.notifyPositionChanged();
        positionRightSideHelperButtons_();
        updateStorageToggleButtonText_();
    }

    function updateStorageToggleButtonText_(){
        if(mStorageToggleButton_ != null){
            mStorageToggleButton_.setText(!mShowingStorage_ ? "Inventory" : "Storage");
            local storageSize = mStorageToggleButton_.getSize();
            mStorageToggleButton_.mData_.labelCentre = Vec2(storageSize.x * 0.5, storageSize.y * 0.75);
            mStorageToggleButton_.mData_.iconCentre = Vec2(storageSize.x * 0.5, storageSize.y * 0.45);
            mStorageToggleButton_.setPosition(mStorageToggleButton_.getPosition());
            //local newSize = mStorageToggleButton_.getSize();
            //newSize.y = newSize.y * 0.75;
            //mStorageToggleButton_.setSize(newSize);
        }
    }

    function positionRightSideHelperButtons_(){
        if(mRightSideHelperButtons_ == null||mInventoryGrid_ == null) return;

        //Get the active grid (storage or inventory)
        local activeGrid = mShowingStorage_ && mStorageGrid_ != null ? mStorageGrid_ : mInventoryGrid_;
        local gridPos = activeGrid.getPosition();
        local gridSize = activeGrid.getSize();
        local buttonXPos = gridPos.x + gridSize.x + 10;
        local buttonYPos = gridPos.y - GRID_BACKGROUND_PADDING;

        foreach(buttonIdx, button in mRightSideHelperButtons_){
            //Calculate available space for this button
            local availableWidth = ::drawable.x - buttonXPos - GRID_BACKGROUND_PADDING;
            local remainingHeight = ::drawable.y - buttonYPos - GRID_BACKGROUND_PADDING;

            //Make the button square if there's space, respecting margins
            local buttonSize = min(availableWidth, remainingHeight);
            buttonSize = max(buttonSize, 64);

            button.setSize(Vec2(buttonSize, buttonSize));
            button.setPosition(Vec2(buttonXPos, buttonYPos));

            //Move to next button position
            buttonYPos += buttonSize + 10;
        }

        if(mAcceptButton_ != null){
            local acceptSize = mAcceptButton_.getSize();
            mAcceptButton_.mData_.iconCentre = Vec2(acceptSize.x * 0.5, acceptSize.y * 0.35);
            mAcceptButton_.mData_.labelCentre = Vec2(acceptSize.x * 0.5, acceptSize.y * 0.75);
            mAcceptButton_.setPosition(mAcceptButton_.getPosition());
            mAcceptButton_.scaleHeightForLabel();
        }
    }

    function getTargetInventory_(){
        return mShowingStorage_ ? mItemStorage_ : mInventory_;
    }

    function getGridForData_(inventoryData){
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            return mInventoryEquippedGrid_;
        }else if(inventoryData.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            return mSecondaryInventoryGrid_;
        }else{
            return mShowingStorage_ ? mStorageGrid_ : mInventoryGrid_;
        }
    }

    function highlightPrevious(){
        processItemHover(mPreviousHighlight_);

        _gui.simulateGuiPrimary(false);

        if(mPreviousHighlight_ != null){
            if(mPreviousHighlight_.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
                mInventoryEquippedGrid_.highlightForIdx(mPreviousHighlight_.id);
            }else if(mPreviousHighlight_.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                mSecondaryInventoryGrid_.highlightForIdx(mPreviousHighlight_.id);
            }else{
                mInventoryGrid_.highlightForIdx(mPreviousHighlight_.id);
            }
        }

        mPreviousHighlight_ = null;
    }

    function createButtonCover(win){
        local cover = win.createPanel();
        cover.setDatablock("gui/inventoryHighlightCover");
        cover.setHidden(true);
        cover.setZOrder(155);
        cover.setClickable(false);
        cover.setKeyboardNavigable(false);

        return cover;
    }

    function busCallback(event, data){
        if(event == InventoryBusEvents.ITEM_SELECTED){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            selectItem(data);
        }
        else if(event == InventoryBusEvents.ITEM_GROUP_SELECTION_CHANGED){
            updateAcceptButtonState_();
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_BEGAN){
            processItemHover(data);
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_ENDED){
            processItemHover(null);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_USE){
            if(data.gridType == InventoryGridType.INVENTORY_GRID){
                local targetInventory = getTargetInventory_();
                local itemForIdx = targetInventory.getItemForIdx(data.idx);
                ::ItemHelper.actuateItem(itemForIdx);
                targetInventory.removeFromInventory(data.idx);
            }else if(data.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                local item = mSecondaryItems_[data.idx];
                mSecondaryItems_[data.idx] = null;
                mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
                ::ItemHelper.actuateItem(item);
            }
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP){
            disposeOfItem(data, false);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_SELL){
            disposeOfItem(data, true);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_OPEN){
            local inventoryData = data;
            removeFromInventory_(inventoryData);

            //Calculate the window position of the item being opened
            local idx = inventoryData.idx;
            local targetGrid = getGridForData_(inventoryData);

            local posForIdx = targetGrid.getPositionForIdx(idx);
            local gridItemSize = targetGrid.getSizeForIdx(idx);
            local itemCentre = posForIdx + (gridItemSize / 2);

            //Convert window position to world position
            local worldPos = ::EffectManager.getWorldPositionForWindowPos(itemCentre);

            local capturedInventoryData = inventoryData;
            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.COLLECTABLE_OPEN_SCREEN, {
                "startPos": worldPos,
                "itemScale": 10,
                "onClose": function() {
                    setItemForInventory(capturedInventoryData, ::Item(ItemId.NOTE_SCRAP, {"artifactId": 0}));
                }.bindenv(this)
            }), null, 3);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_TO_INVENTORY){
            local item = mSecondaryItems_[data.idx];
            local success = mInventory_.addToInventory(item);
            if(!success){
                return;
            }

            mSecondaryItems_[data.idx] = null;
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_OUT_OF_INVENTORY){
            assert(mSecondaryItems_ != null);
            local foundHole = false;
            local holeIdx = -1;
            foreach(c,i in mSecondaryItems_){
                if(i == null){
                    foundHole = true;
                    holeIdx = c;
                    break;
                }
            }
            if(!foundHole) return;
            assert(holeIdx != -1);

            local item = mInventory_.getItemForIdx(data.idx);
            mInventory_.removeFromInventory(data.idx);
            mSecondaryItems_[holeIdx] = item;
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }
        else if(
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP ||
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_LEFT_HAND ||
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND)
        {

            local item =null;
            if(data.gridType == InventoryGridType.INVENTORY_GRID){
                local targetInventory = getTargetInventory_();
                item = targetInventory.getItemForIdx(data.idx);
                targetInventory.removeFromInventory(data.idx);
            }else if(data.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                item = mSecondaryItems_[data.idx];
                mSecondaryItems_[data.idx] = null;
                mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
            }
            assert(item != null);

            local equippableData = ::Equippables[item.getEquippableData()];
            local equipSlot = equippableData.getEquippedSlot();
            if(event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_LEFT_HAND){
                equipSlot = EquippedSlotTypes.LEFT_HAND;
            }
            else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND){
                equipSlot = EquippedSlotTypes.RIGHT_HAND;
            }

            if(equipSlot == EquippedSlotTypes.RIGHT_HAND || equipSlot == EquippedSlotTypes.LEFT_HAND){
                local item = mPlayerStats_.unequipTwoHandedItem();
                if(item != null) mInventory_.addToInventory(item);
            }

            if(equippableData.getEquippableCharacteristics() & EquippableCharacteristics.TWO_HANDED){
                if(mInventory_.getNumSlotsFree() >= 2){
                    local leftHandItem = mPlayerStats_.getEquippedItem(EquippedSlotTypes.LEFT_HAND);
                    local rightHandItem = mPlayerStats_.getEquippedItem(EquippedSlotTypes.RIGHT_HAND);
                    if(leftHandItem != null){
                        mPlayerStats_.unEquipItem(EquippedSlotTypes.LEFT_HAND);
                        mInventory_.addToInventory(leftHandItem);
                    }
                    if(rightHandItem != null){
                        mPlayerStats_.unEquipItem(EquippedSlotTypes.RIGHT_HAND);
                        mInventory_.addToInventory(rightHandItem);
                    }
                }
            }

            local previousEquipped = mPlayerStats_.equipItem(item, equipSlot);
            if(previousEquipped != null){
                mInventory_.addToInventory(previousEquipped);
            }
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_UNEQUIP){
            local idx = data+1;
            local item = mPlayerStats_.getEquippedItem(idx);
            mPlayerStats_.unEquipItem(idx);
            //TODO check if the inventory has space.
            mInventory_.addToInventory(item);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_READ){
            local item = null;
            if(data.gridType == InventoryGridType.INVENTORY_GRID){
                local targetInventory = getTargetInventory_();
                item = targetInventory.getItemForIdx(data.idx);
            }else if(data.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                item = mSecondaryItems_[data.idx];
            }
            if(item == null) return;

            ::Base.mExplorationLogic.readLoreContentForItem(item);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_TO_STORAGE){
            if(!mSupportsStorage_) return;
            transferItemBetweenInventories_(getTargetInventory_(), mItemStorage_, data.idx);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_MOVE_FROM_STORAGE){
            if(!mSupportsStorage_) return;
            transferItemBetweenInventories_(mItemStorage_, mInventory_, data.idx);
        }
        else if(event == InventoryBusEvents.ITEM_HELPER_SCREEN_ENDED){
            highlightPrevious();
        }
    }

    function disposeOfItem(inventoryData, isSell){
        local targetItem = removeFromInventory_(inventoryData);
        if(targetItem == null) return;

        local itemValue = isSell ? targetItem.getSellValue() : targetItem.getScrapVal();
        local actionDescription = isSell ? "Selling" : "Scrapping";
        printf("Adding %s value %i for item: %s", actionDescription, itemValue, targetItem.tostring());

        //Get the item position for the effect origin
        local idx = inventoryData.idx;
        local targetGrid = getGridForData_(inventoryData);
        local posForIdx = targetGrid.getPositionForIdx(idx);
        local gridItemSize = targetGrid.getSizeForIdx(idx);
        local itemCentre = posForIdx + (gridItemSize / 2);
        local startPos = ::EffectManager.getWorldPositionForWindowPos(itemCentre);

        local moneyCounterPos = null;
        //Get the money counter position as the destination
        //TODO pretty nasty
        if(::Base.mExplorationLogic.mGui_ == null){
            moneyCounterPos = ::ScreenManager.getScreenForLayer(0).mPlayerStats_.getMoneyCounter();
        }else{
            moneyCounterPos = ::Base.mExplorationLogic.mGui_.getMoneyCounterWindowPos();
        }

        //Add money without triggering event (effect will handle counter update)
        ::Base.mPlayerStats.changeMoney(itemValue, false);

        //Display the spread coin effect
        ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"numCoins": itemValue, "start": startPos, "end": moneyCounterPos, "money": itemValue, "coinScale": 10, "cellSize": 100}));
    }

    function removeFromInventory_(inventoryData){
        local targetItem = null;
        local idx = inventoryData.idx;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            targetItem = mPlayerStats_.getEquippedItem(idx+1);
            mPlayerStats_.unEquipItem(idx+1);
        }else if(inventoryData.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            targetItem = mSecondaryItems_[idx];
            mSecondaryItems_[idx] = null;
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }else{
            local targetInventory = getTargetInventory_();
            targetItem = targetInventory.getItemForIdx(idx);
            targetInventory.removeFromInventory(idx);
        }
        return targetItem;
    }

    function setItemForInventory(inventoryData, item){
        local idx = inventoryData.idx;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            mPlayerStats_.equipItem(item, idx);
        }else if(inventoryData.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            mSecondaryItems_[idx] = item;
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }else{
            local targetInventory = getTargetInventory_();
            targetInventory.setItemForIdx(item, idx);
        }
    }

    function transferItemBetweenInventories_(sourceInventory, targetInventory, itemIdx){
        local item = sourceInventory.getItemForIdx(itemIdx);
        if(item == null) return;

        // Check if target inventory has space
        if(targetInventory.getNumSlotsFree() <= 0){
            return;
        }

        sourceInventory.removeFromInventory(itemIdx);
        local success = targetInventory.addToInventory(item);
        if(!success){
            // Item could not be added to target, put it back in source
            sourceInventory.addToInventory(item);
            return;
        }
    }

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
            local targetInventory = getTargetInventory_();
            selectedItem = targetInventory.getItemForIdx(idx);
            targetGrid = mShowingStorage_ ? mStorageGrid_ : mInventoryGrid_;
        }
        if(selectedItem == null) return;
        print("Selected item " + selectedItem.tostring());
        setHoverMenuToItem(null);

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
            "secondaryGrid": mUseSecondaryGrid_,
            "showItemInfo": mobile,
            "supportsStorage": mSupportsStorage_,
            "isShowingStorage": mShowingStorage_,
            "inventory": mInventory_,
            "storage": mItemStorage_,
            "inventoryFull": mInventory_.getNumSlotsFree() == 0,
            "sellAvailable": mSellAvailable_
        };
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_ITEM_HELPER_SCREEN, data), null, mLayerIdx+1);
    }

    function processItemHover(inventoryData){
        if(inventoryData != null){
            mPreviousHighlight_ = inventoryData;
        }

        if(inventoryData == null){
            setHoverMenuToItem(null);
            return;
        }
        local idx = inventoryData.id;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            //Skip the NONE object.
            local item = mPlayerStats_.getEquippedItem(idx+1);
            setHoverMenuToItem(item);
        }
        else if(inventoryData.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
            local item = mSecondaryItems_[idx];
            setHoverMenuToItem(item);
        }
        else{
            local targetInventory = getTargetInventory_();
            local item = targetInventory.getItemForIdx(idx);
            setHoverMenuToItem(item);
        }
    }
    function setHoverMenuToItem(item){
        //TODO this might be getting called twice.
        //print(item);
        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        if(item == null || mobile){
            mHoverInfo_.setVisible(false);
            return;
        }
        mHoverInfo_.setItem(item);
        mHoverInfo_.setVisible(true);
    }

    function notifyPositionChanged(){
        if(mInventoryGrid_ != null){
            mInventoryGrid_.notifyPositionChanged();
        }
        if(mInventoryEquippedGrid_ != null){
            mInventoryEquippedGrid_.notifyPositionChanged();
        }
        if(mSecondaryInventoryGrid_ != null){
            mSecondaryInventoryGrid_.notifyPositionChanged();
        }
        if(mStorageGrid_ != null){
            mStorageGrid_.notifyPositionChanged();
        }
    }

    function setZOrder(idx){
        mOverlayWindow_.setZOrder(idx+1);
    }

    function shutdown(){
        _gui.destroy(mOverlayWindow_);
        //mMoneyCounter_.shutdown();
        mInventoryBus_.deregisterCallback(mBusCallbackId_);
        if(mPlayerInspector_ != null){
            mPlayerInspector_.shutdown();
        }
        if(mInventoryGrid_ != null){
            mInventoryGrid_.shutdown();
        }
        if(mInventoryEquippedGrid_ != null){
            mInventoryEquippedGrid_.shutdown();
        }
        if(mSecondaryInventoryGrid_ != null){
            mSecondaryInventoryGrid_.shutdown();
        }
        if(mStorageGrid_ != null){
            mStorageGrid_.shutdown();
        }
        //base.shutdown();
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent);
        _event.unsubscribe(Event.STORAGE_CONTENTS_CHANGED, receiveStorageChangedEvent);
        _event.unsubscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent);
    }

    function update(){
        mInventoryGrid_.update();
        if(mInventoryEquippedGrid_ != null){
            mInventoryEquippedGrid_.update();
        }
        if(mSecondaryInventoryGrid_ != null){
            mSecondaryInventoryGrid_.update();
        }
        if(mStorageGrid_ != null){
            mStorageGrid_.update();
        }
        mHoverInfo_.update();
        if(mPlayerInspector_ != null){
            mPlayerInspector_.update();
        }

        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isScreenTop(mLayerIdx)) closeInventory();
        }
    }

    function closeInventory(){
        //::ScreenManager.backupScreen(mLayerIdx);
        if(mLayerIdx == 0){
            ::ScreenManager.backupScreen(mLayerIdx);
        }else{
            ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
        }
        ::Base.mExplorationLogic.unPauseExploration();
        _event.transmit(Event.INVENTORY_CLOSED, null);
    }

    function updateAcceptButtonState_(){
        if(mAcceptButton_ == null) return;

        local totalSelectedItems = 0;
        if(mInventoryGrid_ != null){
            totalSelectedItems += mInventoryGrid_.getSelectedItemCount();
        }
        if(mInventoryEquippedGrid_ != null){
            totalSelectedItems += mInventoryEquippedGrid_.getSelectedItemCount();
        }
        if(mSecondaryInventoryGrid_ != null){
            totalSelectedItems += mSecondaryInventoryGrid_.getSelectedItemCount();
        }
        if(mStorageGrid_ != null){
            totalSelectedItems += mStorageGrid_.getSelectedItemCount();
        }

        mAcceptButton_.setDisabled(totalSelectedItems == 0);
    }

    function acceptSelection_(){
        local selectedItems = [];

        addItemsFromGrid_(mInventoryGrid_, mInventory_, InventoryGridType.INVENTORY_GRID, selectedItems);
        addItemsFromGrid_(mSecondaryInventoryGrid_, mSecondaryItems_ != null ? mSecondaryItems_ : null, InventoryGridType.INVENTORY_GRID_SECONDARY, selectedItems);
        addItemsFromGrid_(mStorageGrid_, mItemStorage_, InventoryGridType.INVENTORY_GRID, selectedItems);

        //Add equipped items separately since they don't use getItemForIdx
        if(mInventoryEquippedGrid_ != null){
            local selectedArray = mInventoryEquippedGrid_.getSelectedItems();
            foreach(idx, selected in selectedArray){
                if(selected){
                    local item = mPlayerStats_.getEquippedItem(idx + 1);
                    if(item != null){
                        selectedItems.append({
                            "item": item,
                            "idx": idx,
                            "gridType": InventoryGridType.INVENTORY_EQUIPPABLES
                        });
                    }
                }
            }
        }

        local eventData = {
            "items": selectedItems,
            "count": selectedItems.len()
        };

        closeInventory();

        _event.transmit(Event.INVENTORY_SELECTION_FINISHED, eventData);
    }

    function addItemsFromGrid_(grid, targetInventory, gridType, selectedItems){
        if(grid == null) return;
        local selectedArray = grid.getSelectedItems();
        foreach(idx, selected in selectedArray){
            if(selected && targetInventory != null){
                local item = targetInventory.getItemForIdx(idx);
                if(item != null){
                    selectedItems.append({
                        "item": item,
                        "idx": idx,
                        "gridType": gridType
                    });
                }
            }
        }
    }
};

_doFile("res://src/GUI/Widgets/InventoryGrid.nut");
_doFile("res://src/GUI/Widgets/InventoryPlayerInspector.nut");