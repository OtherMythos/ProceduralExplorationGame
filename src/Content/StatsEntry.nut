/**
 * Entry containing information relating to gameplay stats.
 * These are generally stats relating to the combat system, but are also used by items, descriptions for levels, etc.
 */
::StatsEntry <- class{
    mRestorativeHealth = 0;
    mAttack = 0;
    mDefense = 0;

    function _tostring(){
        local t = format("{restorativeHealth: %i, attack: %i, defense: %i}", mRestorativeHealth, mAttack, mDefense);
        return ::wrapToString(::FoundObject, "ItemStat", t);
    }

    function hasStatType(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH: return mRestorativeHealth != 0;
            case StatType.ATTACK: return mAttack != 0;
            case StatType.DEFENSE: return mDefense != 0;
            default:
                assert(false);
        }
    }

    function getStatType(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH: return mRestorativeHealth;
            case StatType.ATTACK: return mAttack;
            case StatType.DEFENSE: return mDefense;
            default:
                assert(false);
        }
    }

    function getDescriptionForStat(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH:{
                return format("Restores %i health.", mRestorativeHealth);
            }
            case StatType.ATTACK:{
                return format("Increases attack by %i.", mAttack);
            }
            case StatType.DEFENSE:{
                return format("Increases defense by %i.", mDefense);
            }
            default:
                assert(false);
        }
    }

    function getColourForStat(stat){
        local statColour = ::ItemHelper.coloursForStats[stat];
        return statColour;
    }

    function getDescriptionWithRichText(){
        local outString = "";
        local outRichText = [];
        for(local i = 0; i < StatType.MAX; i++){
            if(!hasStatType(i)) continue;
            print(getDescriptionForStat(i));
            local appendString = getDescriptionForStat(i) + "\n";

            local colour = getColourForStat(i);
            outRichText.append({"offset": outString.len(), "len": appendString.len(), "col": colour});
            outString += appendString;
        }

        return [outString, outRichText];
    }

    /**
    * Add an item stat's values to this.
    */
    function _add(stat){
        mRestorativeHealth += stat.mRestorativeHealth;
        mAttack += stat.mAttack;
        mDefense += stat.mDefense;

        return this;
    }

};