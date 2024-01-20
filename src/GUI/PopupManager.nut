::PopupManager <- {

    PopupData = class{
        id = Popup.POPUP;
        data = null;
        constructor(id, data){
            this.id = id;
            this.data = data;
        }
        function _typeof(){
            return ObjectType.POPUP_DATA;
        }
    }

    Popups = array(Popup.MAX, null)

    mActivePopups_ = null

    function setup(){
        mActivePopups_ = [];

        _event.subscribe(Event.SCREEN_CHANGED, recieveScreenChange, this);
    }
    function shutdown(){
        _event.unsubscribe(Event.SCREEN_CHANGED, recieveScreenChange, this);
    }

    function recieveScreenChange(id, data){
        killAllPopups();
    }

    function _wrapPopupData(data){
        if(data == null) return data;
        local popupData = data;
        if(typeof popupData != ObjectType.POPUP_DATA){
            popupData = PopupData(data, null);
        }
        return popupData;
    }

    function _createPopupForId(popupData){
        if(popupData == null){
            return null;
        }
        return Popups[popupData.id](popupData);
    }

    function killAllPopups(){
        foreach(i in mActivePopups_){
            i.shutdown();
        }
        mActivePopups_.clear();
    }

    function displayPopup(popupId){
        local popupData = _wrapPopupData(popupId);
        local popupObject = _createPopupForId(popupData);

        if(!popupObject) return;

        popupObject.setup(popupData.data);
        mActivePopups_.append(popupObject);

        popupObject.setZOrder(POPUPS_START_Z);
    }

    function purgeOldPopups_(){
        while(true){
            local idx = mActivePopups_.find(null);
            if(idx == null) return

            mActivePopups_.remove(idx);
        }
    }

    function update(){
        local popupFinished = false;

        foreach(c,i in mActivePopups_){
            local alive = i.update();
            if(!alive){
                print("Shutting down popup " + c);
                i.shutdown();
                mActivePopups_[c] = null;
                popupFinished = true;
            }
        }

        if(popupFinished){
            purgeOldPopups_();
        }
    }
};