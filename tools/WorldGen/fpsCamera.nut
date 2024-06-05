::fpsCamera <- class{

    mCamera_ = null;

    sense = 0.05;
    cursorMoveStarted = false;
    prevMouseX = 0.0;
    prevMouseY = 0.0;
    yaw = 270.0;
    pitch = 0.0;
    count = 0;
    moveInputHandle = null;
    controllerPointCamera = null;

    constructor(camera){
        mCamera_ = camera;

        moveInputHandle = _input.getAxisActionHandle("LeftMove");
        controllerPointCamera = _input.getAxisActionHandle("RightMove");
    }

    function radians(value){
        return value * (3.14159 / 180);
    }

    function degree(value){
        return value * (180 / 3.14159);
    }

    function update(){
        local xCamera = 0;
        local yCamera = 0;

        local mostRecentDevice = _input.getMostRecentDevice();
        local right = _input.getMouseButton(_MB_RIGHT);

        if(!right){
            print("using controller");

            //TODO limit the values returned here with deadspots.
            xCamera = _input.getAxisActionX(this.controllerPointCamera, _INPUT_ANY, 0);
            yCamera = _input.getAxisActionY(this.controllerPointCamera, _INPUT_ANY, 0);
            yCamera = -yCamera;

            _window.showCursor(true);
            cursorMoveStarted = false;
        }else{
            _window.showCursor(false);

            local newMouseX = _input.getMouseX();
            local newMouseY = _input.getMouseY();

            count++;
            if(count % 10 == 0){
                newMouseX = _window.getWidth() / 2;
                newMouseY = _window.getHeight() / 2;
                prevMouseX = newMouseX;
                prevMouseY = newMouseY;
                _window.warpMouseInWindow(newMouseX, newMouseY);
            }

            if(!cursorMoveStarted && (newMouseX != 0 || newMouseY != 0)){
                cursorMoveStarted = true;
                prevMouseX = newMouseX;
                prevMouseY = newMouseY;
                return;
            }

            xCamera = this.prevMouseX - newMouseX;
            yCamera = this.prevMouseY - newMouseY;
            xCamera = -xCamera;

            xCamera *= sense;
            yCamera *= sense;

            prevMouseX = newMouseX;
            prevMouseY = newMouseY;
        }

        yaw += xCamera;
        pitch += yCamera;
        if(pitch > 89.0) pitch = 89.0;
        if(pitch < -89.0) pitch = -89.0;
        if(yaw > 360.0) yaw = 0.0;
        if(yaw < 0.0) yaw = 360.0;

        local front = Vec3();
        front.x = cos(radians(yaw)) * cos(radians(pitch));
        front.y = sin(radians(pitch));
        front.z = sin(radians(yaw)) * cos(radians(pitch));

        front.normalise();

        mCamera_.setDirection(front);


        local xVal = _input.getAxisActionX(this.moveInputHandle, _INPUT_ANY);
        local yVal = _input.getAxisActionY(this.moveInputHandle, _INPUT_ANY);

        // local thing = Vec3();
        // if(yVal > 0) thing.

        local target = Vec3();
        if(yVal > 0.2){
            target = -front;
            target *= 2;
        }else if(yVal < -0.2){
            target = front;
            target *= 2;
        }

        local node = mCamera_.getParentNode();
        if(xVal > 0.2){
            target = node.getOrientation() * ::Vec3_UNIT_X;
            target *= 2;
        }
        else if(xVal < -0.2){
            target = -(node.getOrientation() * ::Vec3_UNIT_X);
            target *= 2;
        }

        node.setPosition(node.getPosition() + target);

        // xCamera *= sense;
        // yCamera *= sense;

        // yaw += xCamera;
        // pitch += yCamera;
        // if(pitch > 89.0f) pitch = 89.0f;
        // if(pitch < -89.0f) pitch = -89.0f;
        // if(yaw > 360.0f) yaw = 0.0f;
        // if(yaw < 0.0f) yaw = 360.0f;

    }
};
