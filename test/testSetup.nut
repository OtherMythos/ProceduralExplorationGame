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
    _doFile("res://../../../../../src/Helpers.nut")
    _doFile("res://../../../../../src/Constants.nut")
    _doFile("res://../../../../../src/System/Save/SaveConstants.nut")
    _doFile("res://../../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../../src/System/Save/SaveManager.nut")

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