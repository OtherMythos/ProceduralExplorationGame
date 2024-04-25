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
                    "CancelTarget": "#CancelTarget",
                    "ShowInventory": "#ShowInventory",
                    "PauseGame": "#PauseGame",
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
            }
        });

        ::InputManager.actionSetGameplay <- _input.getActionSetHandle("Exploration");
        ::InputManager.actionSetMenu <- _input.getActionSetHandle("Menu");

        mActionSets_.append(::InputManager.actionSetGameplay);
        mActionSets_.append(::InputManager.actionSetMenu);

        //Exploration
        ::InputManager.explorationMove <- _input.getAxisActionHandle("Move");
        ::InputManager.explorationCamera <- _input.getAxisActionHandle("Camera");
        ::InputManager.performMove1 <- _input.getButtonActionHandle("PerformMove1");
        ::InputManager.performMove2 <- _input.getButtonActionHandle("PerformMove2");
        ::InputManager.performMove3 <- _input.getButtonActionHandle("PerformMove3");
        ::InputManager.performMove4 <- _input.getButtonActionHandle("PerformMove4");
        ::InputManager.cancelTarget <- _input.getButtonActionHandle("CancelTarget");
        ::InputManager.showInventory <- _input.getButtonActionHandle("ShowInventory");
        ::InputManager.pauseGame <- _input.getButtonActionHandle("PauseGame");

        ::InputManager.menuInteract <- _input.getButtonActionHandle("MenuInteract");
        ::InputManager.menuBack <- _input.getButtonActionHandle("MenuBack");

        _input.mapControllerInput(_BA_LEFT, this.explorationMove);
        _input.mapControllerInput(_BA_RIGHT, this.explorationCamera);
        _input.mapControllerInput(_B_A, this.performMove1);
        _input.mapControllerInput(_B_B, this.performMove2);
        _input.mapControllerInput(_B_X, this.performMove3);
        _input.mapControllerInput(_B_Y, this.performMove4);
        _input.mapControllerInput(_B_LEFTSHOULDER, this.cancelTarget);
        _input.mapControllerInput(_B_RIGHTSHOULDER, this.cancelTarget);
        _input.mapControllerInput(_B_BACK, this.showInventory);
        _input.mapControllerInput(_B_GUIDE, this.pauseGame);

        _input.mapControllerInput(_B_B, this.menuBack);

        //_input.mapKeyboardInputAxis(_K_RIGHT, _K_DOWN, _K_LEFT, _K_UP, this.explorationMove);
        _input.mapKeyboardInputAxis(_K_D, _K_S, _K_A, _K_W, this.explorationCamera);

        _input.mapKeyboardInput(_K_1, this.performMove1);
        _input.mapKeyboardInput(_K_2, this.performMove2);
        _input.mapKeyboardInput(_K_3, this.performMove3);
        _input.mapKeyboardInput(_K_4, this.performMove4);
        //_input.mapKeyboardInput(_K_ESCAPE, this.cancelTarget);
        _input.mapKeyboardInput(_K_E, this.showInventory);
        _input.mapKeyboardInput(_K_ESCAPE, this.pauseGame);

        _input.mapKeyboardInput(_K_ESCAPE, this.menuBack);

        //_input.setActionSetForDevice(_ANY_INPUT_DEVICE, ::InputManager.actionSetGameplay);
        setActionSet(InputActionSets.EXPLORATION);
    }

    function setActionSet(actionSet){
        local target = mActionSets_[actionSet];
        _input.setActionSetForDevice(_ANY_INPUT_DEVICE, target);
    }
}