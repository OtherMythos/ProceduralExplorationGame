
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

function triggerInventoryForItems(){
    local data = {
        "multiSelection": true,
        "stats": ::Base.mPlayerStats
    };
    //TODO fix the action set popping problem by not overriding dialog with the inventory screen.
    ::Base.mExplorationLogic.mCurrentWorld_.showInventory(data, 2);
}

function showItemInfoPopup_(text){
    local dialogMetaScanner = ::DialogManager.DialogMetaScanner();
    local outContainer = array(2);
    dialogMetaScanner.getRichText(text, outContainer);
    ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.TOP_RIGHT_OF_SCREEN, {"text": outContainer[0], "richText": outContainer[1]}));
}

class InventorySelectionWaiter{
    mEventReceived_ = false;
    mItems_ = null;

    constructor(){
        _event.subscribe(Event.INVENTORY_SELECTION_FINISHED, receiveSelectionFinished, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.INVENTORY_SELECTION_FINISHED, receiveSelectionFinished, this);
    }

    function receiveSelectionFinished(id, data){
        this.mEventReceived_ = true;
        this.mItems_ = data;
    }

    function checkEventReceived(){
        return mEventReceived_;
    }

    function getItems(){
        return mItems_;
    }

    function reset(){
        mEventReceived_ = false;
        mItems_ = null;
    }
}

::gInventorySelectionWaiter_ <- null;

function checkForInventoryItems(){
    print("Checking for inventory items");
    if(gInventorySelectionWaiter_ == null){
        gInventorySelectionWaiter_ = InventorySelectionWaiter();
    }

    if(gInventorySelectionWaiter_.checkEventReceived()){
        //local items = gInventorySelectionWaiter_.getItems();
        //gInventorySelectionWaiter_.reset();
        gInventorySelectionWaiter_.shutdown();
        print("Received inventory items");
        return true;
    }

    return false;
}