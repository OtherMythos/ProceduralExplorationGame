_tIntegration("VisitPlace", "Visit a place from the exploration overworld and ensure the transition can happen correctly.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::_testHelper.waitFrames(30);
        },
        function(){
            ::Base.mExplorationLogic.mCurrentWorld_.visitPlace("testVillage");
        },
        function(){
            ::_testHelper.waitFrames(300);
        },
    ]
});