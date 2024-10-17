::PopupManager.Popups[Popup.TOP_RIGHT_OF_SCREEN] = class extends ::PopupManager.Popups[Popup.BOTTOM_OF_SCREEN]{

    function setup(data){
        base.setup(data);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        if(mobile){
            setSize(Vec2(_window.getWidth() * 0.9, 100));
        }else{
            setSize(Vec2(_window.getWidth() * 0.3, 100));
        }
    }

    function getIntendedPosition(){
        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        if(mobile){
            return Vec2(_window.getWidth() * 0.05 - 10, 10);
        }else{
            return Vec2(_window.getWidth() * 0.7 - 10, 10);
        }
    }

    function getAnimOffset(percentage){
        return Vec2(percentage * 20, 0);
    }

};