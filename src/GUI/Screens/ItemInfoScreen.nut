::ScreenManager.Screens[Screen.ITEM_INFO_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mInfoMode_ = null;

    mItem_ = null;
    mItemSlotIdx_ = 0;

    ItemStatsContainer = class{
        mWindow_ = null;

        constructor(parentWindow, item){
            print("Showing info for item: " + item.getName());

            mWindow_ = _gui.createWindow("ItemStatsContainer", parentWindow);
            mWindow_.setSize(100, 100);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(2);

            local layoutLine = _gui.createLayoutLine();

            local text = mWindow_.createLabel();
            text.setText("Stats:");
            layoutLine.addCell(text);

            local stats = item.toStats();
            for(local i = 0; i < StatType.MAX; i++){
                if(!stats.hasStatType(i)) continue;
                addStatLabel(i, stats, mWindow_, layoutLine);
            }

            layoutLine.layout();
        }

        function addStatLabel(statType, stats, parentWin, layout){
            local text = mWindow_.createLabel();
            text.setText(stats.getDescriptionForStat(statType));
            layout.addCell(text);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
        }
    };

    function setup(data){
        mInfoMode_ = data.mode;
        mItem_ = data.item;
        mItemSlotIdx_ = data.slotIdx;

        local itemName = mItem_.getName();
        local itemDescription = mItem_.getDescription();

        mWindow_ = _gui.createWindow("ItemInfoScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText(itemName, false);
        title.sizeToFit(_window.getWidth() * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        local description = mWindow_.createLabel();
        description.setText(itemDescription, false);
        description.sizeToFit(_window.getWidth() * 0.9);
        description.setExpandHorizontal(true);
        layoutLine.addCell(description);

        local statsContainer = ItemStatsContainer(mWindow_, mItem_);
        statsContainer.addToLayout(layoutLine);

        local buttonData = getButtonsForType(mInfoMode_);
        foreach(i,c in buttonData[0]){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonData[1][i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();
    }

    function getButtonsForType(buttonType){
        local buttonOptions = null;
        local buttonFunctions = null;

        if(mInfoMode_ == ItemInfoMode.KEEP_SCRAP_EXPLORATION){
            buttonOptions = ["Keep", "Scrap"];
            buttonFunctions = [
                function(widget, action){
                    ::Base.mPlayerStats.addToInventory(mItem_);
                    //TODO would be nice to do these with events.
                    if(mItemSlotIdx_ >= 0) ::Base.mExplorationLogic.removeFoundItem(mItemSlotIdx_);
                    closeScreen();
                },
                function(widget, action){
                    ::Base.mPlayerStats.mInventory_.addMoney(mItem_.getScrapVal());
                    if(mItemSlotIdx_ >= 0) ::Base.mExplorationLogic.removeFoundItem(mItemSlotIdx_);
                    closeScreen();
                }
            ];
        }
        else if(mInfoMode_ == ItemInfoMode.KEEP_SCRAP_SPOILS){
            buttonOptions = ["Keep", "Scrap"];
            buttonFunctions = [
                function(widget, action){
                    ::Base.mCombatLogic.claimSpoil(mItemSlotIdx_);
                    closeScreen();
                },
                function(widget, action){
                    ::Base.mCombatLogic.scrapSpoil(mItemSlotIdx_);
                    closeScreen();
                }
            ];
        }
        else if(mInfoMode_ == ItemInfoMode.USE){
            buttonOptions = ["Use"];
            buttonFunctions = [
                function(widget, action){
                    ::Base.mPlayerStats.mInventory_.removeFromInventory(mItemSlotIdx_, mItem_);
                    ::ItemHelper.actuateItem(mItem_);
                    closeScreen();
                }
            ];
        }
        else{
            assert(false);
        }

        //Include the back button in either option.
        buttonOptions.append("Back");
        buttonFunctions.append(
            function(widget, action){
                closeScreen();
            }
        );

        return [buttonOptions, buttonFunctions];
    }

    function closeScreen(){
        ::ScreenManager.backupScreen(mLayerIdx);
    }
};