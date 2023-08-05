::SceneEditorGUITerrainToolProperties <- class extends ::SceneEditorFramework.GUIPanel{

    constructor(parent, baseObj, bus){
        base.constructor(parent, baseObj, bus);

    }

    function setup(){
        local layout = _gui.createLayoutLine();

        local label = mParent_.createLabel();
        label.setText("Terrain");
        layout.addCell(label);

        local testButton = mParent_.createButton();
        testButton.setText("Test remove from terrain");
        testButton.attachListenerForEvent(function(widget, action){
            ::Base.mTerrainChunkManager.drawHeightValues(10, 10, 1, 1, [1]);
        }, _GUI_ACTION_PRESSED, this);
        layout.addCell(testButton);

        local editTerrain = mParent_.createCheckbox();
        editTerrain.setText("Edit terrain");
        editTerrain.attachListenerForEvent(function(widget, action){
            ::Base.setEditTerrain(widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layout.addCell(editTerrain);

        layout.layout();
    }

};