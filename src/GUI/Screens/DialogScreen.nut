::DialogScreen <- class extends ::Screen{

    constructor(){

    }

    function setup(){
        //Create a window to block inputs for when the popup appears.
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight() * 0.3333);
        mWindow_.setPosition(0, _window.getHeight() * 0.6666);

        local title = mWindow_.createLabel();
        title.setText("Some dialog");
    }

    function update(){
        //TODO proper buttons to progress this dialog.
        if(_input.getMouseButton(0)){
            ::Base.mDialogManager.notifyProgress();
        }
    }
}