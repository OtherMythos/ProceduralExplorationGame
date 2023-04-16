::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationEnemiesContainer.ExplorationFoundEnemyWidget <- class{

    mParent_ = null;
    mRenderedIcon_ = null;
    mPosition_ = null;
    mSize_ = null;
    mButton_ = null;
    mLabel_ = null;
    mBus_ = null;
    mObject_ = null;
    mTimeBar_ = null;

    mCount_ = 0.0;

    constructor(parentWin, buttonId, bus){
        mParent_ = parentWin;
        mPosition_ = Vec2();
        mSize_ = Vec2(100, 100);
        mBus_ = bus;
        mObject_ = ::FoundObject();

        local button = parentWin.createButton();
        button.setText("Empty");
        button.setHidden(true);
        button.setUserId(buttonId);
        button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
        mButton_ = button;

        mTimeBar_ = ::GuiWidgets.ProgressBar(this.mParent_);
        mTimeBar_.setPercentage(1.0);
        mTimeBar_.setVisible(false);

        local label = parentWin.createLabel();
        label.setText("something");
        label.setHidden(false);
        mLabel_ = label;
    }

    function deactivate(){
        if(mRenderedIcon_ != null){
            mRenderedIcon_.destroy();
            mRenderedIcon_ = null;
        }

        mButton_.setHidden(true);
        mLabel_.setHidden(true);
        mTimeBar_.setVisible(false);

        mObject_ = ::FoundObject();
    }

    function setObject(object){
        if(object == null){
            deactivate();
            return;
        }
        mObject_ = object;

        local renIcon = mRenderedIcon_;
        if(renIcon == null){
            renIcon = ::RenderIconManager.createIcon();
        }
        //local targetMesh = mObject_.getMesh();
        renIcon.setMesh("goblin.mesh");
        renIcon.setPosition(mPosition_);
        renIcon.setSize(mSize_.x, mSize_.y);
        mRenderedIcon_ = renIcon;

        //mButton_.setText(object.toName(), false);
        mButton_.setText(" ");
        mButton_.setVisualsEnabled(false);
        mButton_.setHidden(false);
        //mButton_.setSkinPack(object.getButtonSkinPack());
        mButton_.setZOrder(200);

        mLabel_.setSize(mButton_.getSize());
        //mLabel_.setText(object.toName(), false);
        mLabel_.setText("goblin", false);
        mLabel_.setCentre(mPosition_);
        mLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
    }

    function setCentre(buttonPos){
        mPosition_ = buttonPos;
        setCentre_(mPosition_);
    }

    function setSize(buttonSize){
        mSize_ = buttonSize;
        setSize_(buttonSize);
    }

    function getCentre(){
        return mButton_.getCentre();
    }
    function getSize(){
        return mButton_.getSize();
    }

    function setCentre_(pos){
        mButton_.setCentre(pos);
        if(mRenderedIcon_){
            local newCentre = mButton_.getDerivedCentre();
            local buttonSize = mButton_.getSize();
            newCentre.y -= buttonSize.y * 0.1;
            mRenderedIcon_.setPosition(newCentre + Vec2(0, buttonSize.y * 0.4));
        }
    }
    function setSize_(size){
        if(mRenderedIcon_){
            local newSize = (size / 2) * 0.7;
            mRenderedIcon_.setSize(newSize.x, newSize.y);
        }
        mButton_.setSize(size);
    }

    function updateIconOrientation(){
        if(!mRenderedIcon_) return;
        mCount_ += 0.02;
        mRenderedIcon_.setOrientation(Quat(mCount_, Vec3((sin(mCount_) * 0.1), 1, 0)));
    }

    function buttonPressed(widget, action){
        assert(false);

        local id = widget.getUserId();
        local foundObj = mObject_;
        assert(foundObj != null);
        local value = {
            "type": foundObj.type,
            "slotIdx": id,
            "buttonCentre": widget.getCentre()
        };
        if(foundObj.type == FoundObjectType.ITEM){
            value.item <- foundObj.obj;
        }
        else if(foundObj.type == FoundObjectType.PLACE){
            value.place <- foundObj.obj;
        }else{
            assert(false);
        }

        mBus_.notifyEvent(ExplorationBusEvents.TRIGGER_ITEM, value);
    }

    function shutdown(){
        if(mRenderedIcon_ != null){
            mRenderedIcon_.destroy();
        }
    }

    function notifyStationary(){
        mLabel_.setHidden(false);
        mLabel_.setSize(mButton_.getSize());
        mLabel_.setText("Goblin", false);
        local targetPos = Vec2(mPosition_.x, mPosition_.y);
        targetPos.y += mSize_.y * 0.8;
        mLabel_.setCentre(targetPos);
        //TODO will probably want to get rid of that permanently.
        mTimeBar_.setVisible(false);
        mTimeBar_.setSize(mButton_.getSize().x * 0.8, mTimeBar_.getSize().y);
        mTimeBar_.setCentre(targetPos.x, targetPos.y*0.9);
    }

    function setLifetime(lifetime){
        mTimeBar_.setPercentage(lifetime);
    }

};
