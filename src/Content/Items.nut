::Items <- {

    function itemToStats(item){
        local stat = ItemStat();

        switch(item){
            case Item.NONE: return ItemStat();
            case Item.HEALTH_POTION: {
                stat.mRestorativeHealth = 10;
                return stat;
            }
            case Item.SIMPLE_SWORD: {
                stat.mAttack = 5;
                return stat;
            }
            case Item.SIMPLE_SHIELD: {
                stat.mDefense = 5;
                return stat;
            }
            default:
                assert(false);
        }

        return stat;
    }

    function actuateItem(item){
        switch(item){
            case Item.HEALTH_POTION:{
                ::Base.mPlayerStats.alterPlayerHealth(10);
                break;
            }
            default:{
                assert(false);
            }
        }
    }

    function itemToName(item){
        switch(item){
            case Item.NONE: return ItemNames.NONE;
            case Item.HEALTH_POTION: return ItemNames.HEALTH_POTION;
            case Item.SIMPLE_SWORD: return ItemNames.SIMPLE_SWORD;
            case Item.SIMPLE_SHIELD: return ItemNames.SIMPLE_SHIELD;
            default:
                assert(false);
        }
    }

    function enemyToName(enemy){
        switch(enemy){
            case Enemy.NONE: return EnemyNames.NONE;
            case Enemy.GOBLIN: return EnemyNames.GOBLIN;
            default:
                assert(false);
        }
    }

    function itemToDescription(item){
        switch(item){
            case Item.NONE: return "None";
            case Item.HEALTH_POTION: return "A potion of health. Bubbles gently inside a cast glass flask.";
            case Item.SIMPLE_SWORD: return "A cheap, weak sword. Relatively blunt for something claiming to be a sword.";
            case Item.SIMPLE_SHIELD: return "An un-interesting shield. Provides minimal protection.";
            default:
                assert(false);
        }
    }

    function getScrapValueForItem(item){
        switch(item){
            case Item.NONE: return 0;
            case Item.HEALTH_POTION: return 5;
            case Item.SIMPLE_SWORD: return 5;
            case Item.SIMPLE_SHIELD: return 5;
            default:
                assert(false);
        }
    }
};

/**
 * Store item stats as a class rather than creating a new table each time.
 * This should save the strings to identify the entries from being created each time like would happen in a table.
 */
::Items.ItemStat <- class{
    mRestorativeHealth = 0;
    mAttack = 0;
    mDefense = 0;

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
                return format("  Restores %i health.", mRestorativeHealth);
            }
            case StatType.ATTACK:{
                return format("  Increases attack by %i.", mAttack);
            }
            case StatType.DEFENSE:{
                return format("  Increases defense by %i.", mDefense);
            }
            default:
                assert(false);
        }
    }
};