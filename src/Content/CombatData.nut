::Combat <- {
    "CombatStats": class{
        mHealth = 10;

        constructor(){

        }
    },

    "CombatData": class{
        mCombatStats = null;

        constructor(combatStats){
            mCombatStats = combatStats;
        }
    }
};