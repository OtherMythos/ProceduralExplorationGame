::Combat <- {
    "EquippedItems": class{
        mItems = null;
        mEquippedStats = null;
        constructor(){
            mItems = array(EquippedSlotTypes.MAX, null);
        }

        function getEquippedItem(item){
            return mItems[item];
        }

        function rawSetItems(items){
            assert(items.len() == mItems.len());
            for(local i = 0; i < items.len(); i++){
                mItems[i] = items[i];
            }
        }

        function setEquipped(item, targetSlot){
            assert(targetSlot != EquippedSlotTypes.HAND);
            //TODO I don't particularly like any of the mismatches between enums.
            //It would be more convenient if everything was re-named an ideally the HAND entry wasn't there.
            local itemRequestEquip = ::Equippables[item.getEquippableData()].mEquippedSlot_;
            if(itemRequestEquip == EquippedSlotTypes.HAND){
                if(targetSlot != EquippedSlotTypes.LEFT_HAND && targetSlot != EquippedSlotTypes.RIGHT_HAND){
                    throw format("Item '%s' requested incorrect equip slot.", targetSlot);
                }
            }
            else{
                //Ensure the item equip type matches.
                if(itemRequestEquip != targetSlot){
                    throw format("Item '%s' requested incorrect equip slot.", targetSlot);
                }
            }
            mItems[targetSlot] = item;
            printf("Succesfully equipped item %s to slot %i", item.tostring(), targetSlot);
        }

        function unEquipItem(targetSlot){
            assert(targetSlot != EquippedSlotTypes.HAND);
            mItems[targetSlot] = null;
            printf("Succesfully unequipped item at slot %i", targetSlot);
        }

        function getTotalStats(){
            local stats = ::StatsEntry();

            return stats;
        }

        function calculateEquippedStats(){
            if(mEquippedStats == null){
                mEquippedStats = StatsEntry();
            }
            mEquippedStats.clear();

            foreach(i in mItems){
                if(i == null) continue;
                local newStats = i.toStats();
                mEquippedStats += newStats;
            }
        }

        function _tostring(){
            return ::wrapToString(::Combat.EquippedItems, "EquippedItems", _prettyPrint(mItems));
        }
    },

    /**
     * CombatStats for a single combat actor, for instance an opponent or the player.
     */
    "CombatStats": class{
        mHealth = 10;
        mMaxHealth = 10;
        mEnemyType = EnemyId.NONE;
        mEquippedItems = null;
        mWieldActive = false;

        mDead = false;

        constructor(enemyType = EnemyId.NONE, health = 10, equippedItems = null){
            mHealth = mMaxHealth = health;
            mEnemyType = enemyType;
            if(equippedItems == null){
                mEquippedItems = ::Combat.EquippedItems();
            }else{
                mEquippedItems = equippedItems;
            }
        }

        function setWieldActive(active){
            mWieldActive = active;
        }

        function getHealthPercentage(){
            return mHealth.tofloat() / mMaxHealth.tofloat();
        }

        function alterHealth(amount){
            setHealth(mHealth + amount);
        }

        function setHealth(health){
            mHealth = health;
            if(mHealth <= 0){
                mHealth = 0;
                mDead = true;
            }else{
                mDead = false;
            }
            if(mHealth > mMaxHealth){
                mHealth = mMaxHealth;
            }
        }
        function setHealthToMax(){
            printf("Setting health to %i", mMaxHealth);
            setHealth(mMaxHealth);
        }
        function calculateEquippedStats(){
            mEquippedItems.calculateEquippedStats();
        }
    },

    /**
     * Contains a definition of an attacking move, for instance damage amount, status afflictions, etc.
     */
    "CombatMove": class{
        mDamage = 0;
        mStatusAffliction = null;
        mStatusAfflictionLifetime = null;

        constructor(damage, statusAffliction=null, statusAfflictionLifetime=null){
            mDamage = damage;
            mStatusAffliction = statusAffliction;
            mStatusAfflictionLifetime = statusAfflictionLifetime;
        }

        function getDamage(){
            return mDamage;
        }

        function performOnEntity(entityId, world){
            //Do this first incase damage invalidates the entity.
            if(mStatusAffliction != null){
                world.applyStatusAffliction(entityId, mStatusAffliction, mStatusAfflictionLifetime);
            }
            if(mDamage != null){
                _applyDamageOther(world.getEntityManager(), entityId, mDamage);
            }
        }
    }
};