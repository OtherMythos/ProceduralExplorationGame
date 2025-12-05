::Inventory <- class{
    mInventoryItems_ = null;
    mMoney_ = 0;

    mInventorySize_ = 35;
    mInventoryType_ = null;

    constructor(inventoryType = InventoryType.INVENTORY){
        local items = array(mInventorySize_, null);

        rawSetItems(items);
        mInventoryType_ = inventoryType;
    }

    //Set the initial items, not transmitting events upon change.
    function rawSetItems(items){
        mInventoryItems_ = clone items;
    }

    /**
     * Add an item to the inventory.
     * @returns true if the item could be added, false if not, for example the inventory is full.
     */
    function addToInventory(item){
        local idx = mInventoryItems_.find(null);
        if(idx == null) return false;
        setItemForIdx(item, idx);
        return true;
    }

    /**
     * Remove an item from the inventory based on slot idx.
     * Pass expected type as well to perform a check that the index provided contains the expected ItemId.
     */
    function removeFromInventory(slotIdx, expectedType = null){
        assert(slotIdx >= 0 && slotIdx < mInventoryItems_.len());
        if(expectedType != null){
            assert(mInventoryItems_[slotIdx] == expectedType);
        }
        setItemForIdx(null, slotIdx);
    }

    function setItemForIdx(item, idx){
        mInventoryItems_[idx] = item;
        printf("Inventory setting item %s to idx %i", item == null ? "null" : item.tostring(), idx);
        contentsChanged();
    }

    function getItemForIdx(idx){
        return mInventoryItems_[idx];
    }

    function contentsChanged(){
        local eventType = (mInventoryType_ == InventoryType.STORAGE) ? Event.STORAGE_CONTENTS_CHANGED : Event.INVENTORY_CONTENTS_CHANGED;
        _event.transmit(eventType, mInventoryItems_);
    }

    function addMoney(money){
        changeMoney(money);
    }
    function changeMoney(change, triggerEvent=true){
        local oldMoney = mMoney_;
        mMoney_ += change;
        if(mMoney_ < 0) mMoney_ = 0;
        print(format("Changing money by %i from %i, new is %i", change, oldMoney, mMoney_));
        if(triggerEvent){
            _event.transmit(Event.MONEY_CHANGED, mMoney_);
        }
    }
    function setMoney(money){
        mMoney_ = money;
        _event.transmit(Event.MONEY_CHANGED, mMoney_);
    }

    function getNumSlotsFree(){
        local num = 0;
        foreach(i in mInventoryItems_){
            if(i == null) num++;
        }
        return num;
    }

    function hasFreeSlot(){
        return getNumSlotsFree() > 0;
    }

    function getInventorySize(){
        return mInventorySize_;
    }

    function getMoney(){
        return mMoney_;
    }
};