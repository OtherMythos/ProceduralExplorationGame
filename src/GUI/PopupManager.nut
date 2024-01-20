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
    mPopupsForId_ = null
    mPopupIdPool_ = null

    function setup(){
        mActivePopups_ = [];
        mPopupsForId_ = array(Popup.MAX)
        mPopupIdPool_ = IdPool();

        _event.subscribe(Event.SCREEN_CHANGED, recieveScreenChange, this);
    }
    function shutdown(){
        _event.unsubscribe(Event.SCREEN_CHANGED, recieveScreenChange, this);
        killAllPopups();
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
        local id = mPopupIdPool_.getId();
        return Popups[popupData.id](popupData, id);
    }

    function killAllPopups(){
        foreach(i in mActivePopups_){
            i.shutdown();
        }
        mActivePopups_.clear();
        mPopupsForId_ = array(Popup.MAX);
    }

    function displayPopup(popupId){
        local popupData = _wrapPopupData(popupId);
        local popupObject = _createPopupForId(popupData);

        if(!popupObject) return;

        popupObject.setup(popupData.data);
        mActivePopups_.append(popupObject);

        if(popupObject.mForceSingleInstance){
            local currentPopup = mPopupsForId_[popupData.id];
            if(currentPopup != null){
                foreach(c,i in mActivePopups_){
                    print(i);
                    print(currentPopup);
                    if(i.getId() == currentPopup.getId()){
                        mActivePopups_.remove(c);
                        break;
                    }
                }
                shutdownPopup_(currentPopup);
            }
            mPopupsForId_[popupData.id] = popupObject;
        }

        popupObject.setZOrder(POPUPS_START_Z);
    }

    function purgeOldPopups_(){
        while(true){
            local idx = mActivePopups_.find(null);
            if(idx == null) return

            mActivePopups_.remove(idx);
        }
    }

    function shutdownPopup_(popup){
        popup.shutdown();
        local id = popup.getId();
        mPopupIdPool_.recycleId(id);
    }

    function update(){
        local popupFinished = false;

        foreach(c,i in mActivePopups_){
            local alive = i.update();
            if(!alive){
                print("Shutting down popup " + c);
                mPopupsForId_[i.getPopupData().id] = null;
                shutdownPopup_(i);
                mActivePopups_[c] = null;
                popupFinished = true;
            }
        }

        if(popupFinished){
            purgeOldPopups_();
        }
    }
};