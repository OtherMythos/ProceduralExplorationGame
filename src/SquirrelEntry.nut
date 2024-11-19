function setup(){
    //Simple version of parsing the profile settings.
    //All we care about here is the ForceWindowed flag, so just check for that.
    local profiles = _settings.getUserSetting("profile");
    local windowed = false;

    if(profiles != null){
        local v = split(profiles, ",");
        foreach(i in v){
            if(i == "ForceWindowed"){
                windowed = true;
                break;
            }
        }
    }

    _window.setDefaultFullscreen(windowed ? _WINDOW_WINDOWED : _WINDOW_FULLSCREEN_BORDERLESS);
}

function start(){
    _gui.setScrollSpeed(5.0);
    local deadzone = 0.2;
    _input.setDefaultAxisDeadzone(deadzone);
    _input.setAxisDeadzone(deadzone, _ANY_INPUT_DEVICE);

    _doFile("res://src/Versions.h.nut");
    _doFile("res://src/Constants.nut");
    _doFile("res://src/Helpers.nut");
    _doFile("res://src/MapGen/Exploration/Generator/MapConstants.h.nut");

    _doFile("res://src/System/CompositorManager.nut");
    ::CompositorManager.setup();

    setupInitialCanvasSize();

    _doFile("res://src/Util/StateMachine.nut");
    _doFile("res://src/Util/CombatStateMachine.nut");

    _event.subscribe(_EVENT_SYSTEM_WINDOW_RESIZE, recieveWindowResize, this);

    if(_system.exists("res://developerTools.nut")){
        _doFile("res://developerTools.nut");
    }

    _doFile("res://src/Base.nut");
    checkForProjectExtra();
    ::Base.setup();
    ::Base.setupSecondary();
    ::Base.switchToFirstScreen();
}

function update(){
    ::Base.update();
}

function end(){
    ::Base.shutdown();
}

::checkForProjectExtra <- function(){
    local filePath = "res://extra/GameCore/Base.nut";
    if(_system.exists(filePath)){
        _doFile(filePath);
    }
}

function sceneSafeUpdate(){
    if(::Base.mExplorationLogic != null){
        //::Base.mExplorationLogic.sceneSafeUpdate();
        //::Base.mExplorationLogic.mCurrentWorld_.sceneSafeUpdate();
        ::Base.mExplorationLogic.sceneSafeUpdate();
    }
}

function recieveWindowResize(id, data){
    print("window resized");
    //_gui.setCanvasSize(canvasSize, _window.getActualSize());
    _gui.setCanvasSize(_window.getSize(), _window.getActualSize());
    canvasSize = _window.getSize();
    ::ScreenManager.processResize();
    ::DebugConsole.resize();
}

function setupInitialCanvasSize(){
    ::canvasSize <- _window.getSize();
    ::drawable <- canvasSize.copy();
    //::canvasSize <- Vec2(1, 1);
    ::resolutionMult <- _window.getActualSize() / _window.getSize();
    _gui.setCanvasSize(_window.getSize(), _window.getActualSize());
    _gui.setDefaultFontSize26d6((_gui.getOriginalDefaultFontSize26d6() * ::resolutionMult.x).tointeger());
}