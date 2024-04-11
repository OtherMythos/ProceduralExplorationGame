_tIntegration("HelpScreen", "Switch from the main menu to the help screen.", {
    "steps": [
        function(){
            ::_testHelper.queryWindowExists("MainMenuScreen");
            ::_testHelper.queryWindowDoesNotExist("HelpScreen");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Help");
        },
        function(){
            ::_testHelper.queryWindowDoesNotExist("MainMenuScreen");
            ::_testHelper.queryWindowExists("HelpScreen");

            //Assume this is enough to check for the help text.
            ::_testHelper.queryTextExists("OtherMythos");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Back");
        },
        function(){
            ::_testHelper.queryWindowExists("MainMenuScreen");
            ::_testHelper.queryWindowDoesNotExist("HelpScreen");
        },
    ]
});