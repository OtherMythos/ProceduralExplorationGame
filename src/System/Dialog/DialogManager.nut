::DialogManager <- class{
    mCurrentScript_ = null;

    mDialogMetaScanner_ = null;

    constructor(){
        mDialogMetaScanner_ = DialogMetaScanner();
    }

    function beginExecuting(path, targetBlock = 0){
        try{
            mCurrentScript_ = _dialogSystem.compileDialog(path);
        }catch(e){
            error(e);
            return;
        }

        _dialogSystem.executeCompiledDialog(mCurrentScript_, targetBlock);
    }

    function __DString(dialog, actorId){
        local outContainer = array(2);
        local containsRichText = mDialogMetaScanner_.getRichText(dialog, outContainer);
        if(containsRichText){
            _event.transmit(Event.DIALOG_SPOKEN, outContainer);
        }else{
            _event.transmit(Event.DIALOG_SPOKEN, dialog);
        }
    }

    function __DOption(options){
        _event.transmit(Event.DIALOG_OPTION, options);
    }

    function notifyDialogStart(){
        ::ScreenManager.transitionToScreen(Screen.DIALOG_SCREEN, null, 2);
        _event.transmit(Event.DIALOG_META, { "started": true });
    }

    function notifyDialogEnd(){
        _event.transmit(Event.DIALOG_META, { "ended": true });
        ::ScreenManager.transitionToScreen(null, null, 2);
        ::Base.mExplorationLogic.notifyDialogEnded();
    }

    function notifyProgress(){
        _dialogSystem.unblock();
    }

    function notifyOption(optionId){
        _dialogSystem.specifyOption(optionId);
    }
};