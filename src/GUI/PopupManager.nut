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
    }

    function _wrapPopupData(data){
        if(data == null) return data;
        local popupData = data;
        if(typeof popupData != ObjectType.SCREEN_DATA){
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

    function displayPopup(popupId){
        local popupData = _wrapPopupData(popupId);
        local popupObject = _createPopupForId(popupData);

        if(!popupObject) return;

        popupObject.setup(popupData.data);
        mActivePopups_.append(popupObject);
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