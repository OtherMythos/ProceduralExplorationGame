//Widget for displaying special moves in a radial layout with configurable parameters
::SpecialMovesRadialWidget <- class{

    //Individual button in the radial widget
    mButtonWidget_ = class{
        static SELECTED_SIZE_BONUS = 14;
        static ANIM_SPEED = 0.2;

        mPanel_ = null;
        mLabel_ = null;
        mBaseSize_ = 0;
        mCurrentSize_ = 0.0;
        mTargetSize_ = 0.0;
        mBasePos_ = null;
        mDisabled_ = false;

        constructor(parent, text, size){
            mBaseSize_ = size;
            mCurrentSize_ = size.tofloat();
            mTargetSize_ = mCurrentSize_;
            mBasePos_ = null;

            mPanel_ = parent.createPanel();
            mPanel_.setSkinPack("Panel_midGrey");
            mPanel_.setSize(size, size);
            mPanel_.setClickable(false);

            mLabel_ = parent.createLabel();
            mLabel_.setText(text);
            mLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
            mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
            mLabel_.setClickable(false);
            mLabel_.setSize(size, size);
        }

        function setPosition(pos){
            mBasePos_ = Vec2(pos.x, pos.y);
            updatePosition_();
        }

        function setDisabled(disabled){
            mDisabled_ = disabled;
            if(disabled){
                mPanel_.setSkinPack("Panel_darkGrey");
                mPanel_.setColour(ColourValue(1, 1, 1, 0.75));
                mLabel_.setVisible(false);
            }
        }

        function setSelected(selected){
            if(mDisabled_) return;
            if(selected){
                mPanel_.setSkinPack("Panel_blue");
                mTargetSize_ = (mBaseSize_ + SELECTED_SIZE_BONUS).tofloat();
            }else{
                mPanel_.setSkinPack("Panel_midGrey");
                mTargetSize_ = mBaseSize_.tofloat();
            }
        }

        function update(){
            mCurrentSize_ += (mTargetSize_ - mCurrentSize_) * ANIM_SPEED;
            mPanel_.setSize(mCurrentSize_, mCurrentSize_);
            updatePosition_();
        }

        function updatePosition_(){
            local offset = (mCurrentSize_ - mBaseSize_) * 0.5;
            mPanel_.setPosition(Vec2(mBasePos_.x - offset, mBasePos_.y - offset));
            mLabel_.setPosition(mBasePos_);
        }

        function getPanel(){
            return mPanel_;
        }

        function getLabel(){
            return mLabel_;
        }

        function setLabelText(text){
            mLabel_.setText(text);
        }

        function attachListener(callback, eventType, environment){
            mPanel_.attachListenerForEvent(callback, eventType, environment);
        }
    };

    //Configuration parameters
    mParentWindow_ = null;
    mContainerPanel_ = null;
    mCentrePos_ = null;
    mRingRadius_ = 110;
    mButtonSize_ = 90;
    mNumButtons_ = 4;
    mStartAngle_ = -PI / 2.0;
    mContainerSize_ = null;

    mBackgroundPanel_ = null;
    mTitle_ = null;
    mInnerPanel_ = null;

    //Button storage
    mButtons_ = null;
    mSpecialMoveIds_ = null;

    constructor(parentWindow, config = null){
        mParentWindow_ = parentWindow;
        mButtons_ = [];
        mSpecialMoveIds_ = [];

        //Apply configuration parameters if provided
        if(config != null){
            if(config.rawin("radius")){ mRingRadius_ = config.rawget("radius"); }
            if(config.rawin("buttonSize")){ mButtonSize_ = config.rawget("buttonSize"); }
            if(config.rawin("numButtons")){ mNumButtons_ = config.rawget("numButtons"); }
            if(config.rawin("startAngle")){ mStartAngle_ = config.rawget("startAngle"); }
            if(config.rawin("containerSize")){ mContainerSize_ = config.rawget("containerSize"); }
            if(config.rawin("centrePos")){ mCentrePos_ = config.rawget("centrePos"); }
        }

        //Create container panel
        if(mContainerSize_ == null){
            mContainerSize_ = Vec2(mRingRadius_ * 2.5, mRingRadius_ * 2.5);
        }
        mContainerPanel_ = mParentWindow_.createPanel();
        mContainerPanel_.setSize(parentWindow.getSizeAfterClipping().x, 200);
        mContainerPanel_.setClipBorders(0, 0, 0, 0);
        mContainerPanel_.setSkinPack("Panel_midGrey");

        //Centre position relative to container
        //mCentrePos_ = Vec2(mContainerSize_.x / 2.0, mContainerSize_.y / 2.0);

        //Subscribe to special move selection event
        _event.subscribe(Event.SPECIAL_MOVE_SELECTED, onSpecialMoveSelected, this);
    }

    function setup(specialMovesList = null){
        mBackgroundPanel_ = mParentWindow_.createPanel();
        mBackgroundPanel_.setSize(mParentWindow_.getSizeAfterClipping().x, 200);
        mBackgroundPanel_.setSkinPack("Panel_darkGrey");

        local innerPadding = 10;

        mTitle_ = mParentWindow_.createLabel();
        mTitle_.setDefaultFontSize(mTitle_.getDefaultFontSize() * 1.1);
        mTitle_.setText("Special Moves");
        mTitle_.setPosition(innerPadding, 0);

        local yPos = 0;
        yPos += mTitle_.getSize().y;

        mInnerPanel_ = mParentWindow_.createPanel();
        local backgroundSize = mBackgroundPanel_.getSize();
        mInnerPanel_.setSize(backgroundSize.x - innerPadding * 2, backgroundSize.y - yPos - innerPadding);
        mInnerPanel_.setPosition(innerPadding, yPos);
        mInnerPanel_.setSkinPack("Panel_lightGrey");

        createButtons_(specialMovesList);
        positionButtons_(yPos + innerPadding);
        resizeInnerPanelToFitButtons_(innerPadding);
        resizeBackgroundPanelToFitContent_(innerPadding);
    }

    function createButtons_(specialMovesList){
        mButtons_.clear();
        mSpecialMoveIds_.clear();

        for(local i = 0; i < mNumButtons_; i++){
            local moveId = (i < specialMovesList.len()) ? specialMovesList[i] : SpecialMoveId.NONE;
            local moveDef = ::SpecialMoves[moveId];
            local label = (moveDef != null) ? moveDef.getName() : "None";

            local button = mButtonWidget_(mParentWindow_, label, mButtonSize_);
            mButtons_.append(button);
            mSpecialMoveIds_.append(moveId);

            if(moveId == SpecialMoveId.NONE){
                button.setDisabled(true);
            }else{
                //Make the button clickable and attach listener to open selection screen
                local buttonPanel = button.getPanel();
                buttonPanel.setClickable(true);

                local self = this;
                local slotId = i;
                local callback = function(widget, action){
                    //Open the special moves list screen with this slot index
                    ::ScreenManager.queueTransition(
                        Screen.SPECIAL_MOVES_LIST_SCREEN,
                        {"slotId": slotId},
                        1
                    );
                };

                button.attachListener(callback, _GUI_ACTION_PRESSED, this);
            }
        }
    }

    function positionButtons_(yOffset){
        local angleStep = (PI * 2.0) / mNumButtons_;

        local buttonPos = yOffset + mButtonSize_ / 2 + mRingRadius_;

        for(local i = 0; i < mNumButtons_; i++){
            local angle = mStartAngle_ + angleStep * i;
            local bx = mCentrePos_.x + cos(angle) * mRingRadius_ - mButtonSize_ / 2.0;
            local by = buttonPos + sin(angle) * mRingRadius_ - mButtonSize_ / 2.0;
            mButtons_[i].setPosition(Vec2(bx, by));
        }
    }

    function resizeInnerPanelToFitButtons_(innerPadding){
        local panelPos = mInnerPanel_.getPosition();
        local maxButtonY = panelPos.y;

        //Find the lowest button position
        foreach(button in mButtons_){
            local buttonPanel = button.getPanel();
            local buttonBottomY = buttonPanel.getDerivedPosition().y + buttonPanel.getSize().y;
            if(buttonBottomY > maxButtonY){
                maxButtonY = buttonBottomY;
            }
        }

        //Resize inner panel to fit all buttons with padding
        local newHeight = maxButtonY - panelPos.y + innerPadding;
        mInnerPanel_.setSize(mInnerPanel_.getSize().x, newHeight);
    }

    function resizeBackgroundPanelToFitContent_(margin){
        local innerPanelPos = mInnerPanel_.getPosition();
        local innerPanelSize = mInnerPanel_.getSize();
        local backgroundHeight = innerPanelPos.y + innerPanelSize.y + margin;
        mBackgroundPanel_.setSize(mBackgroundPanel_.getSize().x, backgroundHeight);
    }

    //Mark a button as disabled (greys it out)
    function setButtonDisabled(index, disabled){
        if(index >= 0 && index < mButtons_.len()){
            mButtons_[index].setDisabled(disabled);
        }
    }

    //Set selection state for a button
    function setButtonSelected(index, selected){
        if(index >= 0 && index < mButtons_.len()){
            mButtons_[index].setSelected(selected);
        }
    }

    //Get a button widget by index
    function getButton(index){
        if(index >= 0 && index < mButtons_.len()){
            return mButtons_[index];
        }
        return null;
    }

    //Get the underlying GUI panel for a button
    function getButtonPanel(index){
        local button = getButton(index);
        if(button != null){
            return button.getPanel();
        }
        return null;
    }

    //Update animations for all buttons
    function update(){
        foreach(button in mButtons_){
            button.update();
        }
    }

    //Reposition buttons (call if centre position or radius changes)
    function updateLayout(){
        positionButtons_();
    }

    //Set the centre position of the radial layout
    function setCentrePos(pos){
        mCentrePos_ = Vec2(pos.x, pos.y);
        updateLayout();
    }

    //Set the radius of the radial layout
    function setRadius(radius){
        mRingRadius_ = radius;
        updateLayout();
    }

    //Get the number of buttons
    function getNumButtons(){
        return mNumButtons_;
    }

    //Get the container panel
    function getContainerPanel(){
        return mContainerPanel_;
    }

    //Set the position of the widget container
    function setPosition(pos){
        mContainerPanel_.setPosition(pos.x, pos.y);
    }

    //Get the size of the widget
    function getSize(){
        return mContainerSize_;
    }

    //Cleanup
    function shutdown(){
        mButtons_.clear();
        mSpecialMoveIds_.clear();
        _event.unsubscribe(Event.SPECIAL_MOVE_SELECTED, onSpecialMoveSelected, this);
    }

    function onSpecialMoveSelected(id, data){
        if(data == null) return;

        local slotId = data.rawin("slotId") ? data.rawget("slotId") : -1;
        local moveId = data.rawin("moveId") ? data.rawget("moveId") : SpecialMoveId.NONE;

        if(slotId < 0 || slotId >= mSpecialMoveIds_.len()) return;

        //Update the player stats
        ::Base.mPlayerStats.setSpecialMove(slotId, moveId);

        //Update the button label
        mSpecialMoveIds_[slotId] = moveId;
        local moveDef = ::SpecialMoves[moveId];
        local newLabel = (moveDef != null) ? moveDef.getName() : "None";
        mButtons_[slotId].setLabelText(newLabel);

        //Update disabled state
        if(moveId == SpecialMoveId.NONE){
            mButtons_[slotId].setDisabled(true);
        }else{
            mButtons_[slotId].setDisabled(false);
        }
    }
};
