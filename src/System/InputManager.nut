::InputManager <- {

    mActionSets_ = []

    function setup(){
        _input.setActionSets({
            "Exploration" : {
                "Buttons" : {
                    "PerformMove1": "#PerformMove1",
                    "PerformMove2": "#PerformMove2",
                    "PerformMove3": "#PerformMove3",
                    "PerformMove4": "#PerformMove4",
                    "Dash": "#Dash",
                    "CancelTarget": "#CancelTarget",
                    "ShowInventory": "#ShowInventory",
                    "Interact": "#Interact",
                    "toggleWieldActive": "#toggleWieldActive",
                    "PauseGame": "#PauseGame",
                    "ShowDebugConsole": "#ShowDebugConsole",
                },
                "StickPadGyro" : {
                    "Move":"#Move",
                    "Camera":"#Camera",
                }
            },
            "Menu" : {
                "Buttons" : {
                    "MenuInteract": "#MenuInteract",
                    "MenuBack": "#MenuBack",
                    "CloseMenu": "#CloseMenu",

                    "MoveLeft": "#MoveLeft",
                    "MoveRight": "#MoveRight",
                }
            },
            "Dialog" : {
                "Buttons" : {
                    "Next": "#Next"
                }
            },
            "DebugConsole" : {
                "Buttons" : {
                    "closeConsole": "#closeConsole"
                }
            }
        });

        ::InputManager.actionSetGameplay <- _input.getActionSetHandle("Exploration");
        ::InputManager.actionSetMenu <- _input.getActionSetHandle("Menu");
        ::InputManager.actionSetDialog <- _input.getActionSetHandle("Dialog");
        ::InputManager.actionSetDebugConsole <- _input.getActionSetHandle("DebugConsole");

        mActionSets_.append(::InputManager.actionSetGameplay);
        mActionSets_.append(::InputManager.actionSetMenu);
        mActionSets_.append(::InputManager.actionSetDialog);
        mActionSets_.append(::InputManager.actionSetDebugConsole);

        //Exploration
        ::InputManager.explorationMove <- _input.getAxisActionHandle("Move");
        ::InputManager.explorationCamera <- _input.getAxisActionHandle("Camera");
        ::InputManager.performMove1 <- _input.getButtonActionHandle("PerformMove1");
        ::InputManager.performMove2 <- _input.getButtonActionHandle("PerformMove2");
        ::InputManager.performMove3 <- _input.getButtonActionHandle("PerformMove3");
        ::InputManager.performMove4 <- _input.getButtonActionHandle("PerformMove4");
        ::InputManager.dash <- _input.getButtonActionHandle("Dash");
        ::InputManager.cancelTarget <- _input.getButtonActionHandle("CancelTarget");
        ::InputManager.showInventory <- _input.getButtonActionHandle("ShowInventory");
        ::InputManager.interact <- _input.getButtonActionHandle("Interact");
        ::InputManager.toggleWieldActive <- _input.getButtonActionHandle("toggleWieldActive");
        ::InputManager.pauseGame <- _input.getButtonActionHandle("PauseGame");
        ::InputManager.showDebugConsole <- _input.getButtonActionHandle("ShowDebugConsole");

        ::InputManager.dialogNext <- _input.getButtonActionHandle("Next");

        ::InputManager.menuInteract <- _input.getButtonActionHandle("MenuInteract");
        ::InputManager.menuBack <- _input.getButtonActionHandle("MenuBack");

        ::InputManager.debugConsoleCloseConsole <- _input.getButtonActionHandle("closeConsole");

        _input.mapControllerInput(_BA_LEFT, this.explorationMove);
        _input.mapControllerInput(_BA_RIGHT, this.explorationCamera);
        _input.mapControllerInput(_B_A, this.dash);
        _input.mapControllerInput(_B_B, this.toggleWieldActive);
        _input.mapControllerInput(_B_X, this.showInventory);
        _input.mapControllerInput(_B_Y, this.interact);
        //_input.mapControllerInput(_B_Y, this.performMove4);
        _input.mapControllerInput(_B_LEFTSHOULDER, this.performMove1);
        _input.mapControllerInput(_B_RIGHTSHOULDER, this.performMove2);
        //TODO NOTE I want to map the triggers just as regular buttons, but the engine does not allow that currently.
        //_input.mapControllerInput(_BT_LEFT, this.performMove3);
        //_input.mapControllerInput(_BT_RIGHT, this.performMove4);
        _input.mapControllerInput(_B_START, this.pauseGame);
        _input.mapControllerInput(_B_A, this.dialogNext);

        _input.mapControllerInput(_B_B, this.menuBack);

        //_input.mapKeyboardInputAxis(_K_RIGHT, _K_DOWN, _K_LEFT, _K_UP, this.explorationMove);
        _input.mapKeyboardInputAxis(_K_D, _K_S, _K_A, _K_W, this.explorationCamera);

        _input.mapKeyboardInput(_K_1, this.performMove1);
        _input.mapKeyboardInput(_K_2, this.performMove2);
        _input.mapKeyboardInput(_K_3, this.performMove3);
        _input.mapKeyboardInput(_K_4, this.performMove4);
        //_input.mapKeyboardInput(_K_ESCAPE, this.cancelTarget);
        _input.mapKeyboardInput(_K_SPACE, this.dash);
        _input.mapKeyboardInput(_K_Z, this.interact);
        _input.mapKeyboardInput(_K_E, this.showInventory);
        _input.mapKeyboardInput(_K_R, this.toggleWieldActive);
        _input.mapKeyboardInput(_K_ESCAPE, this.pauseGame);
        _input.mapKeyboardInput(_K_TAB, this.showDebugConsole);

        _input.mapKeyboardInput(_K_Z, this.dialogNext);

        _input.mapKeyboardInput(_K_ESCAPE, this.menuBack);

        _input.mapKeyboardInput(_K_TAB, this.debugConsoleCloseConsole);
        _input.mapKeyboardInput(_K_ESCAPE, this.debugConsoleCloseConsole);

        //_input.setActionSetForDevice(_ANY_INPUT_DEVICE, ::InputManager.actionSetGameplay);
        setActionSet(InputActionSets.EXPLORATION);
    }

    function setActionSet(actionSet){
        local target = mActionSets_[actionSet];
        _input.setActionSetForDevice(_ANY_INPUT_DEVICE, target);
    }
}