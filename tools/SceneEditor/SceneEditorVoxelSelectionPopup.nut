::SceneEditorVoxelSelectionPopup <- {

    mPopup_ = null
    mVoxelSelectionPanel_ = null

    function showPopup(){
        mPopup_ = ::guiFrameworkBase.createPopup(123, "Select voxel colour");
        mPopup_.setSize(_window.getSize() * 0.75);
        mPopup_.centrePopup();

        local win = mPopup_.getWin();
        win.setSkinPack("internal/WindowNoBorder");
        mVoxelSelectionPanel_ = win.createPanel();
        mVoxelSelectionPanel_.setSkinPack("Empty");
        mVoxelSelectionPanel_.setDatablock("SceneEditorTool/voxelPalette");
        mVoxelSelectionPanel_.setSize(win.getSize());

        local inputCheckButton = win.createButton();
        inputCheckButton.setPosition(0, 0);
        inputCheckButton.setSize(win.getSize());
        inputCheckButton.setVisualsEnabled(false);
        inputCheckButton.attachListenerForEvent(function(widget, action){
            local win = mPopup_.getWin();
            local mousePos = Vec2(_input.getMouseX(), _input.getMouseY());
            mousePos -= win.getDerivedPosition();

            local winSize = win.getSize();
            local xIdx = (mousePos.x / (winSize.x / 16.0)).tointeger();
            local yIdx = (mousePos.y / (winSize.y / 16.0)).tointeger();
            local idx = xIdx + (yIdx * 16);
            printf("voxel: x: %i y: %i id: %i", xIdx, yIdx, idx);

            ::Base.setEditTerrainColourValue(idx);
            mPopup_.closePopup();
            mPopup_ = null;
        }, _GUI_ACTION_RELEASED, this);

    }

};