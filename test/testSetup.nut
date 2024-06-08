//General SquirrelEntry.nut for testing.
//Wraps logic for executing tests, also working around issues defining constants in setup files.

::_testSystem <- {
    testFuncs = []
    integration = false
    setupContext = null

    currentCalledEntry = null

    /**
    Steps can either define a function or a data block.
    Functions are the simplest form, as they are called once and the step is jumped.
    Data blocks can define things like repetitions to repeat the same group of steps.
    Steps can be nested within data blocks and the step is only jumped when each of the steps has returned itself as having finished.
    */
    TestStepEntry = class{
        currentWaitFrame = -1;
        currentWaitFrameTotal = -1;

        mFunction = null;
        mCalledOnce = false;

        mRepeatCount = 0;
        mRepeatCountTotal = 0;
        mSteps = null;
        mStepsFinished = false;

        constructor(i){
            local t = typeof i;
            if(t == "function"){
                mFunction = i;
            }
            else if(t == "table"){
                if(i.rawin("repeat")){
                    mRepeatCountTotal = i.rawget("repeat");
                    mRepeatCount = 0;
                }
                if(i.rawin("steps")){
                    mSteps = ::_testSystem.TestSteps(i.rawget("steps"));
                }
            }else{
                assert(false);
            }
        }
        function prepareBegin(){
            resetWaitFrame();
            mCalledOnce = false;
        }
        function update(){
            local result = false;
            if(!mCalledOnce){
                if(mFunction != null){
                    ::_testSystem.currentCalledEntry = this;
                    mFunction();
                    ::_testSystem.currentCalledEntry = null;
                    //Check to see if a request to wait frames was called.
                    //If it's still -1 then move on.
                    if(currentWaitFrameTotal < 0){
                        result = true;
                    }
                    mCalledOnce = true;
                }else{
                    if(!mStepsFinished){
                        if(mSteps.update()){
                            mStepsFinished = true;
                        }
                    }
                }
            }
            if(currentWaitFrame > 0){
                //We have steps, wait for them to finish before processing the wait frame.
                if(mFunction == null){
                    if(mStepsFinished){
                        local waitCompleted = processWaitFrame_()
                        if(waitCompleted){
                            result = jumpRepeat();
                        }
                    }
                }else{
                    //Otherwise just process the wait frame like normal.
                    result = processWaitFrame_()
                }
            }
            if(currentWaitFrameTotal < 0){
                //In the case of no wait frame.
                if(mFunction == null){
                    if(mStepsFinished){
                        result = jumpRepeat();
                    }
                }
            }

            return result;
        }
        function processWaitFrame_(){
            currentWaitFrame--;
            if(currentWaitFrame <= 0){
                return true;
            }
            return false;
        }
        function jumpRepeat(){
            mRepeatCount++;
            if(mRepeatCount >= mRepeatCountTotal){
                print("finished repeats");
                return true;
            }

            resetWaitFrame();

            mStepsFinished = false;
            mSteps.resetSteps();
            return false;
        }
        function waitFrames(frames){
            //The general usecase is this is called each frame, so skip unless there has been a change in the requested count.
            if(frames == currentWaitFrameTotal) return;
            currentWaitFrameTotal = frames;
            currentWaitFrame = currentWaitFrameTotal;
        }
        function resetWaitFrame(){
            currentWaitFrame = ::_testHelper.mDefaultWaitFrames;
            currentWaitFrameTotal = ::_testHelper.mDefaultWaitFrames;
        }
        function reset(){
            resetWaitFrame();
            mCalledOnce = false;
            mRepeatCount = 0;
            mStepsFinished = false;
            if(mSteps != null){
                mSteps.resetSteps();
            }
        }
    }
    /**
    Stores a list of steps to complete.
    An array will be used and each index will be represented by a TestStepEntry
    Keeps track of which state is currently active and whether the steps are complete.
    */
    TestSteps = class{
        mCurrentStep = 0;
        mTotalSteps = 0;

        mSteps = null;
        constructor(steps){
            local s = [];
            foreach(i in steps){
                s.append(::_testSystem.TestStepEntry(i));
            }

            mSteps = s;
            mTotalSteps = mSteps.len();
        }

        function update(){
            local result = mSteps[mCurrentStep].update();
            if(result){
                jumpStep();
            }
            return mCurrentStep >= mTotalSteps;
        }

        function jumpStep(){
            mCurrentStep++;
            if(mCurrentStep < mTotalSteps){
                mSteps[mCurrentStep].prepareBegin();
            }
        }

        function resetSteps(){
            mCurrentStep = 0;
            foreach(i in mSteps){
                i.reset();
            }
        }
    }
    TestEntry = class{
        testName = null;
        testDescription = null;
        testClosure = null;
        integration = false;

        parentTestStep = null;

        constructor(testName, testDescription, closure, integration){
            this.testName = testName;
            this.testDescription = testDescription;
            this.testClosure = closure;
            this.integration = integration;

            if(integration){
                if(testClosure.rawin("steps")){
                    initialiseSteps(testClosure.rawget("steps"));
                }
            }
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
            if(parentTestStep != null){
                local result = parentTestStep.update();
                if(result){
                    _test.endTest();
                }
            }
        }
        function end(){
            if(testClosure.rawin("end")){
                testClosure.update();
            }
        }

        function initialiseSteps(steps){
            if(typeof steps == "array"){
                parentTestStep = ::_testSystem.TestSteps(steps);
                parentTestStep.resetSteps();
            }else if(typeof steps == "table"){
                parentTestStep = ::_testSystem.TestStepEntry(steps);
            }
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
        if(currentCalledEntry == null) throw "Only call 'waitFrames' within a step function.";
        currentCalledEntry.waitFrames(frames);
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
::_tStress <- function(testName, testDescription, closure){
    ::_testSystem.registerIntegrationTest(testName, testDescription, closure);
};
::_testHelper <- {

    mDefaultWaitFrames = -1

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
            if(window.getQueryName() == "DebugConsole") continue;
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

    function setDefaultWaitFrames(frames){
        mDefaultWaitFrames = frames;
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

_doFile("script://projectTestHelpers.nut");