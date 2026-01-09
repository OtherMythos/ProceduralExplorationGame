_tIntegration("MainMenuMobileInventoryMoveCursor", "Test to check the inventory can click an item then move the cursor with the mouse still down", {
    "steps": [
        function(){
            ::_testHelper.generateSimpleSaves(1);
            ::_testHelper.setDefaultWaitFrames(5);
        },
        function(){
            local screen = ::ScreenManager.getScreenForLayer(0);
            local inventoryObj = screen.mInventoryObj_;
            local invPos = inventoryObj.mInventoryGrid_.getPositionForIdx(0);

            ::startInvPos <- invPos;
            _gui.simulateMousePosition(invPos);
            _gui.simulateMouseButton(_MB_LEFT, true);
        },
        function(){
            for(local i = 0; i < 50; i++){
                ::startInvPos += Vec2(1, 0);
                _gui.simulateMousePosition(::startInvPos);
                print(::startInvPos);

                if(::startInvPos.x <= 1000){
                    ::_testHelper.repeatStep();
                }
            }
        }
    ]
});