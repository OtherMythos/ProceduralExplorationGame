::PopupManager.Popups[Popup.TOP_RIGHT_OF_SCREEN] = class extends ::PopupManager.Popups[Popup.BOTTOM_OF_SCREEN]{

    function setup(data){
        base.setup(data);

        setSize(Vec2(_window.getWidth() * 0.3, 100));
    }

    function getIntendedPosition(){
        return Vec2(_window.getWidth() * 0.7 - 10, 10);
    }

    function getAnimOffset(percentage){
        return Vec2(percentage * 20, 0);
    }

};