::ItemInfoScreen <- class extends ::Screen{

    mWindow_ = null;

    mItemType_ = Item.NONE;

    ItemStatsContainer = class{
        mWindow_ = null;

        constructor(parentWindow, item){
            print("Showing info for item: " + ::Items.itemToName(item));

            mWindow_ = _gui.createWindow(parentWindow);
            mWindow_.setSize(100, 100);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(2);

            local layoutLine = _gui.createLayoutLine();

            local text = mWindow_.createLabel();
            text.setText("Stats:");
            layoutLine.addCell(text);

            local stats = ::Items.itemToStats(item);
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

    constructor(itemType){
        mItemType_ = itemType;
    }

    function setup(){
        local itemName = ::Items.itemToName(mItemType_);
        local itemDescription = ::Items.itemToDescription(mItemType_);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

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

        local statsContainer = ItemStatsContainer(mWindow_, mItemType_);
        statsContainer.addToLayout(layoutLine);

        //Add the buttons to either keep or scrap.
        local buttonOptions = ["Keep", "Scrap"];
        local buttonFunctions = [
            function(widget, action){
                closeScreen();
            },
            function(widget, action){
                closeScreen();
            }
        ];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();
    }

    function closeScreen(){
        ::ScreenManager.transitionToScreen(ExplorationScreen(::Base.mExplorationLogic));
    }
};