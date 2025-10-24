::SceneEditorGUITerrainToolProperties <- class extends ::SceneEditorFramework.GUIPanel{

    mEditTerrain_ = null;
    mEditTerrainBrushSize_ = null;
    mEditTerrainHeight_ = null;
    mEditTerrainColour_ = null;
    mEditTerrainRegion_ = null;

    mEditTerrainColourValue_ = null;
    mEditTerrainHeightValue_ = null;
    mEditTerrainRegionValue_ = null;

    constructor(parent, baseObj, bus){
        base.constructor(parent, baseObj, bus);

    }

    function setup(){
        local layout = _gui.createLayoutLine();

        /*
        if(::Base.getTargetMapType().getMapType() == SceneEditorMapType.PLACE){
            local label = mParent_.createLabel();
            label.setText("Terrain Properties do not apply for places.");
            return;
        }
            */

        mEditTerrainBrushSize_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "Brush size");
        mEditTerrainBrushSize_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainBrushSize(val);
            }
        }));
        mEditTerrainBrushSize_.addToLayout(layout);

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

        mEditTerrainRegion_ = mParent_.createCheckbox();
        mEditTerrainRegion_.setText("Edit terrain region");
        mEditTerrainRegion_.attachListenerForEvent(function(widget, action){
            ::Base.setEditTerrainRegion(widget.getValue());
            refreshButtons();
        }, _GUI_ACTION_RELEASED, this);
        layout.addCell(mEditTerrainRegion_);

        mEditTerrainHeightValue_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "Height");
        mEditTerrainHeightValue_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainHeightValue(val);
            }
        }));
        mEditTerrainHeightValue_.addToLayout(layout);

        mEditTerrainColourValue_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "Colour");
        mEditTerrainColourValue_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainColourValue(val);
            }
        }));
        mEditTerrainColourValue_.addToLayout(layout);

        mEditTerrainRegionValue_ = ::EditorGUIFramework.Widget.NumericInput(mParent_, false, "Region");
        mEditTerrainRegionValue_.attachListener(::EditorGUIFramework.Listener(function(widget, action){
            if(action == EditorGUIFramework_WidgetCallbackEvent.VALUE_CHANGED){
                local val = widget.getValue();
                ::Base.setEditTerrainRegionValue(val);
            }
        }));
        mEditTerrainRegionValue_.addToLayout(layout);

        local createPopup = mParent_.createButton();
        createPopup.setText("Select voxel");
        createPopup.attachListenerForEvent(function(widget, action){
            ::SceneEditorVoxelSelectionPopup.showPopup();
        }, _GUI_ACTION_PRESSED, this);
        layout.addCell(createPopup);

        layout.layout();

        refreshButtons();
    }

    function refreshButtons(){
        local state = ::Base.getTerrainEditState();
        mEditTerrain_.setValue(::Base.getEditingTerrain());
        mEditTerrainBrushSize_.setValue(::Base.getTerrainBrushSize())
        mEditTerrainHeight_.setValue(state == TerrainEditState.HEIGHT);
        mEditTerrainColour_.setValue(state == TerrainEditState.COLOUR);
        mEditTerrainRegion_.setValue(state == TerrainEditState.REGION);
        mEditTerrainHeightValue_.setValue(::Base.getTerrainEditHeight());
        mEditTerrainColourValue_.setValue(::Base.getTerrainEditColour());
        mEditTerrainRegionValue_.setValue(::Base.getEditTerrainRegionValue());
    }

};