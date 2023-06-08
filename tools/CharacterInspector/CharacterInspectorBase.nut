enum CharacterInspectorWidgetTypes{
    MODEL_TYPE
};

::CharacterInspectorWidgets <- {};

::CharacterInspectorMultiChoicePopup <- class{
    mWin_ = null;
    mParent_ = null;
    constructor(parent, title, labelFunc, start, end){
        mParent_ = parent;

        mWin_ = _gui.createWindow();
        mWin_.setPosition(0, 0);
        mWin_.setSize(_window.getWidth(), _window.getHeight());

        local layout = _gui.createLayoutLine();

        local label = mWin_.createLabel();
        label.setText(title);
        layout.addCell(label);

        //Populate with the various entries
        for(local i = start; i < end; i++){
            local button = mWin_.createButton();
            local text = labelFunc(i);
            button.setUserId(i);
            button.attachListenerForEvent(characterInspectorMultiChoicePopupCallback, _GUI_ACTION_PRESSED, this);
            button.setText(text);

            layout.addCell(button);
        }

        layout.layout();
    }
    function characterInspectorMultiChoicePopupCallback(widget, action){
        mParent_.notifyNewSelection(widget.getUserId());
        _gui.destroy(mWin_);
    }
}

::CharacterInspectorMultiChoicePopupButton <- class{
    mCallback_ = null;
    mButton_ = null;
    mLayoutHorizontal_ = null;
    mCurrentVal_ = 0;
    mPopup_ = null;
    mLabel_ = "None";
    mLabelFunction_ = null;
    mStart_ = 0;
    mEnd_ = 0;
    constructor(callback, current, win, label, labelFunction, start, end){
        mCallback_ = callback;
        mCurrentVal_ = current;
        mLabelFunction_ = labelFunction;
        mStart_ = start;
        mEnd_ = end;

        local button = win.createButton();
        button.setText(mLabel_);
        button.attachListenerForEvent(characterInspectorMultiChoicePopupCallback, _GUI_ACTION_PRESSED, this);
        mButton_ = button;

        local layoutHorizontal = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);

        local text = win.createLabel();
        text.setText(label);
        layoutHorizontal.addCell(text);

        layoutHorizontal.addCell(button);
        layoutHorizontal.layout();
        mLayoutHorizontal_ = layoutHorizontal;

        mLabel_ = label;

        updateButtonLabel();
    }
    function addToLayout(layout){
        layout.addCell(mLayoutHorizontal_);
    }
    function getCurrentVal(){
        return mCurrentVal_;
    }


    function characterInspectorMultiChoicePopupCallback(widget, action){
        mPopup_ = ::CharacterInspectorMultiChoicePopup(this, mLabel_, mLabelFunction_, mStart_, mEnd_);

        //updateButtonLabel();
    }
    function updateButtonLabel(){
        local label = ::ConstHelper.CharacterModelTypeToString(mCurrentVal_);
        mButton_.setText(label);
    }
    function notifyNewSelection(selection){
        mCurrentVal_ = selection;
        updateButtonLabel();
        mCallback_(selection);
    }
}

::CharacterInspectorBase <- class{
    mGenerator_ = null;
    mInspectedModel_ = null;

    mConstructionData_ = null;
    mNode_ = null;

    constructor(){
        fpsCamera.start(Vec3(10, 10, 20), Vec3(245.45, -15.9, 0));

        mConstructionData_ = {
            "type": CharacterModelType.HUMANOID
        };

        createGui();

        mGenerator_ = CharacterGenerator();

        reCreateEntity();
    }

    function update(){
        fpsCamera.update();
    }


    function animCheckboxCallback(widget, action){
        local testVals = [
            CharacterModelAnimId.BASE_LEGS_WALK,
            CharacterModelAnimId.BASE_ARMS_WALK,
            CharacterModelAnimId.REGULAR_SWORD_SWING,
        ];
        if(widget.getValue()){
            mInspectedModel_.startAnimation(testVals[widget.getUserId()]);
        }else{
            mInspectedModel_.stopAnimation(testVals[widget.getUserId()]);
        }
    }
    function equipCheckboxCallback(widget, action){
        if(widget.getValue()){
            local item = ::Items[ItemId.SIMPLE_SWORD];
            mInspectedModel_.equipToNode(item, CharacterModelEquipNodeType.LEFT_HAND);
        }else{
            mInspectedModel_.equipToNode(null, CharacterModelEquipNodeType.LEFT_HAND);
        }
    }

    function guiCreateTitle(title, layout){
        local entityDataTitle = ::containerWin.createLabel();
        entityDataTitle.setText(title);
        layout.addCell(entityDataTitle);
    }
    function createGui(){
        ::containerWin <- _gui.createWindow();
        containerWin.setSize(500, 500);
        local layout = _gui.createLayoutLine();

        guiCreateTitle("Entity Data", layout);
        local entityTypeButton = ::CharacterInspectorMultiChoicePopupButton(notifyEntityTypeChange.bindenv(this), CharacterModelType.HUMANOID, ::containerWin, "Model Type", ::ConstHelper.CharacterModelTypeToString, CharacterModelType.NONE, CharacterModelType.MAX);
        entityTypeButton.addToLayout(layout);
        ::CharacterInspectorWidgets[CharacterInspectorWidgetTypes.MODEL_TYPE] <- entityTypeButton;

        guiCreateTitle("Animation", layout);
        local labels = [
            "FeetWalk",
            "UpperWalk",
            "Sword swing"
        ];
        foreach(c,i in labels){
            local checkbox = ::containerWin.createCheckbox();
            checkbox.attachListenerForEvent(animCheckboxCallback, _GUI_ACTION_RELEASED, this);
            checkbox.setText(i);
            checkbox.setUserId(c);

            layout.addCell(checkbox);
            if(c == 0){
                checkbox.setValue(true);
            }
        }

        guiCreateTitle("Equipables", layout);
        labels = [
            "equipSword"
        ];
        foreach(c,i in labels){
            local checkbox = ::containerWin.createCheckbox();
            checkbox.attachListenerForEvent(equipCheckboxCallback, _GUI_ACTION_RELEASED, this);
            checkbox.setText(i);
            checkbox.setUserId(c);

            layout.addCell(checkbox);
        }


        layout.layout();
    }

    function notifyEntityTypeChange(newType){
        mConstructionData_.type = newType;

        reCreateEntity();
    }

    function reCreateEntity(){
        if(mNode_ != null){
            mNode_.destroyNodeAndChildren();
        }
        mNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mInspectedModel_ = mGenerator_.createCharacterModel(mNode_, mConstructionData_);
        try{
            mInspectedModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
        }catch(e){
            print(e);
        }
    }
};