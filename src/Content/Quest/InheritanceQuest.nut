//A quest where the player gets given some money for free, but ideally returns it.

enum QuestValue_InheritanceQuest{
    MONEY_CLAIMED,

    MAX
};
::InheritanceQuest <- class extends ::Quest{

    constructor(){
        base.constructor("Inheritance", QuestValue_InheritanceQuest.MAX);
    }

    function setup(){
        local metaEntry = registerEntry("meta");

        registerValue(QuestValue_InheritanceQuest.MONEY_CLAIMED, "moneyClaimed", metaEntry, 1, 0);
    }

}

local inheritanceQuest = InheritanceQuest();
::Base.mQuestManager.registerQuest(inheritanceQuest);