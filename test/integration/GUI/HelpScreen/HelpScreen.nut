_tIntegration("HelpScreen", "Switch from the main menu to the help screen.", {

    "start": function(){
        ::stage <- 0;
    }

    "steps": [
        function(){
            _test.assertNotEqual(::_testHelper.queryWindow("MainMenuScreen"), null);
            _test.assertEqual(::_testHelper.queryWindow("HelpScreen"), null);
        },
        function(){
            ::ScreenManager.transitionToScreen(Screen.HELP_SCREEN);
        },
        function(){
            _test.assertNotEqual(::_testHelper.queryWindow("HelpScreen"), null);
            _test.assertEqual(::_testHelper.queryWindow("MainMenuScreen"), null);
        }
    ]
});