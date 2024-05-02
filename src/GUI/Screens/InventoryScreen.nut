enum InventoryBusEvents{
    ITEM_HOVER_BEGAN,
    ITEM_HOVER_ENDED,
    ITEM_SELECTED,

    ITEM_INFO_REQUEST_EQUIP,
    ITEM_INFO_REQUEST_EQUIP_LEFT_HAND,
    ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND,
    ITEM_INFO_REQUEST_UNEQUIP,
    ITEM_INFO_REQUEST_USE,
    ITEM_INFO_REQUEST_SCRAP,
};

::ScreenManager.Screens[Screen.INVENTORY_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mOverlayWindow_ = null;
    mInventoryGrid_ = null;
    mInventoryEquippedGrid_ = null;
    mHoverInfo_ = null;
    mInventory_ = null;
    mMoneyCounter_ = null;
    mPlayerStats_ = null;
    mPlayerInspector_ = null;

    mInventoryBus_ = null;

    HoverItemInfo = class{
        mHoverWin_ = null;

        mTitleLabel_ = null;
        mDescriptionLabel_ = null;
        mStatsLabel_ = null;

        mActive_ = false;

        constructor(overlayWindow){
            mHoverWin_ = overlayWindow.createWindow("InventoryOverlayWindow");
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
        mInventoryEquippedGrid_.setNewGridIcons(data.mItems);
    }

    function setup(data){
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        _event.subscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent, this);

        if( !(data.rawin("disableBackground") && data.disableBackground) ){
            createBackgroundScreen_();
        }

        mPlayerStats_ = data.stats;
        mInventory_ = mPlayerStats_.mInventory_;

        mInventoryBus_ = InventoryInfoBus();
        mInventoryBus_.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow("InventoryScreen");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        {
            local inventoryButton = mWindow_.createButton();
            inventoryButton.setText("Back");
            inventoryButton.setPosition(5, 25);
            inventoryButton.attachListenerForEvent(function(widget, action){
                closeInventory();
            }, _GUI_ACTION_PRESSED, this);
        }

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Inventory", false);
        title.sizeToFit(::drawable.x * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        mMoneyCounter_.addToLayout(layoutLine);

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

        local layoutHorizontal = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mInventoryGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_GRID, mInventoryBus_, mHoverInfo_, buttonCover);
        //local inventoryWidth = mInventory_.getInventorySize() / 5;
        local inventoryWidth = 5;
        local inventoryHeight = mInventory_.getInventorySize() / inventoryWidth;
        mInventoryGrid_.initialise(mWindow_, mOverlayWindow_, inventoryWidth, inventoryHeight);
        //mInventoryGrid_.addToLayout(layoutLine);
        mInventoryGrid_.addToLayout(layoutHorizontal);

        mInventoryEquippedGrid_ = ::GuiWidgets.InventoryGrid(InventoryGridType.INVENTORY_EQUIPPABLES, mInventoryBus_, mHoverInfo_, buttonCover);
        mInventoryEquippedGrid_.initialise(mWindow_, mOverlayWindow_, null, null);
        //mInventoryEquippedGrid_.addToLayout(layoutLine);
        mInventoryEquippedGrid_.addToLayout(layoutHorizontal);

        mPlayerInspector_ = ::GuiWidgets.InventoryPlayerInspector();
        mPlayerInspector_.setup(mWindow_);
        mPlayerInspector_.addToLayout(layoutHorizontal);

        layoutHorizontal.setMarginForAllCells(10, 0);
        layoutLine.addCell(layoutHorizontal);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(::drawable.x * 0.05, 50);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.setHardMaxSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.layout();

        mInventoryGrid_.notifyLayout();
        mInventoryGrid_.setNewGridIcons(mInventory_.mInventoryItems_);
        mInventoryEquippedGrid_.setNewGridIcons(mPlayerStats_.mPlayerCombatStats.mEquippedItems.mItems);
        //container.sizeInner();
        mPlayerInspector_.notifyLayout();

        ::InputManager.setActionSet(InputActionSets.MENU);
    }

    function createButtonCover(win){
        local cover = win.createPanel();
        local gridSize = ::ScreenManager.calculateRatio(64);
        cover.setSize(gridSize, gridSize);
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
            local itemForIdx = mInventory_.getItemForIdx(data);
            ::ItemHelper.actuateItem(itemForIdx);
            mInventory_.removeFromInventory(data);
        }
        else if(event == InventoryBusEvents.ITEM_INFO_REQUEST_SCRAP){
            scrapItem(data);
        }
        else if(
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP ||
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_LEFT_HAND ||
            event == InventoryBusEvents.ITEM_INFO_REQUEST_EQUIP_RIGHT_HAND)
        {
            local item = mInventory_.getItemForIdx(data);
            assert(item != null);
            mInventory_.removeFromInventory(data);

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
    }

    function scrapItem(inventoryData){
        local targetItem = null;
        local idx = inventoryData.idx;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            targetItem = mPlayerStats_.getEquippedItem(idx+1);
            mPlayerStats_.unEquipItem(idx+1);
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
        }else{
            selectedItem = mInventory_.getItemForIdx(idx);
            targetGrid = mInventoryGrid_;
        }
        if(selectedItem == null) return;
        print("Selected item " + selectedItem.tostring());
        setHoverMenuToItem(null);

        local size = targetGrid.getSize();
        local pos = targetGrid.getPosition();
        local posForIdx = targetGrid.getPositionForIdx(idx);
        local data = {
            "pos": Vec2(posForIdx.x + ::ScreenManager.calculateRatio(64), posForIdx.y),
            "size": Vec2(::ScreenManager.calculateRatio(200), size.y),
            "item": selectedItem,
            "idx": idx,
            "gridType": inventoryData.gridType
            "bus": mInventoryBus_
        };
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_ITEM_HELPER_SCREEN, data), null, mLayerIdx+1);
    }

    function processItemHover(inventoryData){
        if(inventoryData == null){
            setHoverMenuToItem(null);
            return;
        }
        local idx = inventoryData.id;
        if(inventoryData.gridType == InventoryGridType.INVENTORY_EQUIPPABLES){
            //Skip the NONE object.
            local item = mPlayerStats_.getEquippedItem(idx+1);
            setHoverMenuToItem(item);
        }else{
            local item = mInventory_.getItemForIdx(idx);
            setHoverMenuToItem(item);
        }
    }
    function setHoverMenuToItem(item){
        //TODO this might be getting called twice.
        //print(item);
        if(item == null){
            mHoverInfo_.setVisible(false);
            return;
        }
        mHoverInfo_.setItem(item);
        mHoverInfo_.setVisible(true);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mOverlayWindow_.setZOrder(idx+1);
    }

    function shutdown(){
        _gui.destroy(mOverlayWindow_);
        mMoneyCounter_.shutdown();
        mPlayerInspector_.shutdown();
        base.shutdown();
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent);
        _event.unsubscribe(Event.PLAYER_EQUIP_CHANGED, receivePlayerEquipChangedEvent);

        ::InputManager.setActionSet(InputActionSets.EXPLORATION);
    }

    function update(){
        //mInventoryGrid_.update();
        mHoverInfo_.update();
        mPlayerInspector_.update();

        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            closeInventory();
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