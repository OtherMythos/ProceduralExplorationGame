::QuestManager <- class{

    mQuests_ = null;
    mQuestLookups_ = null;

    constructor(){
        mQuests_ = [];
        mQuestLookups_ = {};
    }

    function registerQuest(quest){
        local name = quest.getName();
        if(mQuestLookups_.rawin(name)) throw format("Quest with name %s already exists.", name);
        local id = mQuests_.len();
        mQuests_.append(quest);
        mQuestLookups_.rawset(name, id);
    }

    function getQuestForName(name){
        if(!mQuestLookups_.rawin(name)) return null;

        return mQuests_[mQuestLookups_.rawget(name)];
    }

    function getTableForQuests(){
        local outTable = {};

        foreach(i in mQuests_){
            local d = i.getTable();
            outTable.rawset(i.getName(), d);
        }

        return outTable;
    }

};