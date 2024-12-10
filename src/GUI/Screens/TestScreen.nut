::ScreenManager.Screens[Screen.TEST_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mTestRenderIcon_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow("TestScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local buttonOptions = [
            "Trigger popup",
            "Trigger popup top right",
            "Trigger Region Discovered popup",
            "Trigger spread coin effect",
            "Trigger linear coin effect",
            "Trigger linear orb effect",
            "Trigger single text popup",
            "Generate render icon"
        ];
        local buttonFunctions = [
            function(widget, action){
                local dialogMetaScanner = ::DialogManager.DialogMetaScanner();

                local popupText = "This is a [RED]Popup[RED] with some [BLUE]Rich Text[BLUE]!";
                local outContainer = array(2);
                dialogMetaScanner.getRichText(popupText, outContainer);
                ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.BOTTOM_OF_SCREEN, {"text": outContainer[0], "richText": outContainer[1]}));
            },
            function(widget, action){
                ::PopupManager.displayPopup(Popup.TOP_RIGHT_OF_SCREEN);
            },
            function(widget, action){
                //::PopupManager.displayPopup(Popup.REGION_DISCOVERED);

                ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.REGION_DISCOVERED, ::Biomes[BiomeId.DESERT]));
            },
            function(widget, action){
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"numCoins": 10, "start": Vec2(0, 0), "end": Vec2(-2, 0), "money": 10}));
            },
            function(widget, action){
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_COIN_EFFECT, {"numCoins": 10, "start": Vec2(0, 0), "end": Vec2(-4, -4), "money": 10, "coinScale": 0.1}));
            },
            function(widget, action){
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_EXP_ORB_EFFECT, {"numOrbs": 10, "start": Vec2(0, 0), "end": Vec2(-4, -4), "orbScale": 0.1}));
            },
            function(widget, action){
                ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.SINGLE_TEXT, {"text": "You clicked the mouse", "posX": _input.getMouseX(), "posY": _input.getMouseY(), "fontMultiplier": 1.5, "lifespan": 50, "fadeInTime": 10}));
            },
            function(widget, action){
                local renderIcon = ::RenderIconManager.createIcon("cube");
                renderIcon.setPosition(Vec2(100, 100));
                renderIcon.setSize(50, 50);
                mTestRenderIcon_ = renderIcon;

                //Add some example panels to show how to screen coordinate systems match up.
                local firstPanel = mWindow_.createPanel();
                firstPanel.setPosition(Vec2(150, 150));
                firstPanel.setSize(Vec2(10, 10));

                local secondPanel = mWindow_.createPanel();
                secondPanel.setPosition(Vec2(40, 40));
                secondPanel.setSize(Vec2(10, 10));
            }
        ]

        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 50);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();
    }

    function update(){

    }
};