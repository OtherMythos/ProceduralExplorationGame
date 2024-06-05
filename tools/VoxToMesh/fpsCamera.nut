::fpsCamera <- {

    mSpeedModifier = false

    function radians(value){
        return value * (3.14159 / 180);
    }

    function degree(value){
        return value * (180 / 3.14159);
    }

    function start(pos=null, rot=null){
        this.sense <- 0.05;
        this.cursorMoveStarted <- false;

        this.moveInputHandle <- _input.getAxisActionHandle("LeftMove");
        this.controllerPointCamera <- _input.getAxisActionHandle("RightMove");

        this.prevMouseX <- 0.0;
        this.prevMouseY <- 0.0;

        this.yaw <- 270.0;
        this.pitch <- 0.0;

        this.count <- 0;

        if(pos != null){
            _camera.setPosition(pos);
        }
        if(rot != null){
            this.yaw = rot.x;
            this.pitch = rot.y;
        }
    }

    function update(){
        local xCamera = 0;
        local yCamera = 0;

        local mostRecentDevice = _input.getMostRecentDevice();
        local right = _input.getMouseButton(_MB_RIGHT);

        if(!right){
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

        _camera.setDirection(front);


        local xVal = _input.getAxisActionX(this.moveInputHandle, _INPUT_ANY);
        local yVal = _input.getAxisActionY(this.moveInputHandle, _INPUT_ANY);

        // local thing = Vec3();
        // if(yVal > 0) thing.

        local target = Vec3();
        local speed = mSpeedModifier ? 1.0 : 0.3;
        if(yVal > 0.2){
            target = -front;
            target *= speed;
        }else if(yVal < -0.2){
            target = front;
            target *= speed;
        }

        if(xVal > 0.2){
            target = _camera.getOrientation() * ::Vec3_UNIT_X;
            target *= speed;
        }
        else if(xVal < -0.2){
            target = -(_camera.getOrientation() * ::Vec3_UNIT_X);
            target *= speed;
        }

        _camera.setPosition(_camera.getPosition() + target);

        // xCamera *= sense;
        // yCamera *= sense;

        // yaw += xCamera;
        // pitch += yCamera;
        // if(pitch > 89.0f) pitch = 89.0f;
        // if(pitch < -89.0f) pitch = -89.0f;
        // if(yaw > 360.0f) yaw = 0.0f;
        // if(yaw < 0.0f) yaw = 360.0f;

    }

    function setSpeedModifier(modifier){
        mSpeedModifier = modifier;
    }
};
