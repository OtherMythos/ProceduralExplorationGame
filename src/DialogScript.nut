
function dialogString(dialog, actorId){
    ::Base.mDialogManager.__DString(dialog, actorId);
}

function dialogOption(options){
    ::Base.mDialogManager.__DOption(options);
}

function actorSet(actor){
    ::Base.mDialogManager.notifyActorSet(actor);
}

function actorPush(actor){
    ::Base.mDialogManager.notifyActorPush(actor);
}

function actorPop(){
    ::Base.mDialogManager.notifyActorPop();
}

function dialogBegan(){
    ::Base.mDialogManager.notifyDialogStart();
}

function dialogEnded(){
    ::Base.mDialogManager.notifyDialogEnd();
}

