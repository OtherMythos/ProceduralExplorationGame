_t("calculateFontWidth", "Test the calculate font width function", function(){
    local testWindow = _gui.createWindow();
    testWindow.setSize(400, 400);

    foreach(i in [100, 200, 300, 700]){
        local testLabel = testWindow.createLabel();
        testLabel.setText("hello");

        ::calculateFontWidth_(testLabel, i);
        local determinedWidth = testLabel.getSize().x;
        print(determinedWidth);
        _test.assertTrue(determinedWidth >= i - 4.0 && determinedWidth <= i + 4.0);
    }
});


_t("calculateFontWidthSmaller", "Test the calculate font width function while shrinking the font size", function(){
    local testWindow = _gui.createWindow();
    testWindow.setSize(400, 400);

    foreach(i in [100, 200, 300, 700]){
        local testLabel = testWindow.createLabel();
        testLabel.setText("test text");
        testLabel.setDefaultFontSize(testLabel.getDefaultFontSize() * 26);

        ::calculateFontWidth_(testLabel, i);
        local determinedWidth = testLabel.getSize().x;
        print(determinedWidth);
        _test.assertTrue(determinedWidth >= i - 4.0 && determinedWidth <= i + 4.0);
    }
});