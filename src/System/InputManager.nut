::InputManager <- {

    function setup(){
        _input.setActionSets({
            "Exploration" : {
                "Buttons" : {
                    "PerformMove1": "#PerformMove1",
                    "PerformMove2": "#PerformMove2",
                    "PerformMove3": "#PerformMove3",
                    "PerformMove4": "#PerformMove4",
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

        //Exploration
        ::InputManager.explorationMove <- _input.getAxisActionHandle("Move");
        ::InputManager.explorationCamera <- _input.getAxisActionHandle("Camera");
        ::InputManager.performMove1 <- _input.getButtonActionHandle("PerformMove1");
        ::InputManager.performMove2 <- _input.getButtonActionHandle("PerformMove2");
        ::InputManager.performMove3 <- _input.getButtonActionHandle("PerformMove3");
        ::InputManager.performMove4 <- _input.getButtonActionHandle("PerformMove4");

        _input.mapControllerInput(_BA_LEFT, this.explorationMove);
        _input.mapControllerInput(_BA_RIGHT, this.explorationCamera);
        _input.mapControllerInput(_B_A, this.performMove1);
        _input.mapControllerInput(_B_B, this.performMove2);
        _input.mapControllerInput(_B_X, this.performMove3);
        _input.mapControllerInput(_B_Y, this.performMove4);

        //_input.mapKeyboardInputAxis(_K_D, _K_S, _K_A, _K_W, this.explorationMove);
        _input.mapKeyboardInputAxis(_K_D, _K_S, _K_A, _K_W, this.explorationCamera);

        _input.mapKeyboardInput(_K_UP, this.performMove1);
        _input.mapKeyboardInput(_K_DOWN, this.performMove2);
        _input.mapKeyboardInput(_K_LEFT, this.performMove3);
        _input.mapKeyboardInput(_K_RIGHT, this.performMove4);

        _input.setActionSetForDevice(_ANY_INPUT_DEVICE, ::InputManager.actionSetGameplay);
    }
}