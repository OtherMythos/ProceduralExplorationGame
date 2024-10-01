
_t("Scan simple dialog", "Check dialog can be scanned, markers are removed and rich text contains correct values.", function(){
    local scanner = ::DialogManager.DialogMetaScanner();

    local outContainer = array(2);
    scanner.getRichText("This is some [GREEN]rich[GREEN] [RED]text[RED] and an end.", outContainer);
    _test.assertEqual(outContainer[0], "This is some rich text and an end.");

    scanner.getRichText("You received [MONEY]100[MONEY] coins!", outContainer);
    _test.assertEqual(outContainer[0], "You received 100 coins!");
});