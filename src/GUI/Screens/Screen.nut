//Base class
::Screen <- class{
    mWindow_ = null;

    constructor(){

    }

    function start(){

    }

    function update(){

    }

    function shutdown(){
        _gui.destroy(mWindow_);
    }
};