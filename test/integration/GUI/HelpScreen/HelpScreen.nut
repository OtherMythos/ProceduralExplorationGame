_tIntegration("HelpScreen", "Switch from the main menu to the help screen.", {

    "start": function(){
        ::stage <- 0;
    }

    "update": function(){
        if(::stage == 0){
            _test.assertNotEqual(::_testHelper.queryWindow("MainMenuScreen"), null);
            _test.assertEqual(::_testHelper.queryWindow("HelpScreen"), null);
            stage++;
        }
        else if(::stage == 1){
            ::ScreenManager.transitionToScreen(Screen.HELP_SCREEN);
            stage++;
        }
        else if(::stage == 2){
            _test.assertNotEqual(::_testHelper.queryWindow("HelpScreen"), null);
            _test.assertEqual(::_testHelper.queryWindow("MainMenuScreen"), null);

            stage++;
        }
        else if(::stage == 3){
            _test.endTest();
        }
    }

});