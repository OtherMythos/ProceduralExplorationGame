
function setQuestValue(questId, valueId, value){

    local quest = ::Base.mQuestManager.getQuestForName(questId);
    if(quest == null){
        throw format("No quest was found for id '%s'", questId);
    }
    quest.setValue(valueId, value);
}

function givePlayerMoney(amount){
    printf("Giving player %i money", amount);
    ::Base.mPlayerStats.mInventory_.addMoney(amount);
}