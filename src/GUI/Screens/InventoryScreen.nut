enum InventoryBusEvents{
    ITEM_HOVER_BEGAN,
    ITEM_HOVER_ENDED,
    ITEM_SELECTED,
    ITEM_HELPER_SCREEN_BEGAN,
    ITEM_HELPER_SCREEN_ENDED,

    ITEM_INFO_REQUEST_EQUIP,
    ITEM_INFO_REQUEST_EQUIP_LEFT_HAND,
    ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND,
    ITEM_INFO_REQUEST_UNEQUIP,
    ITEM_INFO_REQUEST_USE,
    ITEM_INFO_REQUEST_SCRAP,
    ITEM_INFO_REQUEST_MOVE_TO_INVENTORY,
    ITEM_INFO_REQUEST_MOVE_OUT_OF_INVENTORY,
    ITEM_INFO_REQUEST_READ,
};

::ScreenManager.Screens[Screen.INVENTORY_SCREEN] = class extends ::Screen{

    mInventoryObj_ = null;

    mActionSetId_ = null;

    function setup(data){
        if( !(data.rawin("disableBackground") && data.disableBackground) ){
            createBackgroundScreen_();
        }

        mWindow_ = _gui.createWindow("InventoryScreen");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        mInventoryObj_ = ::InventoryScreenObject();
        mInventoryObj_.mLayerIdx = mLayerIdx;
        mInventoryObj_.setup(mWindow_, data);

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
    }

    function shutdown(){
        mInventoryObj_.shutdown();
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mInventoryObj_.setZOrder(idx);
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
    mHoverInfo_ = null;
    mInventory_ = null;
    //mMoneyCounter_ = null;
    mPlayerStats_ = null;
    mPlayerInspector_ = null;

    mLayerIdx = 0;

    mUseSecondaryGrid_ = false;
    mSecondaryItems_ = null;
    mSecondaryWidth_ = 0;
    mSecondaryHeight_ = 0;

    mPreviousHighlight_ = null;

    mInventoryWidth = 5;

    mInventoryBus_ = null;
    mBusCallbackId_ = null;

    HoverItemInfo = class{
        mHoverWin_ = null;

        mTitleLabel_ = null;
        mDescriptionLabel_ = null;
        mStatsLabel_ = null;

        mActive_ = false;

        constructor(overlayWindow){
            mHoverWin_ = overlayWindow.createWindow("InventoryHoverInfoWindow");
            mHoverWin_.setSize(400, 200);
            mHoverWin_.setHidden(true);
            mHoverWin_.setPosition(0, 0);
            mHoverWin_.setZOrder(200);
            mHoverWin_.setClickable(false);
            mHoverWin_.setKeyboardNavigable(false);

            local layout = _gui.createLayoutLine();
            mTitleLabel_ = mHoverWin_.createLabel();
            mTitleLabel_.setText(" ");
            layout.addCell(mTitleLabel_);

            mDescriptionLabel_ = mHoverWin_.createLabel();
            mDescriptionLabel_.setText(" ");
            layout.addCell(mDescriptionLabel_);

            mStatsLabel_ = mHoverWin_.createLabel();
            mStatsLabel_.setText(" ");
            layout.addCell(mStatsLabel_);

            layout.layout();
        }

        function update(){
            if(mActive_){
                local xx = _input.getMouseX().tofloat() / ::drawable.x.tofloat();
                local yy = _input.getMouseY().tofloat() / ::drawable.y.tofloat();
                setPosition((::drawable.x*xx), (::drawable.y*yy));
            }
        }

        function destroy(){
            _gui.destroy(actionMenuWin_);
        }

        function setVisible(vis){
            mActive_ = vis;
            mHoverWin_.setVisible(vis);
        }

        function setPosition(x, y){
            mHoverWin_.setPosition(x, y);
        }

        function setItem(item){
            mTitleLabel_.setText(item.getName());
            local descText = item.getDescription();

            mDescriptionLabel_.setText(descText);

            local stats = item.toStats();
            local richTextDesc = stats.getDescriptionWithRichText();
            mStatsLabel_.setText(richTextDesc[0]);
            mStatsLabel_.setRichText(richTextDesc[1]);

            mHoverWin_.setSize(mHoverWin_.calculateChildrenSize());
        }
    };

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
        _event.subscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent, this);

        local startOffset = 0;
        if(data.rawin("startOffset")){
            startOffset = data.rawget("startOffset");
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

        mInventoryBus_ = InventoryInfoBus();
        mBusCallbackId_ = mInventoryBus_.registerCallback(busCallback, this);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        local disableBackgroundClose = false;
        if(data.rawin("disableBackgroundClose") && data.disableBackgroundClose){
            disableBackgroundClose = true;
        }
        if(mobile && !disableBackgroundClose){
            local inventoryCloseButton = mWindow_.createButton();
            inventoryCloseButton.setSize(mWindow_.getSize());
            inventoryCloseButton.setVisualsEnabled(false);
            inventoryCloseButton.attachListenerForEvent(function(widget, action){
                closeInventory();
            }, _GUI_ACTION_PRESSED, this);
        }

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
            inventoryButton.setPosition(Vec2(10, 10 + startOffset));
            inventoryButton.attachListenerForEvent(function(widget, action){
                closeInventory();
            }, _GUI_ACTION_PRESSED, this);
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

        local buttonCover = createButtonCover(mOverlayWindow_);
        mHoverInfo_ = HoverItemInfo(mOverlayWindow_);

        //Add one for the equippables slot and another for general padding.
        local gridSize = calculateGridSize();

            mPlayerInspector_ = ::GuiWidgets.InventoryPlayerInspector();
            mPlayerInspector_.setup(mWindow_);

        local layoutHorizontal = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, mHoverInfo_, buttonCover);
        local inventoryHeight = mInventory_.getInventorySize() / mInventoryWidth;
        mInventoryGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, mInventoryWidth, inventoryHeight);
        //mInventoryGrid_.addToLayout(layoutLine);
        mInventoryGrid_.addToLayout(layoutHorizontal);

        mInventoryEquippedGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_EQUIPPABLES, mInventoryBus_, mHoverInfo_, buttonCover);
        mInventoryEquippedGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, null, null);
        //mInventoryEquippedGrid_.addToLayout(layoutLine);
        //mInventoryEquippedGrid_.addToLayout(layoutHorizontal);

        if(mUseSecondaryGrid_){
            mSecondaryInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID_SECONDARY, mInventoryBus_, mHoverInfo_, buttonCover);
            mSecondaryInventoryGrid_.initialise(mWindow_, gridSize, mOverlayWindow_, mSecondaryWidth_, mSecondaryHeight_);
            //mSecondaryInventoryGrid_.addToLayout(layoutLine);
            mSecondaryInventoryGrid_.addToLayout(layoutHorizontal);
        }

        mInventoryGrid_.connectNeighbours(mInventoryEquippedGrid_, inventoryButton);
        if(mSecondaryInventoryGrid_ != null){
            mInventoryEquippedGrid_.connectNeighbours([mInventoryGrid_, mSecondaryInventoryGrid_], inventoryButton);
            mSecondaryInventoryGrid_.connectNeighbours(mInventoryEquippedGrid_, inventoryButton);
        }else{
            mInventoryEquippedGrid_.connectNeighbours(mInventoryGrid_, inventoryButton);
        }

        if(inventoryButton){
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
        local startPos = 0;
        if(inventoryButton){
            startPos = inventoryButton.getPosition().y + inventoryButton.getSize().y;
        }
        layoutLine.setPosition(::drawable.x * 0.05, startPos);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.setHardMaxSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.layout();

        mInventoryGrid_.notifyLayout();
        mInventoryGrid_.setNewGridIcons(mInventory_.mInventoryItems_);
        mInventoryEquippedGrid_.setNewGridIcons(mPlayerStats_.mPlayerCombatStats.mEquippedItems.mItems);
        if(mUseSecondaryGrid_){
            mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
        }

        local inspectorSize = mPlayerInspector_.getSize();
        //inspectorSize.x = mInventoryGrid_.getSize().x
        inspectorSize.x = ::drawable.x * 0.9;
        mPlayerInspector_.setSize(inspectorSize);
        //container.sizeInner();
        //if(!mobile){
            repositionEquippablesGrid();

            inspectorSize.y = mInventoryEquippedGrid_.getSize().y;
            mPlayerInspector_.setSize(inspectorSize);
            mPlayerInspector_.notifyLayout();
        //}

        local gridStart = mPlayerInspector_.getPosition() + mPlayerInspector_.getSize();
        gridStart.x = ::drawable.x * 0.05;
        mInventoryGrid_.setPosition(gridStart);
    }

    function repositionEquippablesGrid(){
        mInventoryEquippedGrid_.setPosition(mPlayerInspector_.getPosition());
        local widgetSize = mInventoryEquippedGrid_.getWidgetSize();
        //mInventoryEquippedGrid_.setSize(mInventoryEquippedGrid_.calculateChildrenSize());
        //mInventoryEquippedGrid_.setSize(::drawable);
        //local rightPos = mPlayerInspector_.getModelExtentRight();
        //local leftPos = mPlayerInspector_.getModelExtentLeft();
        local leftPos = Vec2();
        local rightPos = mPlayerInspector_.getSize();
        rightPos.x -= widgetSize.x;
        //leftPos.x -= widgetSize.x;
        for(local i = 0; i < EquippedSlotTypes.MAX-1; i++){
            local target = (i < 4 ? leftPos : rightPos).copy();
            target.y = 0;
            target.y += (i % 4) * widgetSize.y;
            mInventoryEquippedGrid_.setPositionForIdx(i, target);
        }
        //mInventoryEquippedGrid_.setSize(mInventoryEquippedGrid_.calculateChildrenSize());
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
            selectItem(data);
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_BEGAN){
            processItemHover(data);
        }
        else if(event == InventoryBusEvents.ITEM_HOVER_ENDED){
            processItemHover(null);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_USE){
            if(data.gridType == InventoryGridType.INVENTORY_GRID){
                local itemForIdx = mInventory_.getItemForIdx(data.idx);
                ::ItemHelper.actuateItem(itemForIdx);
                mInventory_.removeFromInventory(data.idx);
            }else if(data.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                local item = mSecondaryItems_[data.idx];
                mSecondaryItems_[data.idx] = null;
                mSecondaryInventoryGrid_.setNewGridIcons(mSecondaryItems_);
                ::ItemHelper.actuateItem(item);
            }
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP){
            scrapItem(data);
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
                item = mInventory_.getItemForIdx(data.idx);
                mInventory_.removeFromInventory(data.idx);
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
                item = mInventory_.getItemForIdx(data.idx);
            }else if(data.gridType == InventoryGridType.INVENTORY_GRID_SECONDARY){
                item = mSecondaryItems_[data.idx];
            }
            if(item == null) return;

            ::Base.mExplorationLogic.readLoreContentForItem(item);
        }
        else if(event == InventoryBusEvents.ITEM_HELPER_SCREEN_ENDED){
            highlightPrevious();
        }
    }

    function scrapItem(inventoryData){
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
            targetItem = mInventory_.getItemForIdx(idx);
            mInventory_.removeFromInventory(idx);
        }
        printf("Adding scrap value for item: %s", targetItem.tostring());
        local scrapValue = targetItem.getScrapVal();
        mInventory_.addMoney(scrapValue);
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
            selectedItem = mInventory_.getItemForIdx(idx);
            targetGrid = mInventoryGrid_;
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
            "item": selectedItem,
            "idx": idx,
            "gridType": inventoryData.gridType,
            "bus": mInventoryBus_,
            "secondaryGrid": mUseSecondaryGrid_
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
            local item = mInventory_.getItemForIdx(idx);
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
        //base.shutdown();
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent);
        _event.unsubscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent);
    }

    function update(){
        //mInventoryGrid_.update();
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
    }
};

_doFile("res://src/GUI/Widgets/InventoryGrid.nut");
_doFile("res://src/GUI/Widgets/InventoryPlayerInspector.nut");