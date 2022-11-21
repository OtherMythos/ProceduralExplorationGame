::Inventory <- class{
    mInventoryItems_ = null;

    mInventorySize_ = 5;

    constructor(){
        mInventoryItems_ = array(mInventorySize_, Item.NONE);
    }

    /**
     * Add an item to the inventory.
     * @returns true if the item could be added, false if not, for example the inventory is full.
     */
    function addToInventory(item){
        local idx = mInventoryItems_.find(Item.NONE);
        if(idx == null) return false;
        setItemForIdx(item, idx);
        return true;
    }

    function setItemForIdx(item, idx){
        mInventoryItems_[idx] = item;
        contentsChanged();
    }

    function contentsChanged(){
        _event.transmit(Event.INVENTORY_CONTENTS_CHANGED, null);
    }
};