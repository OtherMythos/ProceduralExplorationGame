::SceneEditorSceneWindowButtons <- class{

    mWindow_ = null;
    mButtons_ = null;
    mMagenticOption_ = null;

    constructor(parentWindow, parentGuiWindow){
        this.mWindow_ = parentWindow;
        //mWindow_ = _gui.createWindow("SceneEditorSceneWindowButtons");
        //mWindow_.setVisualsEnabled(false);
        //mWindow_.setSkin("EditorGUIFramework/WindowNoBorder");
        mButtons_ = [];

        local layout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);

        local buttonLabels = [
            "Position",
            "Scale",
            "Raycast"
        ];
        local buttonFunctions = [
            function(widget, action){
                ::Base.mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.POSITION);
            },
            function(widget, action){
                ::Base.mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.SCALE);
            },
            function(widget, action){
                ::Base.mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.RAYCAST);
            }
        ];
        foreach(c,i in buttonLabels){
            local button = mWindow_.createButton();
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED);
            layout.addCell(button);
            mButtons_.append(button);
        }

        mMagenticOption_ = this.mWindow_.createCheckbox();
        mMagenticOption_.setText("Magnetic");
        mMagenticOption_.attachListenerForEvent(function(widget, event){
            ::Base.mEditorBase.getActiveSceneTree().setMagneticEdit(widget.getValue());
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(mMagenticOption_);

        layout.setMarginForAllCells(5, 0);
        layout.setPosition(-5, 0);
        layout.layout();

        ::evenOutButtonsForHeight(mButtons_);

        local childSize = mWindow_.calculateChildrenSize();
        parentGuiWindow.setSize(childSize);
    }

    function setPosition(pos){
        //mWindow_.setPosition(pos);
    }

};