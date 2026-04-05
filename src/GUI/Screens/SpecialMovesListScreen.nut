//Screen for selecting a special move from a list

local SpecialMoveListItemButton = class{
    mBackgroundPanel_ = null;
    mLeftPanel_ = null;
    mNameLabel_ = null;
    mDescriptionLabel_ = null;
    mSize_ = null;
    mDisabled_ = false;
    mMaxTextWidth_ = null;

    static TEXT_OFFSET_X = 98;
    static LEFT_PANEL_SIZE = 90;

    constructor(parentWindow, name, description = null, maxWidth = null){
        //Background panel for full-width clickability (invisible)
        mBackgroundPanel_ = parentWindow.createButton();
        mBackgroundPanel_.setVisualsEnabled(false);

        //Left panel for visual representation
        mLeftPanel_ = parentWindow.createPanel();
        mLeftPanel_.setSkinPack("Button_midGrey");
        mLeftPanel_.setColour(ColourValue(1, 1, 1, 0.95));
        mLeftPanel_.setClickable(false);

        mNameLabel_ = parentWindow.createLabel();
        mNameLabel_.setText(name);
        mNameLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_LEFT);
        mNameLabel_.setClickable(false);

        mDescriptionLabel_ = parentWindow.createLabel();
        if(description != null){
            mDescriptionLabel_.setDefaultFont(6);
            mDescriptionLabel_.setText(description);
            mDescriptionLabel_.setDefaultFontSize(mDescriptionLabel_.getDefaultFontSize() * 0.8);
        }
        mDescriptionLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_LEFT);
        mDescriptionLabel_.setClickable(false);

        mMaxTextWidth_ = maxWidth;
    }

    function attachListenerForEvent(callback, eventType, environment){
        mBackgroundPanel_.attachListenerForEvent(callback, eventType, environment);
    }

    function setPosition(x, y){
        mBackgroundPanel_.setPosition(x, y);
        mLeftPanel_.setPosition(x, y);
        updateLabelPosition_();
    }

    function setSize(width, height){
        mBackgroundPanel_.setSize(width, height);
        mLeftPanel_.setSize(LEFT_PANEL_SIZE, height);
        mSize_ = mBackgroundPanel_.getSize();
        updateLabelPosition_();
    }

    function updateLabelPosition_(){
        local panelPos = mBackgroundPanel_.getPosition();
        local textX = panelPos.x + TEXT_OFFSET_X;
        local textY = panelPos.y;

        //Calculate available width for text
        local availableWidth = mMaxTextWidth_;
        if(availableWidth != null){
            mNameLabel_.sizeToFit(availableWidth);
            mDescriptionLabel_.sizeToFit(availableWidth);
        }

        mNameLabel_.setPosition(textX, textY);

        local nameSize = mNameLabel_.getSize();
        mDescriptionLabel_.setPosition(textX, textY + nameSize.y - 4);
    }

    function setDisabled(disabled){
        mDisabled_ = disabled;
        if(disabled){
            mLeftPanel_.setSkinPack("Button_darkGrey");
            mLeftPanel_.setColour(ColourValue(1, 1, 1, 0.75));
            mNameLabel_.setVisible(false);
            mDescriptionLabel_.setVisible(false);
        }else{
            mLeftPanel_.setSkinPack("Button_midGrey");
            mLeftPanel_.setColour(ColourValue(1, 1, 1, 0.95));
            mNameLabel_.setVisible(true);
            mDescriptionLabel_.setVisible(true);
        }
    }

    function setSelected(selected){
        //Selection logic removed for mobile
    }

    function getPanel(){
        return mBackgroundPanel_;
    }

    function getSize(){
        if(mSize_ == null){
            mSize_ = mBackgroundPanel_.getSize();
        }
        return mSize_;
    }


};

::ScreenManager.Screens[Screen.SPECIAL_MOVES_LIST_SCREEN] = class extends ::Screen{

    static BUTTON_HEIGHT = 90;
    static BUTTON_PADDING = 8;
    static WINDOW_PADDING = 16;

    mScrollWindow_ = null;
    mButtonList_ = null;
    mOnSelectionCallback_ = null;
    mActionSetId_ = null;

    function setup(data){
        if(data != null){
            if(data.rawin("onSelection")){
                mOnSelectionCallback_ = data.rawget("onSelection");
            }
        }
        recreate();
    }

    function recreate(){
        mWindow_ = _gui.createWindow("SpecialMovesListScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mButtonList_ = [];

        createBackgroundScreen_();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 1.3);
        title.setText("Select Special Move");
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setPosition(WINDOW_PADDING, WINDOW_PADDING);

        //Create a scrollable panel for the move buttons
        mScrollWindow_ = mWindow_.createWindow("SpecialMovesList");
        local windowHeight = _window.getHeight() - (WINDOW_PADDING * 3) - title.getSize().y;
        mScrollWindow_.setSize(
            _window.getWidth() - (WINDOW_PADDING * 2),
            windowHeight
        );
        mScrollWindow_.setPosition(WINDOW_PADDING, WINDOW_PADDING * 2 + title.getSize().y);
        mScrollWindow_.setVisualsEnabled(true);
        mScrollWindow_.setSkinPack("Panel_lightGrey");
        mScrollWindow_.setClipBorders(0, 0, 0, 0);

        createMoveButtons_();
        layoutButtons_();

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
    }

    function createMoveButtons_(){
        mButtonList_.clear();

        local allSpecialMoves = ::SpecialMoves;

        //Calculate max width for text based on scroll window size
        local scrollWindowWidth = mScrollWindow_.getSize().x;
        local maxTextWidth = scrollWindowWidth - SpecialMoveListItemButton.TEXT_OFFSET_X - (BUTTON_PADDING * 2);

        for(local i = 0; i < allSpecialMoves.len(); i++){
            local moveDef = allSpecialMoves[i];
            if(moveDef == null) continue;
            if(i == SpecialMoveId.NONE) continue;

            local moveId = i;
            local label = moveDef.getName();
            local description = moveDef.getDescription();
            local button = SpecialMoveListItemButton(mScrollWindow_, label, description, maxTextWidth);
            button.setSize(scrollWindowWidth - (BUTTON_PADDING * 2), BUTTON_HEIGHT);

            //Create callback that captures moveId
            local self = this;
            local callback = function(widget, action){
                if(self.mOnSelectionCallback_){
                    self.mOnSelectionCallback_(moveId);
                }
                self.closeScreen();
            };

            button.attachListenerForEvent(
                callback,
                _GUI_ACTION_PRESSED,
                this
            );

            mButtonList_.append(button);
        }
    }

    function layoutButtons_(){
        local yPos = BUTTON_PADDING;

        foreach(button in mButtonList_){
            button.setPosition(BUTTON_PADDING, yPos);
            yPos += BUTTON_HEIGHT + BUTTON_PADDING;
        }
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isForefrontScreen(mLayerIdx)){
                closeScreen();
            }
        }
    }

    function shutdown(){
        base.shutdown();
        if(mActionSetId_ != null){
            ::InputManager.popActionSet(mActionSetId_);
        }
    }

    function closeScreen(){
        ::ScreenManager.queueTransition(null, null, mLayerIdx);
    }
};
