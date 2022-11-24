::DialogManager <- class{
    mCurrentScript_ = null;

    constructor(){

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
        print(dialog);
    }

    function __DOption(options){

    }

    function notifyDialogStart(){

    }

    function notifyDialogEnd(){

    }

    function notifyProgress(){
        _dialogSystem.unblock();
    }

    function notifyOption(optionId){
        _dialogSystem.specifyOption(optionId);
    }
};