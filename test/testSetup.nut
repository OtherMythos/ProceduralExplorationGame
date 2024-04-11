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
        integration = false;

        currentStep = 0;
        currentWaitFrame = -1;
        currentWaitFrameTotal = -1;

        constructor(testName, testDescription, closure, integration){
            this.testName = testName;
            this.testDescription = testDescription;
            this.testClosure = closure;
            this.integration = integration;
        }
        function start(){
            if(testClosure.rawin("start")){
                testClosure.start();
            }
        }
        function update(){
            if(testClosure.rawin("update")){
                testClosure.update();
            }
            if(testClosure.rawin("steps")){
                processSteps();
            }
        }
        function end(){
            if(testClosure.rawin("end")){
                testClosure.update();
            }
        }

        function processSteps(){
            local stepsArray = testClosure.rawget("steps");
            if(currentWaitFrameTotal < 0){
                stepsArray[currentStep]();
                //Check to see if a request to wait frames was called.
                if(currentWaitFrameTotal < 0){
                    jumpStep(stepsArray.len());
                }
            }
            if(currentWaitFrame > 0){
                currentWaitFrame--;
                if(currentWaitFrame <= 0){
                    jumpStep(stepsArray.len());
                }
            }
        }

        function jumpStep(totalSteps){
            currentStep++;
            if(currentStep >= totalSteps){
                _test.endTest();
            }
            currentWaitFrame = -1;
            currentWaitFrameTotal = -1;
        }

        function waitFrames(frames){
            //The general usecase is this is called each frame, so skip unless there has been a change in the requested count.
            if(frames == currentWaitFrameTotal) return;
            currentWaitFrameTotal = frames;
            currentWaitFrame = currentWaitFrameTotal;
        }
    }

    function registerTest(testName, testDescription, closure){
        local testInstance = TestEntry(testName, testDescription, closure, false);
        testFuncs.append(testInstance);
    }
    function registerIntegrationTest(testName, testDescription, closure){
        testFuncs = TestEntry(testName, testDescription, closure, true);
        integration = true
    }

    function registerSetupContext(context){
        setupContext = context;
    }

    function waitFrames(frames){
        testFuncs.waitFrames(frames);
    }

    function start() { if(integration) { testFuncs.start(); setupContext.start() } }
    function update() { if(integration) { testFuncs.update(); setupContext.update() } }
    function end() { if(integration) { testFuncs.end(); setupContext.end() } }
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
    function iterateComparisonFunction(first, second){
        return second.tolower().find(first) != null;
    }
    function iterateWindow_(win, checkString, comparisonFunc){
        for(local i = 0; i < win.getNumChildren(); i++){
            local child = win.getChildForIdx(i);
            local childType = child.getType();
            if(childType == _GUI_WIDGET_WINDOW){
                local result = iterateWindow_(child, checkString, comparisonFunc);
                if(result != null){
                    return result;
                }
                continue;
            }
            if(
                childType == _GUI_WIDGET_BUTTON ||
                childType == _GUI_WIDGET_LABEL ||
                childType == _GUI_WIDGET_ANIMATED_LABEL ||
                childType == _GUI_WIDGET_EDITBOX ||
                childType == _GUI_WIDGET_CHECKBOX ||
                childType == _GUI_WIDGET_SPINNER
            ){
                if(comparisonFunc(checkString, child.getText())){
                    return child;
                }
            }
        }

        return null;
    }
    function getWidgetForText(text){
        local targetText = text.tolower();
        local numWindows = _gui.getNumWindows();
        local foundWidget = null;
        for(local i = 0; i < numWindows; i++){
            local window = _gui.getWindowForIdx(i);
            local result = iterateWindow_(window, targetText, iterateComparisonFunction);
            if(result != null){
                foundWidget = result;
                break;
            }
        }

        return foundWidget;
    }

    function queryTextExists(text){
        if(getWidgetForText(text) == null){
            throw format("No text found for '%s'", text);
        }
    }
    function queryWindowExists(text){
        if(queryWindow(text) == null){
            throw format("No window found for '%s'", text);
        }
    }
    function queryWindowDoesNotExist(text){
        if(queryWindow(text) != null){
            throw format("Window found for '%s' when none should be", text);
        }
    }

    function focusMouseToWidgetForText(text){
        local targetButton = ::_testHelper.getWidgetForText(text);
        if(targetButton == null) throw format("No widget found for text '%s'", text);
        _gui.simulateMousePosition(targetButton.getDerivedCentre());
    }

    function mousePressWidgetForText(text){
        focusMouseToWidgetForText(text);
        _gui.simulateMouseButton(_MB_LEFT, true);
    }

    function waitFrames(frames){
        ::_testSystem.waitFrames(frames);
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