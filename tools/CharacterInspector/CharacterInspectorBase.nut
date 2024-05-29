enum CharacterInspectorWidgetTypes{
    MODEL_TYPE,

    EQUIP_LEFT_HAND,
    EQUIP_RIGHT_HAND,
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
    mId_ = 0;
    constructor(callback, id, current, win, label, labelFunction, start, end){
        mCallback_ = callback;
        mCurrentVal_ = current;
        mLabelFunction_ = labelFunction;
        mStart_ = start;
        mEnd_ = end;
        mId_ = id;

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
        local label = mLabelFunction_(mCurrentVal_);
        mButton_.setText(label);
    }
    function notifyNewSelection(selection){
        mCurrentVal_ = selection;
        updateButtonLabel();
        mCallback_(mId_, selection);
    }

    function getId(){
        return mId_;
    }
}

::CharacterInspectorBase <- class{
    mGenerator_ = null;
    mInspectedModel_ = null;

    mNode_ = null;

    mCurrentData_ = null;

    constructor(){
        fpsCamera.start(Vec3(10, 10, 20), Vec3(245.45, -15.9, 0));

        mCurrentData_ = obtainCurrentData();

        createGui();

        mGenerator_ = CharacterGenerator();

        reCreateEntity();
    }

    function update(){
        fpsCamera.update();
    }

    function obtainCurrentData(){
        local outData = null;

        local resolvedPath = getSettingsPath();
        if(_system.exists(resolvedPath)){
            local saveTable = null;
            try{
                saveTable = _system.readJSONAsTable(resolvedPath);
            }catch(e){
                print(e);
            }
            outData = saveTable;
            print(_prettyPrint(outData));
        }

        if(outData == null){
            outData = {
                "type": CharacterModelType.HUMANOID,
                "equip": array(CharacterModelEquipNodeType.MAX, ItemId.NONE),
                "wieldActive": false
            }
            outData.equip[CharacterModelEquipNodeType.LEFT_HAND] = ItemId.SIMPLE_TWO_HANDED_SWORD;
        }

        return outData;
    }

    function animCheckboxCallback(widget, action){
        if(widget.getValue()){
            mInspectedModel_.startAnimation(widget.getUserId());
        }else{
            mInspectedModel_.stopAnimation(widget.getUserId());
        }
    }

    function toggleWieldActive(widget, action){
        mCurrentData_.wieldActive = widget.getValue();
        printf("Setting wield active to %s", mCurrentData_.wieldActive ? "true" : "false");

        processEquipTypeChange();
    }

    function guiCreateTitle(title, layout){
        local entityDataTitle = ::containerWin.createLabel();
        entityDataTitle.setText(title);
        layout.addCell(entityDataTitle);
    }
    function createGui(){
        ::containerWin <- _gui.createWindow();
        containerWin.setSize(500, _window.getHeight());
        local layout = _gui.createLayoutLine();

        guiCreateTitle("Entity Data", layout);
        local entityTypeButton = ::CharacterInspectorMultiChoicePopupButton(notifyEntityTypeChange.bindenv(this), 0, mCurrentData_.type, ::containerWin, "Model Type", ::ConstHelper.CharacterModelTypeToString, CharacterModelType.NONE, CharacterModelType.MAX);
        entityTypeButton.addToLayout(layout);
        ::CharacterInspectorWidgets[CharacterInspectorWidgetTypes.MODEL_TYPE] <- entityTypeButton;

        guiCreateTitle("Animation", layout);
        for(local i = 1; i < CharacterModelAnimId.MAX; i++){
            local checkbox = ::containerWin.createCheckbox();
            checkbox.attachListenerForEvent(animCheckboxCallback, _GUI_ACTION_RELEASED, this);
            checkbox.setText(::CharacterModelAnims[i].mName);
            checkbox.setUserId(i);

            layout.addCell(checkbox);
            if(i == 1){
                checkbox.setValue(true);
            }
        }
        local labels = [
            "FeetWalk",
            "UpperWalk",
            "Sword swing",
            "Two Hand Sword swing",
            "UpperSwim",
        ];
        foreach(c,i in labels){
        }

        guiCreateTitle("Equipables", layout);
        local equipEntries = [
            "Right Hand",
            "Left Hand"
        ];
        local equipEntriesVals = [
            CharacterInspectorWidgetTypes.EQUIP_RIGHT_HAND,
            CharacterInspectorWidgetTypes.EQUIP_LEFT_HAND,
        ];
        local equipNodeType = [
            CharacterModelEquipNodeType.RIGHT_HAND
            CharacterModelEquipNodeType.LEFT_HAND,
        ];
        foreach(c,i in equipEntries){
            local equipVal = equipEntriesVals[c];
            local equipNodeType = equipNodeType[c];
            local currentEquip = mCurrentData_.equip[equipNodeType];
            local equip = ::CharacterInspectorMultiChoicePopupButton(notifyEquipChange.bindenv(this), equipNodeType, currentEquip, ::containerWin, i, ::ConstHelper.ItemIdToString, ItemId.NONE, ItemId.MAX);
            equip.addToLayout(layout);
            ::CharacterInspectorWidgets[equipVal] <- equip;
        }

        //Wield active state toggle.
        local wieldActiveStateToggle = ::containerWin.createCheckbox();
        wieldActiveStateToggle.attachListenerForEvent(toggleWieldActive, _GUI_ACTION_RELEASED, this);
        wieldActiveStateToggle.setText("Wield active");
        layout.addCell(wieldActiveStateToggle);

        layout.layout();
    }

    function notifyEquipChange(equipType, newEquip){
        mCurrentData_.equip[equipType] = newEquip;
        processEquipTypeChange();
    }

    function notifyEntityTypeChange(id, newType){
        mCurrentData_.type = newType;

        reCreateEntity();
    }

    function processEquipTypeChange(){
        mInspectedModel_.clearEquipNodes();

        local wieldActive = mCurrentData_.wieldActive;
        for(local i = CharacterModelEquipNodeType.NONE+1; i < CharacterModelEquipNodeType.MAX; i++){
            local item = ::Items[mCurrentData_.equip[i]];
            local target = i;
            if(wieldActive){
                if(target == CharacterModelEquipNodeType.LEFT_HAND || target == CharacterModelEquipNodeType.RIGHT_HAND){
                    target = CharacterModelEquipNodeType.WEAPON_STORE;
                }
            }
            mInspectedModel_.equipToNode(item.getType() == ItemId.NONE ? null : item, target, target == CharacterModelEquipNodeType.WEAPON_STORE);
        }
    }

    function reCreateEntity(){
        if(mNode_ != null){
            mNode_.destroyNodeAndChildren();
        }
        mNode_ = _scene.getRootSceneNode().createChildSceneNode();

        local constructionData = {
            "type": mCurrentData_.type
        };
        mInspectedModel_ = mGenerator_.createCharacterModel(mNode_, constructionData);
        try{
            mInspectedModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
        }catch(e){
            print(e);
        }

        processEquipTypeChange();
    }

    function saveCurrentSettings(){
        _system.ensureUserDirectory();

        local resolvedPath = getSettingsPath();
        if(!_system.exists(resolvedPath)){
            _system.createBlankFile(resolvedPath);
        }
        _system.writeJsonAsFile(resolvedPath, mCurrentData_);
    }

    function getSettingsPath(){
        local path = "user://currentSettings.json";
        return _system.resolveResPath(path);
    }
};