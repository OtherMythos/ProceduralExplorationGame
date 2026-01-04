function checkItemsAreNull(){
    local items = gInventorySelectionWaiter_.getItems();
    return items == null;
}

function giveItems(){
    local items = gInventorySelectionWaiter_.getItems();
    getroottable().rawdelete("gInventorySelectionWaiter_");
    ::ItemHelper.removeItemsFromInventory(items);

    local totalScrapValue = 0;
    foreach(itemData in items.items){
        local item = itemData.item;
        totalScrapValue += item.getScrapVal();
    }

    return totalScrapValue > 20;
}