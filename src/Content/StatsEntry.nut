/**
 * Entry containing information relating to gameplay stats.
 * These are generally stats relating to the combat system, but are also used by items, descriptions for levels, etc.
 */
::StatsEntry <- class{
    mRestorativeHealth = 0;
    mAttack = 1;
    mDefense = 1;
    mSellValue = 0;
    mScrapValue = 0;

    constructor(){
        clear();
    }

    function _tostring(){
        local t = format("{restorativeHealth: %i, attack: %i, defense: %i, sellValue: %i, scrapValue: %i}", mRestorativeHealth, mAttack, mDefense, mSellValue, mScrapValue);
        return ::wrapToString(::FoundObject, "ItemStat", t);
    }

    function clear(){
        mRestorativeHealth = 0;
        mAttack = 1;
        mDefense = 1;
        mSellValue = 0;
        mScrapValue = 0;
    }

    function hasStatType(stat){
        switch(stat){
            case StatType.RESTORATIVE_HEALTH: return mRestorativeHealth != 0;
            case StatType.ATTACK: return mAttack > 1;
            case StatType.DEFENSE: return mDefense > 1;
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
                if(mRestorativeHealth < 0){
                    return format("%s Reduces health by %i.", UNICODE_HEART, -mRestorativeHealth);
                }
                return format("%s Restores %i health.", UNICODE_HEART, mRestorativeHealth);
            }
            case StatType.ATTACK:{
                return format("%s Increases attack by %i.", UNICODE_ATTACK_UP, mAttack);
            }
            case StatType.DEFENSE:{
                return format("%s Increases defense by %i.", UNICODE_ATTACK_UP, mDefense);
            }
            default:
                assert(false);
        }
    }

    function getDescriptionForValue(){
        local desc = "";
        if(mSellValue > 0){
            desc += format("%s Sell: %i", UNICODE_COINS, mSellValue);
        }
        if(mScrapValue > 0){
            if(desc.len() > 0) desc += " ";
            desc += format("%s Scrap: %i", UNICODE_COINS, mScrapValue);
        }
        return desc;
    }

    function getColourForStat(stat){
        local statColour = ::ItemHelper.coloursForStats[stat];
        return statColour;
    }

    function getDescriptionWithRichText(hideValueInfo = false){
        local outString = "";
        local outRichText = [];
        for(local i = 0; i < StatType.MAX; i++){
            if(!hasStatType(i)) continue;
            print(getDescriptionForStat(i));
            local appendString = getDescriptionForStat(i) + "\n";

            local colour = getColourForStat(i);
            outRichText.append({"offset": outString.len(), "len": appendString.len(), "col": colour, "font": 6});
            outString += appendString;
        }

        //Add value information if present
        if(!hideValueInfo){
            local valueDesc = getDescriptionForValue();
            if(valueDesc.len() > 0){
                local appendString = valueDesc + "\n";
                local goldColour = ColourValue(1.0, 0.84, 0.0, 1.0);
                outRichText.append({"offset": outString.len(), "len": appendString.len(), "col": goldColour, "font": 6});
                outString += appendString;
            }
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
        mSellValue += stat.mSellValue;
        mScrapValue += stat.mScrapValue;

        return this;
    }

};