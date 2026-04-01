::DialogManager <- class{

    mCurrentScript_ = null;
    mDialogMetaScanner_ = null;
    mActorStack_ = null;
    mLastSetActor_ = null;
    mActorNames_ = null;

    constructor(){
        mDialogMetaScanner_ = DialogMetaScanner();
        mActorStack_ = [];
        mLastSetActor_ = null;
        mActorNames_ = {};
    }

    function beginExecuting(path, targetBlock = 0){
        try{
            mCurrentScript_ = _dialogSystem.compileDialog(path);
        }catch(e){
            error(e);
            return;
        }

        _dialogSystem.executeCompiledDialog(mCurrentScript_, targetBlock);
        buildActorNames_();
    }

    function _ensureDialogScreenAtLayer(idx = 2){
        if(::ScreenManager.getScreenIdForLayer(idx) != Screen.DIALOG_SCREEN){
            ::ScreenManager.transitionToScreen(Screen.DIALOG_SCREEN, null, idx);
            _event.transmit(Event.DIALOG_META, { "started": true });
        }
    }

    function __DString(dialog, actorId){
        _ensureDialogScreenAtLayer();
        print(dialog)
        local outContainer = array(2);
        local containsRichText = mDialogMetaScanner_.getRichText(dialog, outContainer);
        if(containsRichText){
            _event.transmit(Event.DIALOG_SPOKEN, outContainer);
        }else{
            _event.transmit(Event.DIALOG_SPOKEN, dialog);
        }
    }

    function __DOption(options){
        _ensureDialogScreenAtLayer();
        _event.transmit(Event.DIALOG_OPTION, options);
    }


    function notifyActorSet(actor){
        // Clear stack and set only this actor
        mActorStack_.clear();
        mActorStack_.append(actor);
        mLastSetActor_ = actor;
        _event.transmit(Event.DIALOG_META, { "actorSet": actor });
    }

    function notifyActorPush(actor){
        mActorStack_.append(actor);
        _event.transmit(Event.DIALOG_META, { "actorSet": actor });
    }

    function notifyActorPop(){
        if(mActorStack_.len() > 0){
            mActorStack_.pop();
        }
        local newActor = null;
        if(mActorStack_.len() > 0){
            newActor = mActorStack_[mActorStack_.len() - 1];
        }else{
            newActor = mLastSetActor_;
        }
        _event.transmit(Event.DIALOG_META, { "actorSet": newActor });
    }

    function notifyDialogStart(){
        mActorStack_.clear();
        _ensureDialogScreenAtLayer();
        _event.transmit(Event.DIALOG_META, { "started": true });
    }

    function buildActorNames_(){
        mActorNames_ = {};
        local keys = _dialogSystem.registry.getKeys();
        foreach(key in keys){
            if(key.len() > 2 && key.slice(0, 2) == "a."){
                local suffix = key.slice(2);
                local actorId = _dialogSystem.registry.get(key);
                local name = _dialogSystem.registry.get("n." + suffix);
                if(name != null){
                    mActorNames_[actorId] <- name;
                }
            }
        }
    }

    function getActorName(actorId){
        if(actorId in mActorNames_){
            return mActorNames_[actorId];
        }
        return null;
    }

    function notifyDialogEnd(){
        _event.transmit(Event.DIALOG_META, { "ended": true });
        //::ScreenManager.transitionToScreen(null, null, 2);
        ::Base.mExplorationLogic.notifyDialogEnded();
        mActorStack_.clear();
        mActorNames_ = {};
    }

    function notifyProgress(){
        _dialogSystem.unblock();
    }

    function notifyOption(optionId){
        _dialogSystem.specifyOption(optionId);
    }
};