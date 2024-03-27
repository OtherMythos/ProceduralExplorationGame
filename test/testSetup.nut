//General SquirrelEntry.nut for testing.
//Wraps logic for executing tests, also working around issues defining constants in setup files.

::_testSystem <- {
    testFuncs = []

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
};
::_t <- function(testName, testDescription, closure){
    ::_testSystem.registerTest(testName, testDescription, closure);
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

    foreach(c,i in ::_testSystem.testFuncs){
        printf("====== test '%s' ======", i.testName);
        //printf("------ '%s' ------", i.testDescription);
        i.testClosure();
        print("------ finished ------");
    }

    _test.endTest();
}

function end(){

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