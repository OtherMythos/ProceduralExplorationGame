::Inventory <- class{
    mInventoryItems_ = null;
    mMoney_ = 300;

    mInventorySize_ = 5;

    constructor(){
        mInventoryItems_ = array(mInventorySize_, Item.NONE);

        mInventoryItems_[0] = Item.HEALTH_POTION;
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

    /**
     * Remove an item from the inventory based on slot idx.
     * Pass expected type as well to perform a check that the index provided contains the expected item.
     */
    function removeFromInventory(slotIdx, expectedType = Item.NONE){
        assert(slotIdx >= 0 && slotIdx < mInventoryItems_.len());
        if(expectedType != Item.NONE){
            assert(mInventoryItems_[slotIdx] == expectedType);
        }
        setItemForIdx(Item.NONE, slotIdx);
    }

    function setItemForIdx(item, idx){
        mInventoryItems_[idx] = item;
        contentsChanged();
    }

    function getItemForIdx(idx){
        return mInventoryItems_[idx];
    }

    function contentsChanged(){
        _event.transmit(Event.INVENTORY_CONTENTS_CHANGED, null);
    }

    function addMoney(money){
        print(format("Adding %i to %i money, new is %i", money, mMoney_, mMoney_+money));
        mMoney_ += money;
        _event.transmit(Event.MONEY_CHANGED, mMoney_);
    }

    function getMoney(){
        return mMoney_;
    }
};