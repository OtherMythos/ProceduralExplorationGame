_tIntegration("MainMenuMobileInventory", "Test to check the inventory system works as expected in the complex main menu screen.", {
    "steps": [
        function(){
            ::_testHelper.generateSimpleSaves(1);
            ::_testHelper.setDefaultWaitFrames(20);
        },
        ::_testHelper.STEPS_WAIT_FOR_SPLASH_SCREEN,
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenuComplex");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Inventory");
        },
        function(){
            ::Base.mPlayerStats.setPlayerHealth(10);
            ::Base.mPlayerStats.addToInventory(::Item(ItemId.APPLE));
        },
        function(){
            local screen = ::ScreenManager.getScreenForLayer(0);
            local inventoryWindow = screen.mTabWindows_[1];
            local inventoryObj = inventoryWindow.mInventoryObj_;
            local invPos = inventoryObj.mInventoryGrid_.getPositionForIdx(0);

            _gui.simulateMousePosition(invPos);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Use");
        },
        function(){
            //The health should've changed because the apple was consumed.
            local health = ::Base.mPlayerStats.getPlayerHealth();
            _test.assertNotEqual(health, 10);
        },
        function(){
            ::Base.mPlayerStats.addToInventory(::Item(ItemId.APPLE));
        },
        function(){
            local screen = ::ScreenManager.getScreenForLayer(0);
            local inventoryWindow = screen.mTabWindows_[1];
            local inventoryObj = inventoryWindow.mInventoryObj_;
            local invPos = inventoryObj.mInventoryGrid_.getPositionForIdx(0);

            _gui.simulateMousePosition(invPos);
        },
        function(){
            //Shutdown the screen manager to simulate engine shutdown with the helper screen popup visible.
            ::ScreenManager.shutdown();
        }

    ]
});