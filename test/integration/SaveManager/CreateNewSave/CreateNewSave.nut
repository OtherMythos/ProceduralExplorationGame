_tIntegration("CreateNewSave", "Move through the gui screen and create a new save, making sure the game doesn't crash", {
    "start": function(){
        ::_testHelper.clearAllSaves();

        ::NAME <- "testPlayerName";
        ::createdNames <- [];
    },

    "steps": [
        {
            "repeat": 5,
            "steps":[
                function(){
                    ::_testHelper.waitFrames(20);

                    ::ScreenManager.transitionToScreen(Screen.SAVE_SELECTION_SCREEN);
                },
                function(){
                    ::_testHelper.waitFrames(20);

                    ::_testHelper.mousePressWidgetForText("new save");
                    ::_testHelper.queryTextExists("confirm");
                    ::_testHelper.queryTextExists("cancel");
                },
                function(){
                    ::_testHelper.waitFrames(20);

                    local screen = ::ScreenManager.getScreenForLayer(1);
                    local editbox = screen.mEditBox_;
                    local newName = ::NAME + ::createdNames.len();

                    editbox.setText(newName);
                    ::createdNames.append(newName);

                    ::_testHelper.mousePressWidgetForText("confirm");
                },
                function(){
                    //Ensure that the created saves were shown in the list.
                    local saveInfo = ::Base.mSaveManager.obtainViableSaveInfo();
                    _test.assertEqual(saveInfo.len(), ::createdNames.len());
                    for(local i = 0; i < saveInfo.len(); i++){
                        _test.assertEqual(saveInfo[i].playerName, ::createdNames[i]);
                    }
                }
            ]
        }
    ],

    "end": function(){
        ::_testHelper.clearAllSaves();
    }
});