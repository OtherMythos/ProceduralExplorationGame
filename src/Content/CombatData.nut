::Combat <- {
    "EquippedItems": class{
        mItems = null;
        constructor(){
            mItems = array(EquippedSlotTypes.MAX, null);
        }

        function setEquipped(item, slot){
            mItems[slot] = item;
        }

        function getTotalStats(){
            local stats = ::ItemHelper.ItemStat();
            foreach(i in mItems){
                if(i == null) continue;
                local newStats = i.toStats();
                stats += newStats;
            }

            return stats;
        }
    },

    /**
     * CombatStats for a single combat actor, for instance an opponent or the player.
     */
    "CombatStats": class{
        mHealth = 10;
        mMaxHealth = 10;
        mEnemyType = Enemy.NONE;
        mEquippedItems = null;

        mDead = false;

        constructor(enemyType = Enemy.NONE, health = 10, equippedItems = null){
            mHealth = mMaxHealth = health;
            mEnemyType = enemyType;
            if(equippedItems == null){
                mEquippedItems = ::Combat.EquippedItems();
            }
        }

        function alterHealthWithMove(move, dealerStats = null){
            //Here, apply damage based on the equipped.
            //Take both the recipient and dealer's equipped items into account.
            local moveDamage = move.getDamage();

            local dealerEquipped = dealerStats.mEquippedItems.getTotalStats();
            local equipped = mEquippedItems.getTotalStats();

            moveDamage -= dealerEquipped.mAttack;
            moveDamage += equipped.mDefense;
            print("Final damage in move: " + moveDamage);
            alterHealth(moveDamage);
        }

        function alterHealth(amount){
            setHealth(mHealth + amount);
        }

        function setHealth(health){
            mHealth = health;
            if(mHealth <= 0){
                mHealth = 0;
                mDead = true;
            }
            if(mHealth > mMaxHealth){
                mHealth = mMaxHealth;
            }
        }
    },

    /**
     * Contains a definition of an attacking move, for instance damage amount, status afflictions, etc.
     */
    "CombatMove": class{
        mDamage = 0;

        constructor(damage){
            mDamage = damage;
        }

        function getDamage(){
            return mDamage;
        }
    },

    /**
     * Encapsulates all the data needed for an individual combat scene.
     * This includes, the player's stats, enemy stats, any other combat attributes which might effect the combat outcome.
     */
    "CombatData": class{
        mPlayerStats = null;
        mOpponentStats = null;

        mCombatSpoils = null;
        mSpoilsAvailable = false;

        constructor(playerStats, opponentStats){
            mPlayerStats = playerStats;
            mOpponentStats = opponentStats;
            mCombatSpoils = array(4, null);
        }

        function resetSpoils(){
            for(local i = 0; i < mCombatSpoils.len(); i++){
                mCombatSpoils[i] = null;
            }
            mSpoilsAvailable = false;
        }

        function setSpoilForIdx(spoil, idx){
            mCombatSpoils[idx] = spoil;
            mSpoilsAvailable = true;
        }

        function getNumOpponents(){
            return mOpponentStats.len();
        }

        function getNumAliveOpponents(){
            local count = 0;
            foreach(i in mOpponentStats){
                if(!i.mDead) count++;
            }
            return count;
        }

        function performAttackOnOpponent(damage, opponentId){
            local stats = mOpponentStats[opponentId];
            return _performAttackOnStats(damage, stats, mPlayerStats);
        }

        function performAttackOnPlayer(damage, opponentId){
            local stats = mOpponentStats[opponentId];
            return _performAttackOnStats(damage, mPlayerStats, stats);
        }

        function _performAttackOnStats(damage, stats, dealerStats){
            local dead = stats.mDead;
            stats.alterHealthWithMove(damage, dealerStats);

            //The opponent died as a result of this attack.
            return (dead != stats.mDead);
        }
    }
};