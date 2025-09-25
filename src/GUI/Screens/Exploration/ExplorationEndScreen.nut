enum ExplorationScreenComponents{
    NONE,
    INTRO,
    TITLE,
    TEXT_ENTRIES,
    LEVEL_INDICATOR,
    EXP_PROGRESS,
    DISCOVERED_LEVELS,
    END_BUTTONS,

    MAX
};

local ExplorationEndScreenAnimStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(ExplorationScreenComponents.MAX);
};

local ObjAnim = class{
    mObj = null;
    mStart = null; mEnd = null;
    constructor(obj){
        mObj = obj;
        mObj.setTextColour(0, 0, 0, 0);
        mObj.setVisible(true);
        mEnd = mObj.getPosition();
        mStart = mEnd - Vec2(30, 0);
    }
    function update(p){
        mObj.setTextColour(0, 0, 0, p);
        mObj.setPosition(mStart + (mEnd - mStart) * p);
    }
};

{
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.INTRO] = class extends ::Util.State{
        mTotalCount_ = 1
        mNextState_ = ExplorationScreenComponents.TITLE;
        function start(data){
            local c = data.components;
            c[ExplorationScreenComponents.TITLE].setVisible(false);
            foreach(i in c[ExplorationScreenComponents.TEXT_ENTRIES]) { i.setVisible(false); }
            c[ExplorationScreenComponents.EXP_PROGRESS].setVisible(false);
            c[ExplorationScreenComponents.LEVEL_INDICATOR].setVisible(false);
            foreach(i in c[ExplorationScreenComponents.END_BUTTONS]) { i.setVisible(false); }
        }
        function update(p, data){
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.TITLE] = class extends ::Util.State{
        mTotalCount_ = 20
        mNextState_ = ExplorationScreenComponents.TEXT_ENTRIES;
        mObjAnim_ = null;
        function start(data){
            mObjAnim_ = ObjAnim(data.components[ExplorationScreenComponents.TITLE]);
        }
        function update(p, data){
            mObjAnim_.update(p);
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.TEXT_ENTRIES] = class extends ::Util.State{
        mTotalCount_ = 30
        mNextState_ = ExplorationScreenComponents.LEVEL_INDICATOR;
        mObjAnim_ = null;
        mDiv_ = 0;
        function start(data){
            mObjAnim_ = [];
            foreach(i in data.components[ExplorationScreenComponents.TEXT_ENTRIES]){
                mObjAnim_.append(ObjAnim(i));
            }
            mDiv_ = 1.0 / mObjAnim_.len().tofloat();
        }
        function update(p, data){
            local current = (p / mDiv_).tointeger();
            local anim = (p % mDiv_) / mDiv_;
            if(current < mObjAnim_.len()){
                for(local i = 0; i < current+1; i++){
                    mObjAnim_[i].update(current == i ? anim : 1.0);
                }
            }else{
                //Just make sure they're all fully visible.
                foreach(i in mObjAnim_){
                    i.update(1.0);
                }
            }
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.LEVEL_INDICATOR] = class extends ::Util.State{
        mTotalCount_ = 10
        mNextState_ = ExplorationScreenComponents.EXP_PROGRESS;
        mObjAnim_ = null;
        function start(data){
            local indicator = data.components[ExplorationScreenComponents.LEVEL_INDICATOR];
            indicator.setText("Level " + ::Base.mPlayerStats.getLevel());
            mObjAnim_ = ObjAnim(indicator);
        }
        function update(p, data){
            mObjAnim_.update(p);
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.EXP_PROGRESS] = class extends ::Util.State{
        mTotalCount_ = 200
        mNextState_ = ExplorationScreenComponents.DISCOVERED_LEVELS;
        mObjAnim_ = null;

        mEXPOrbTotalLabel_ = null;

        mOrbsToAdd_ = 0;
        mOrbsAdded_ = 0;

        mStartPos_ = null;
        mEndPos_ = null;
        mLevelData_ = null;
        function start(data){
            mTotalCount_ = data.data.foundEXPOrbs;
            mOrbsToAdd_ = data.data.foundEXPOrbs;
            mLevelData_ = ::Base.mPlayerStats.addEXP(mOrbsToAdd_);
            setLabel(mLevelData_.startEXP, data);

            data.components[ExplorationScreenComponents.EXP_PROGRESS].setVisible(true);

            //TOOD assume the final is the xp orb counter, ensure this in future.
            mEXPOrbTotalLabel_ = data.components[ExplorationScreenComponents.TEXT_ENTRIES].top();
            mStartPos_ = ::EffectManager.getWorldPositionForWindowPos(mEXPOrbTotalLabel_.getDerivedCentre());
            mEndPos_ = ::EffectManager.getWorldPositionForWindowPos(data.components[ExplorationScreenComponents.EXP_PROGRESS].getDerivedCentre());

            data.components[ExplorationScreenComponents.EXP_PROGRESS].setPercentage(mLevelData_.startPercentage);
        }
        function update(p, data){
            if(mOrbsToAdd_ > 0){
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_EXP_ORB_EFFECT, {"numOrbs": 1, "start": mStartPos_, "end": mEndPos_, "orbScale": 0.2}));
            }
            if(mOrbsToAdd_ <= 0) return;
            local prevLevel = ::Base.mPlayerStats.getLevelForEXP_(mLevelData_.startEXP + mOrbsAdded_);

            mOrbsToAdd_--;
            mOrbsAdded_++;

            local currentEXP = mLevelData_.startEXP + mOrbsAdded_;
            local finalAnim = ::Base.mPlayerStats.getPercentageEXP(currentEXP);

            local currentLevel = ::Base.mPlayerStats.getLevelForEXP_(currentEXP);

            //TODO make this a bit nicer
            mEXPOrbTotalLabel_.setText(format("    • Found %i EXP orbs", mOrbsToAdd_));

            local indicator = data.components[ExplorationScreenComponents.LEVEL_INDICATOR];
            indicator.setText("Level " + ::Base.mPlayerStats.getLevelForEXP_(currentEXP));

            data.components[ExplorationScreenComponents.EXP_PROGRESS].setPercentage(finalAnim);
            setLabel(currentEXP, data);

            if(currentLevel > prevLevel){
                //Level up occured.
                local derivedPosition = data.components[ExplorationScreenComponents.EXP_PROGRESS].getDerivedCentre();
                ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.SINGLE_TEXT, {"text": "Level up", "posX": derivedPosition.x, "posY": derivedPosition.y, "fontMultiplier": 1.5, "lifespan": 50, "fadeInTime": 10}));
            }
        }
        function setLabel(currentEXP, data){
            local level = ::Base.mPlayerStats.getLevelForEXP_(currentEXP);
            local expForLevel = ::Base.mPlayerStats.getEXPForLevel(level);
            local total = ::Base.mPlayerStats.getEXPForSingleLevel(level);
            local diff = currentEXP - expForLevel;

            data.components[ExplorationScreenComponents.EXP_PROGRESS].setLabel(format("%i/%i", diff, total));
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.DISCOVERED_LEVELS] = class extends ::Util.State{
        mTotalCount_ = 120;
        mNextState_ = ExplorationScreenComponents.END_BUTTONS;
        function start(data){
            data.components[ExplorationScreenComponents.DISCOVERED_LEVELS].setVisible(true);
        }
        function update(p, data){
            data.components[ExplorationScreenComponents.DISCOVERED_LEVELS].update(p);
        }
    };
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.END_BUTTONS] = class extends ::Util.State{
        mTotalCount_ = 20
        mNextState_ = ExplorationScreenComponents.NONE;
        mObjAnim_ = null;
        function start(data){
            local vals = data.components[ExplorationScreenComponents.END_BUTTONS];
            foreach(i in vals){
                i.setVisible(true);
            }
            _gui.reprocessMousePosition();
        }
        function update(p, data){
        }
    };
}

::ScreenManager.Screens[Screen.EXPLORATION_END_SCREEN] = class extends ::Screen{

    mScreenComponents_ = null;

    mStateMachine_ = null;

    buttonOptions = ["Explore again", "Return to menu"];
    buttonFunctions = [
        function(widget, action){
            ::SaveManager.writeSaveAtPath("user://" + ::Base.mPlayerStats.getSaveSlot(), ::Base.mPlayerStats.getSaveData());

            ::Base.mExplorationLogic.resetExploration();
            ::ScreenManager.queueTransition(null, null, mLayerIdx);
        },
        function(widget, action){
            ::SaveManager.writeSaveAtPath("user://" + ::Base.mPlayerStats.getSaveSlot(), ::Base.mPlayerStats.getSaveData());

            ::ScreenManager.queueTransition(null, null, mLayerIdx);
            ::ScreenManager.queueTransition(::BaseHelperFunctions.getTargetGameplayMainMenu());
        }
    ];

    DiscoveredLevelsScreen = class{
        mWindow_ = null;
        mWidgets_ = null;
        mData_ = null;
        mAnimationsFinished_ = null;
        constructor(parent, data){
            mWindow_ = parent.createWindow();
            mWidgets_ = [];
            mData_ = [];
            mAnimationsFinished_ = array(data.len(), false);

            local layoutLine = _gui.createLayoutLine();
            foreach(c,i in data){
                local discoverData = ::Base.mPlayerStats.getBiomeDiscoveredData(i);
                mData_.append(discoverData);

                local bar = ::GuiWidgets.ExplorationDiscoverLevelBarWidget(mWindow_);
                bar.setLabel(c);
                print(discoverData.percentageCurrent);
                bar.setPercentage(discoverData.percentageCurrent);
                bar.setSecondaryPercentage(discoverData.percentageFuture);
                bar.setCounter(discoverData.levelProgress-1, discoverData.completeLevel);
                bar.addToLayout(layoutLine);

                mWidgets_.append(bar);
            }
            layoutLine.layout();

            foreach(i in mWidgets_){
                i.notifyLayout();
            }
        }
        function addToLayout(layout){
            layout.addCell(mWindow_);
        }
        function update(frame){
            if(frame < 0.5) return;
            foreach(c,i in mWidgets_){
                local d = mData_[c];
                i.setPercentage(d.percentageFuture);
                if(d.percentageFuture >= 1.0){
                    if(!mAnimationsFinished_[c]){
                        local derivedPosition = i.getDerivedCentre();
                        ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.SINGLE_TEXT, {"text": "Level up", "posX": derivedPosition.x, "posY": derivedPosition.y, "fontMultiplier": 1.5, "lifespan": 50, "fadeInTime": 10}));
                        mAnimationsFinished_[c] = true;
                    }
                }
                i.setCounter(d.levelProgress, d.completeLevel);
            }
        }
        function setVisible(vis){
            mWindow_.setVisible(vis);
        }
    };

    function setup(data){

        mScreenComponents_ = {};

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

        mWindow_ = _gui.createWindow("ExplorationEndScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setZOrder(61);
        mWindow_.setBreadthFirst(true);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText("Exploration Complete");
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        mScreenComponents_[ExplorationScreenComponents.TITLE] <- title;

        local outText = getTextForExploration(data);
        foreach(c,i in outText){
            local descText = mWindow_.createLabel();
            descText.setText(i);
            descText.sizeToFit(winWidth);
            descText.setExpandHorizontal(true);
            layoutLine.addCell(descText);
            outText[c] = descText;
        }
        mScreenComponents_[ExplorationScreenComponents.TEXT_ENTRIES] <- outText;

        local levelIndicator = mWindow_.createLabel();
        levelIndicator.setText("Level 0");
        //levelIndicator.setSize(200, 50);
        levelIndicator.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(levelIndicator);
        mScreenComponents_[ExplorationScreenComponents.LEVEL_INDICATOR] <- levelIndicator;

        local levelBar = ::GuiWidgets.ProgressBar(mWindow_);
        levelBar.setSize(200, 50);
        levelBar.addToLayout(layoutLine);
        mScreenComponents_[ExplorationScreenComponents.EXP_PROGRESS] <- levelBar;

        local discoveredLevels = DiscoveredLevelsScreen(mWindow_, data.discoveredBiomes);
        discoveredLevels.addToLayout(layoutLine);
        discoveredLevels.setVisible(false);
        mScreenComponents_[ExplorationScreenComponents.DISCOVERED_LEVELS] <- discoveredLevels;

        local endButtonsLayoutLine = _gui.createLayoutLine();
        local endButtons = [];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            endButtonsLayoutLine.addCell(button);
            endButtons.append(button);
        }
        mScreenComponents_[ExplorationScreenComponents.END_BUTTONS] <- endButtons;

        layoutLine.setSize(winWidth, winHeight);
        layoutLine.setPosition(0, 0);
        layoutLine.layout();

        endButtonsLayoutLine.setSize(winWidth, winHeight);
        local endY = 0;
        endButtonsLayoutLine.layout();
        foreach(i in endButtons){
            endY += i.getSize().y;
        }
        endButtonsLayoutLine.setPosition(0, mWindow_.getSizeAfterClipping().y - endY);
        endButtonsLayoutLine.layout();

        levelBar.notifyLayout();
        levelBar.setPercentage(0.5);

        mStateMachine_ = ExplorationEndScreenAnimStateMachine({"components": mScreenComponents_, "data": data});
        mStateMachine_.setState(ExplorationScreenComponents.INTRO);
    }

    function update(){
        mStateMachine_.update();
    }

    function wrapBulletText_(text){
        return "    • " + text;
    }
    function getTextForExploration(data){
        local outText = [];

        local minutes = (data.explorationTimeTaken / 60.0).tointeger();
        local seconds = (data.explorationTimeTaken % 60.0).tointeger();
        outText.append(format("Exploration completed in %i:%i minutes.", minutes, seconds));
        outText.append(format(wrapBulletText_("Found %i places"), data.totalDiscoveredPlaces));
        outText.append(format(wrapBulletText_("Defeated %i enemies"), data.totalDefeated));
        outText.append(format(wrapBulletText_("Found %i EXP orbs"), data.foundEXPOrbs));

        return outText;
    }
}