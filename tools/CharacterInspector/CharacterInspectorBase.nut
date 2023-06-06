::CharacterInspectorBase <- class{
    mGenerator_ = null;
    mInspectedModel_ = null;

    constructor(){
        fpsCamera.start(Vec3());

        createGui();

        ::generator <- CharacterGenerator();

        local constructionData = {
            "type": CharacterModelType.GOBLIN
        };

        local targetNode = _scene.getRootSceneNode().createChildSceneNode();
        mInspectedModel_ = ::generator.createCharacterModel(targetNode, constructionData);
        try{
            mInspectedModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
        }catch(e){
            print(e);
        }

        _camera.setPosition(0, 0, 20);
        _camera.lookAt(0, 0, 0);
    }

    function update(){
        fpsCamera.update();
    }


    function animCheckboxCallback(widget, action){
        local testVals = [
            CharacterModelAnimId.BASE_LEGS_WALK,
            CharacterModelAnimId.BASE_ARMS_WALK,
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

    function createGui(){
        ::containerWin <- _gui.createWindow();
        containerWin.setSize(500, 500);
        local layout = _gui.createLayoutLine();

        local labels = [
            "FeetWalk",
            "UpperWalk"
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
};