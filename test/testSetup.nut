//General SquirrelEntry.nut for testing.
//Wraps logic for executing tests, also working around issues defining constants in setup files.

::_testSystem <- {
    testFuncs = []
    integration = false
    setupContext = null

    TestEntry = class{
        testName = null;
        testDescription = null;
        testClosure = null;
        constructor(testName, testDescription, closure){
            this.testName = testName;
            this.testDescription = testDescription;
            this.testClosure = closure;
        }
    }

    function registerTest(testName, testDescription, closure){
        local testInstance = TestEntry(testName, testDescription, closure);
        testFuncs.append(testInstance);
    }
    function registerIntegrationTest(testName, testDescription, closure){
        testFuncs = TestEntry(testName, testDescription, closure);
        integration = true
    }

    function registerSetupContext(context){
        setupContext = context;
    }

    function start() { if(testFuncs.testClosure.rawin("start")) testFuncs.testClosure.start(); setupContext.start(); }
    function update() { if(testFuncs.testClosure.rawin("update")) testFuncs.testClosure.update(); setupContext.update(); }
    function end() { if(testFuncs.testClosure.rawin("end")) testFuncs.testClosure.end(); setupContext.update(); }
};
::_t <- function(testName, testDescription, closure){
    ::_testSystem.registerTest(testName, testDescription, closure);
};
::_tIntegration <- function(testName, testDescription, closure){
    ::_testSystem.registerIntegrationTest(testName, testDescription, closure);
};
::_testHelper <- {

    function queryWindow(windowName){
        local numWindows = _gui.getNumWindows();
        for(local i = 0; i < numWindows; i++){
            local window = _gui.getWindowForIdx(i);
            local queryName = window.getQueryName();
            if(queryName == windowName){
                return window;
            }
        }
    }

};

function start(){
    _doFile("script://../src/Helpers.nut")
    _doFile("script://../src/Constants.nut")
    _doFile("script://../src/System/Save/SaveConstants.nut")
    _doFile("script://../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("script://../src/System/Save/SaveManager.nut")

    checkForAdditionalIncludes();

    local setupFile = _settings.getUserSetting("SetupFile")
    if(typeof setupFile != "string") throw "No test setup file was provided.";
    _doFile(setupFile);

    if(::_testSystem.integration){
        local contextTable = {};
        _doFileWithContext("script://../src/SquirrelEntry.nut", contextTable);
        ::_testSystem.registerSetupContext(contextTable);
        ::_testSystem.start();
    }else{
        foreach(c,i in ::_testSystem.testFuncs){
            printf("====== test '%s' ======", i.testName);
            //printf("------ '%s' ------", i.testDescription);
            i.testClosure();
            print("------ finished ------");
        }

        _test.endTest();
    }
}

function update(){
    ::_testSystem.update();
}

function end(){
    ::_testSystem.end();
}

function checkForAdditionalIncludes(){
    local additional = _settings.getUserSetting("Additional")
    if(additional != null){
        if(typeof additional != "string") throw "Additional includes must be string paths, separated by commas.";
        local paths = split(additional, ",");
        foreach(i in paths){
            _doFile(i);
        }
    }
}