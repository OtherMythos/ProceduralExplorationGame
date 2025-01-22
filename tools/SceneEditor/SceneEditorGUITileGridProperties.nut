::SceneEditorGUITileGridProperties <- class extends ::SceneEditorFramework.GUIPanel{

    mTileTypeInput_ = null
    mTileType_ = null
    mTileRotation_ = null
    mEditTileGrid_ = null

    constructor(parent, baseObj, bus){
        base.constructor(parent, baseObj, bus);

    }

    function setup(){
        local layout = _gui.createLayoutLine();

        mEditTileGrid_ = mParent_.createCheckbox();
        mEditTileGrid_.setText("Edit tile grid");
        mEditTileGrid_.attachListenerForEvent(function(widget, action){
            ::Base.setEditTileGrid(widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layout.addCell(mEditTileGrid_);

        mEditTileGrid_ = mParent_.createCheckbox();
        mEditTileGrid_.setText("Draw holes");
        mEditTileGrid_.attachListenerForEvent(function(widget, action){
            ::Base.setTileDrawHoles(widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layout.addCell(mEditTileGrid_);

        mTileTypeInput_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "tile");
        mTileTypeInput_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();

                ::Base.setEditingTile(val);
            }
        }));
        mTileTypeInput_.addToLayout(layout);

        mTileRotation_ = mParent_.createSpinner();
        mTileRotation_.setOptions(["0", "90", "180", "270"]);
        mTileRotation_.attachListenerForEvent(function(widget, action){
            local value = widget.getValueRaw();
            print(value);
            ::Base.setEditingTileRotation(value);
        }, _GUI_ACTION_VALUE_CHANGED);
        layout.addCell(mTileRotation_);

        layout.layout();

        refreshButtons();
    }

    function refreshButtons(){
        mEditTileGrid_.setValue(::Base.getEditingTileGrid());
        local tileEditData = ::Base.getTileEditData();
        mTileTypeInput_.setValue(tileEditData.tile);
        mTileRotation_.setValueRaw(tileEditData.tileRotation);
        mEditTileGrid_.setValue(tileEditData.drawHoles);
    }

};