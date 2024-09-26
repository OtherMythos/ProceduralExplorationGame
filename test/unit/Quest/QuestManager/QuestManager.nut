
enum QuestValue_TestQuest{
    FIRST,
    SECOND,
    THIRD,
    FOURTH,

    MAX
};
enum QuestValue_TestQuestMultiEntry{
    METAFIRST_FIRST,
    METAFIRST_SECOND,
    METAFIRST_THIRD,
    METAFIRST_FOURTH,

    METASECOND_FIRST,
    METASECOND_SECOND,
    METASECOND_THIRD,
    METASECOND_FOURTH,

    MAX
};
::TestQuest <- class extends ::Quest{

    constructor(){
        base.constructor("TestQuest", QuestValue_TestQuest.MAX);
    }

    function setup(){
        local metaEntry = registerEntry("meta");

        //Register the values for the specific entries in the quest file.
        registerValue(QuestValue_TestQuest.FIRST, "first", metaEntry, 1, 0);
        registerValue(QuestValue_TestQuest.SECOND, "second", metaEntry, 1, 1);
        registerValue(QuestValue_TestQuest.THIRD, "third", metaEntry, 4, 2);
        registerValue(QuestValue_TestQuest.FOURTH, "fourth", metaEntry, 2, 6);
    }

}
::TestQuestMultiEntry <- class extends ::Quest{

    constructor(){
        base.constructor("TestQuestMultiEntry", QuestValue_TestQuestMultiEntry.MAX);
    }

    function setup(){
        local metaFirstEntry = registerEntry("metaFirst");
        local metaSecondEntry = registerEntry("metaSecond");

        //Register the values for the specific entries in the quest file.
        registerValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST, "metafirst_first", metaFirstEntry, 1, 0);
        registerValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND, "metafirst_second", metaFirstEntry, 1, 1);
        registerValue(QuestValue_TestQuestMultiEntry.METAFIRST_THIRD, "metafirst_third", metaFirstEntry, 4, 2);
        registerValue(QuestValue_TestQuestMultiEntry.METAFIRST_FOURTH, "metafirst_fourth", metaFirstEntry, 2, 6);

        registerValue(QuestValue_TestQuestMultiEntry.METASECOND_FIRST, "metasecond_first", metaSecondEntry, 1, 0);
        registerValue(QuestValue_TestQuestMultiEntry.METASECOND_SECOND, "metasecond_second", metaSecondEntry, 1, 1);
        registerValue(QuestValue_TestQuestMultiEntry.METASECOND_THIRD, "metasecond_third", metaSecondEntry, 4, 2);
        registerValue(QuestValue_TestQuestMultiEntry.METASECOND_FOURTH, "metasecond_fourth", metaSecondEntry, 2, 6);
    }

}

_t("checkQuestRegister", "Check that quests can be setup and registered", function(){
    local questManager = ::QuestManager();

    questManager.registerQuest(Quest("first"));
    questManager.registerQuest(Quest("second"));

    _test.assertEqual(questManager.mQuests_.len(), 2);
    _test.assertEqual(questManager.mQuestLookups_.len(), 2);

    {
        local firstQuest = questManager.getQuestForName("first");
        _test.assertEqual(firstQuest.getName(), "first");

        local secondQuest = questManager.getQuestForName("second");
        _test.assertEqual(secondQuest.getName(), "second");
    }
});

//TODO move these into a test just to check Quest objects, when there's enough code mass to test.
_t("createBasicQuestEntriesAndValues", "Create a simple quest and check entries and values are populated correctly", function(){
    local questEntry = TestQuest();

    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.FIRST), 0);
    questEntry.setValue(QuestValue_TestQuest.FIRST, 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.FIRST), 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.SECOND), 0);

    //If we were to write a value greater than the value's size it should be clamped.
    questEntry.setValue(QuestValue_TestQuest.FIRST, 2);
    //Check there has been no spill over into the next value.
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.SECOND), 0);
    questEntry.setValue(QuestValue_TestQuest.FIRST, 100);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.SECOND), 0);

    //Do the same for a value that needs shifting.
    questEntry.setValue(QuestValue_TestQuest.SECOND, 100);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.THIRD), 0);
    questEntry.setValue(QuestValue_TestQuest.SECOND, 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.THIRD), 0);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.SECOND), 1);

    //Big number for multi-bit entry.
    questEntry.setValue(QuestValue_TestQuest.THIRD, 0xFF);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.THIRD), (1<<4)-1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuest.FOURTH), 0);
});

_t("readWriteBooleanValues", "Check boolean values can be read and written by the quest system", function(){
    local questEntry = TestQuest();

    //Use assertEqual to prevent 1 resolting to success.
    _test.assertEqual(questEntry.readBoolean(QuestValue_TestQuest.FIRST), false);
    questEntry.setBoolean(QuestValue_TestQuest.FIRST, true);
    _test.assertEqual(questEntry.readBoolean(QuestValue_TestQuest.FIRST), true);
    _test.assertEqual(questEntry.readBoolean(QuestValue_TestQuest.SECOND), false);
    questEntry.setBoolean(QuestValue_TestQuest.SECOND, true);
    _test.assertEqual(questEntry.readBoolean(QuestValue_TestQuest.SECOND), true);

    local failed = false;
    try{
        questEntry.setBoolean(QuestValue_TestQuest.THIRD);
    }catch(e){
        failed = true;
    }
    _test.assertTrue(failed);
});

_t("createBasicQuestEntriesAndValuesForMultiEntries", "Create a simple quest and check entries and values are populated correctly, this time using the multi-entry quest", function(){
    local questEntry = TestQuestMultiEntry();

    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST), 0);
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST, 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST), 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND), 0);

    //If we were to write a value greater than the value's size it should be clamped.
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST, 2);
    //Check there has been no spill over into the next value.
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND), 0);
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST, 100);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND), 0);

    //Do the same for a value that needs shifting.
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND, 100);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_THIRD), 0);
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND, 1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_THIRD), 0);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND), 1);

    //Big number for multi-bit entry.
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_THIRD, 0xFF);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_THIRD), (1<<4)-1);
    _test.assertEqual(questEntry.readValue(QuestValue_TestQuestMultiEntry.METAFIRST_FOURTH), 0);
});

_t("getTable", "Get the serialisation table for a quest.", function(){
    local questEntry = TestQuestMultiEntry();

    local table = questEntry.getTable();
    print(_prettyPrint(table));
    _test.assertTrue(table.rawin("metaFirst"));
    _test.assertTrue(table.rawin("metaSecond"));
    _test.assertEqual(table.rawget("metaSecond"), 0);
    _test.assertEqual(table.rawget("metaFirst"), 0);

    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_FIRST, 1);
    table = questEntry.getTable();
    print(_prettyPrint(table));
    _test.assertEqual(table.rawget("metaFirst"), 1);
    questEntry.setValue(QuestValue_TestQuestMultiEntry.METAFIRST_SECOND, 1);
    table = questEntry.getTable();
    print(_prettyPrint(table));
    _test.assertEqual(table.rawget("metaFirst"), 3);

    _test.assertEqual(table.rawget("metaSecond"), 0);
});