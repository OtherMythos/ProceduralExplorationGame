::SceneEditorTileGridResizePopup <- {

    mPopup_ = null
    mVoxelSelectionPanel_ = null

    mWidthInput_ = null
    mHeightInput_ = null

    function showPopup(width, height){
        mPopup_ = ::guiFrameworkBase.createPopup(124, "Set tile grid size");
        mPopup_.setSize(_window.getSize() * 0.2);
        mPopup_.centrePopup();

        local win = mPopup_.getWin();

        local layout = _gui.createLayoutLine();

        mWidthInput_ = ::EditorGUIFramework.Widget.NumericInput(win, false, "width");
        mWidthInput_.setValue(width);
        mWidthInput_.addToLayout(layout);

        mHeightInput_ = ::EditorGUIFramework.Widget.NumericInput(win, false, "height");
        mHeightInput_.setValue(height);
        mHeightInput_.addToLayout(layout);

        local acceptButton = win.createButton();
        acceptButton.setText("Change");
        acceptButton.attachListenerForEvent(function(widget, action){
            local newWidth = mWidthInput_.getValue();
            local newHeight = mHeightInput_.getValue();
            ::Base.resizeTileGrid(newWidth, newHeight)

            mPopup_.closePopup();
            mPopup_ = null;
        }, _GUI_ACTION_PRESSED, this);
        layout.addCell(acceptButton);

        layout.layout();

    }

};