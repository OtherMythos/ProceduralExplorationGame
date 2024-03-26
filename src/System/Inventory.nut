::Inventory <- class{
    mInventoryItems_ = null;
    mMoney_ = 0;

    mInventorySize_ = 35;

    constructor(){
        local items = array(mInventorySize_, null);

        items[0] = ::Item(ItemId.HEALTH_POTION);
        items[1] = ::Item(ItemId.LARGE_HEALTH_POTION);
        for(local i = 0; i < 20; i++){
            items[i] = ::Item(i %2 == 0 ? ItemId.LARGE_HEALTH_POTION : ItemId.HEALTH_POTION);
        }
        items[0] = ::Item(ItemId.SIMPLE_SWORD);
        items[10] = ::Item(ItemId.SIMPLE_SWORD);
        items[11] = ::Item(ItemId.SIMPLE_SHIELD);
        items[12] = ::Item(ItemId.SIMPLE_SHIELD);
        items[13] = ::Item(ItemId.SIMPLE_TWO_HANDED_SWORD);

        rawSetItems(items);
    }

    //Set the initial items, not transmitting events upon change.
    function rawSetItems(items){
        mInventoryItems_ = items;
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
        _event.transmit(Event.INVENTORY_CONTENTS_CHANGED, mInventoryItems_);
    }

    function addMoney(money){
        print(format("Adding %i to %i money, new is %i", money, mMoney_, mMoney_+money));
        mMoney_ += money;
        _event.transmit(Event.MONEY_CHANGED, mMoney_);
    }

    function getNumSlotsFree(){
        local num = 0;
        foreach(i in mInventoryItems_){
            if(i == null) num++;
        }
        return num;
    }

    function getInventorySize(){
        return mInventorySize_;
    }

    function getMoney(){
        return mMoney_;
    }
};