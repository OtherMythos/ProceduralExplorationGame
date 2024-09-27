
function setQuestValue(questId, valueId, value){

    local quest = ::Base.mQuestManager.getQuestForName(questId);
    if(quest == null){
        throw format("No quest was found for id '%s'", questId);
    }
    quest.setValue(valueId, value);
}

function givePlayerMoney(amount){
    printf("Dialog giving player %i money", amount);
    ::Base.mPlayerStats.mInventory_.addMoney(amount);
}

function changePlayerMoney(amount){
    printf("Dialog changing player money by %i", amount);
    ::Base.mPlayerStats.mInventory_.changeMoney(amount);
}

function givePlayerItem(item){
    local targetItem = ::ItemHelper.nameToItemId(item);
    if(targetItem == ItemId.NONE){
        printf("Could not find an item for name '%s'", item);
        return;
    }
    printf("Giving player item '%s' of id %i", item, targetItem);
    ::Base.mPlayerStats.mInventory_.addToInventory(::Item(targetItem));
}

function checkPlayerMoney(amount){
    return ::Base.mPlayerStats.mInventory_.getMoney() >= amount ;
}

function checkPlayerFreeInventorySlot(){
    return ::Base.mPlayerStats.mInventory_.hasFreeSlot();
}