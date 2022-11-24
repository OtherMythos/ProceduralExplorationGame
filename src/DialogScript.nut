
function dialogString(dialog, actorId){
    ::Base.mDialogManager.__DString(dialog, actorId);
}

function dialogOption(options){
    ::Base.mDialogManager.__DOption(options);
}

function dialogBegan(){
    ::Base.mDialogManager.notifyDialogStart();
}

function dialogEnded(){
    ::Base.mDialogManager.notifyDialogEnd();
}

