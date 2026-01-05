_tIntegration("PlayerDeathFromItem", "Test to check the player death screen can be shown if the player consumes an item that lowers health.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::Base.mPlayerStats.addToInventory(::Item(ItemId.MUSHROOM_1));
            ::Base.mPlayerStats.setPlayerHealth(1);
            ::Base.mExplorationLogic.mCurrentWorld_.showInventory({}, 1);
        },
        function(){
            local screen = ::ScreenManager.getScreenForLayer(1);
            local inventoryObj = screen.mInventoryObj_;
            local invPos = inventoryObj.mInventoryGrid_.getPositionForIdx(0);

            _gui.simulateMousePosition(invPos);
            _gui.simulateMouseButton(_MB_LEFT, true);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Eat");

            ::_testHelper.setQueryText("Return to menu");
        },
        function(){
            ::_testHelper.queryWindowDoesNotExist("InventoryScreen");
        }
        ::_testHelper.STEPS_WAIT_FOR_WIDGET_WITH_TEXT,
        function(){
            ::_testHelper.mousePressWidgetForText(::_testHelper.getQueryText());
        },
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenu");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        ::_testHelper.STEPS_WAIT_FOR_MAP_GEN_COMPLETE,
        function(){
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});