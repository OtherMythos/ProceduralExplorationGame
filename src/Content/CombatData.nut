::Combat <- {
    "EquippedItems": class{
        mItems = null;
        constructor(){
            mItems = array(EquippedSlotTypes.MAX, null);
        }

        function setEquipped(item, slot){
            mItems[slot] = item;
        }
    },

    /**
     * CombatStats for a single combat actor, for instance an opponent or the player.
     */
    "CombatStats": class{
        mHealth = 10;
        mEnemyType = Enemy.NONE;
        mEquippedItems = null;

        mDead = false;

        constructor(enemyType = Enemy.NONE, health = 10, equippedItems = null){
            mHealth = health;
            mEnemyType = enemyType;
            if(equippedItems == null){
                mEquippedItems = ::Combat.EquippedItems();
            }
        }

        function alterHealthWithMove(move){
            alterHealth(move.getDamage());
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

        constructor(playerStats, opponentStats){
            mPlayerStats = playerStats;
            mOpponentStats = opponentStats;
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
            return _performAttackOnStats(damage, stats);
        }

        function performAttackOnPlayer(damage){
            return _performAttackOnStats(damage, mPlayerStats);
        }

        function _performAttackOnStats(damage, stats){
            local dead = stats.mDead;
            stats.alterHealthWithMove(damage);

            //The opponent died as a result of this attack.
            return (dead != stats.mDead);
        }
    }
};