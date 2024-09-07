::SceneEditorGUITerrainToolProperties <- class extends ::SceneEditorFramework.GUIPanel{

    mEditTerrain_ = null;
    mEditTerrainHeight_ = null;
    mEditTerrainColour_ = null;

    mEditTerrainColourValue_ = null;
    mEditTerrainHeightValue_ = null;

    constructor(parent, baseObj, bus){
        base.constructor(parent, baseObj, bus);

    }

    function setup(){
        local layout = _gui.createLayoutLine();

        mEditTerrain_ = mParent_.createCheckbox();
        mEditTerrain_.setText("Edit terrain");
        mEditTerrain_.attachListenerForEvent(function(widget, action){
            ::Base.setEditTerrain(widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layout.addCell(mEditTerrain_);

        mEditTerrainHeight_ = mParent_.createCheckbox();
        mEditTerrainHeight_.setText("Edit terrain height");
        mEditTerrainHeight_.attachListenerForEvent(function(widget, action){
            ::Base.setEditTerrainHeight(widget.getValue());
            refreshButtons();
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(mEditTerrainHeight_);

        mEditTerrainColour_ = mParent_.createCheckbox();
        mEditTerrainColour_.setText("Edit terrain colour");
        mEditTerrainColour_.attachListenerForEvent(function(widget, action){
            ::Base.setEditTerrainColour(widget.getValue());
            refreshButtons();
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(mEditTerrainColour_);

        mEditTerrainColourValue_ = ::EditorGUIFramework.Widget.NumericInput(mParent_);
        mEditTerrainColourValue_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainColourValue(val);
            }
        }));
        mEditTerrainColourValue_.addToLayout(layout);

        mEditTerrainHeightValue_ = ::EditorGUIFramework.Widget.NumericInput(mParent_);
        mEditTerrainHeightValue_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainHeightValue(val);
            }
        }));
        mEditTerrainHeightValue_.addToLayout(layout);

        layout.layout();
    }

    function refreshButtons(){
        local state = ::Base.getTerrainEditState();
        mEditTerrainHeight_.setValue(state == TerrainEditState.HEIGHT);
        mEditTerrainColour_.setValue(state == TerrainEditState.COLOUR);
    }

};