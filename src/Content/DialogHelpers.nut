
function setQuestValue(questId, valueId, value){

    local quest = ::Base.mQuestManager.getQuestForName(questId);
    if(quest == null){
        throw format("No quest was found for id '%s'", questId);
    }
    quest.setValue(valueId, value);
}

function incrementQuestValue(questId, valueId){

    local quest = ::Base.mQuestManager.getQuestForName(questId);
    if(quest == null){
        throw format("No quest was found for id '%s'", questId);
    }
    local val = quest.readValue(valueId);
    quest.setValue(valueId, val+1);
}

function givePlayerMoney(amount){
    printf("Dialog giving player %i money", amount);

    showItemInfoPopup_(format("You received [MONEY]%i[MONEY] coins!", amount));
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

    showItemInfoPopup_(format("You received [GREEN]%s[GREEN]!", item));

    ::Base.mPlayerStats.mInventory_.addToInventory(::Item(targetItem));
}

function checkPlayerMoney(amount){
    return ::Base.mPlayerStats.mInventory_.getMoney() >= amount ;
}

function checkPlayerFreeInventorySlot(){
    return ::Base.mPlayerStats.mInventory_.hasFreeSlot();
}

function showItemInfoPopup_(text){
    local dialogMetaScanner = ::DialogManager.DialogMetaScanner();
    local outContainer = array(2);
    dialogMetaScanner.getRichText(text, outContainer);
    ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.TOP_RIGHT_OF_SCREEN, {"text": outContainer[0], "richText": outContainer[1]}));
}