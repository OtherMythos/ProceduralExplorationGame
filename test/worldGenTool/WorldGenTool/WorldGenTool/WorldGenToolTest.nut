_tIntegration("WorldGenToolTest", "Sanity test to check that the world gen tool can be started up", {
    "steps": [
        function(){
            ::_testHelper.waitFrames(10);

            ::_testHelper.queryTextExists("World Gen Tool");
        },
        function(){
            //::_testHelper.queryTextExists("Generating");
            local widget = ::_testHelper.getWidgetForText("Generating");
            if(widget != null){
                ::_testHelper.repeatStep();
            }
        }
    ]
});