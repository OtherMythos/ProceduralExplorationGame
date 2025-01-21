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

        mTileTypeInput_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "tile");
        mTileTypeInput_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();

                ::Base.setEditingTile(val);
            }
        }));
        mTileTypeInput_.addToLayout(layout);

        mTileType_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "tile type");
        mTileType_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();

                ::Base.setEditingTileType(val);
            }
        }));
        mTileType_.addToLayout(layout);

        mTileRotation_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "tile rotation");
        mTileRotation_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();

                ::Base.setEditingTileRotation(val);
            }
        }));
        mTileRotation_.addToLayout(layout);

        layout.layout();

        refreshButtons();
    }

    function refreshButtons(){
        mEditTileGrid_.setValue(::Base.getEditingTileGrid());
        local tileEditData = ::Base.getTileEditData();
        mTileTypeInput_.setValue(tileEditData.tile);
        mTileType_.setValue(tileEditData.tileType);
        mTileRotation_.setValue(tileEditData.tileRotation);
    }

};