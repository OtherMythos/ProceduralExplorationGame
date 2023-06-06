enum ExplorationScreenComponents{
    NONE,
    INTRO,
    TITLE,
    TEXT_ENTRIES,
    EXP_PROGRESS,
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
        mNextState_ = ExplorationScreenComponents.EXP_PROGRESS;
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
            print("current " + current);
            print("anim " + anim);
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
    ExplorationEndScreenAnimStateMachine.mStates_[ExplorationScreenComponents.EXP_PROGRESS] = class extends ::Util.State{
        mTotalCount_ = 200
        mNextState_ = ExplorationScreenComponents.END_BUTTONS;
        mObjAnim_ = null;

        mOrbsToAdd_ = 0;

        mStartPos_ = null;
        mEndPos_ = null;
        mLevelData_ = null;
        function start(data){
            data.components[ExplorationScreenComponents.EXP_PROGRESS].setVisible(true);

            //TOOD assume the final is the xp orb counter, ensure this in future.
            mStartPos_ = ::EffectManager.getWorldPositionForWindowPos(data.components[ExplorationScreenComponents.TEXT_ENTRIES].top().getDerivedCentre());
            mEndPos_ = ::EffectManager.getWorldPositionForWindowPos(data.components[ExplorationScreenComponents.EXP_PROGRESS].getDerivedCentre());

            mTotalCount_ = data.data.foundEXPOrbs;
            mOrbsToAdd_ = data.data.foundEXPOrbs;

            mLevelData_ = ::Base.mPlayerStats.addEXP(mOrbsToAdd_);

            //"startLevel": prevLevel,
            //"endLevel": endLevel,
            //"levelPercentage": percentage,
            //"startPercentage": startPercentage,
            data.components[ExplorationScreenComponents.EXP_PROGRESS].setPercentage(mLevelData_.startPercentage);
        }
        function update(p, data){
            if(mOrbsToAdd_ > 0){
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_EXP_ORB_EFFECT, {"numOrbs": 1, "start": mStartPos_, "end": mEndPos_, "orbScale": 0.2}));
            }
            mOrbsToAdd_--;

            local percentageDiff = mLevelData_.endPercentage - mLevelData_.startPercentage;
            data.components[ExplorationScreenComponents.EXP_PROGRESS].setPercentage(mLevelData_.startPercentage + percentageDiff * p);
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
        }
        function update(p, data){
        }
    };
}

::ScreenManager.Screens[Screen.EXPLORATION_END_SCREEN] = class extends ::Screen{

    mScreenComponents_ = null;

    mStateMachine_ = null;

    function setup(data){

        mScreenComponents_ = {};

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setZOrder(61);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Exploration Complete");
        title.setSize(winWidth, title.getSize().y);
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

        local levelBar = ::GuiWidgets.ProgressBar(mWindow_);
        levelBar.setSize(200, 50);
        levelBar.addToLayout(layoutLine);
        mScreenComponents_[ExplorationScreenComponents.EXP_PROGRESS] <- levelBar;

        local buttonOptions = ["Explore again", "Return to menu"];
        local buttonFunctions = [
            function(widget, action){
                ::Base.mExplorationLogic.resetExploration();
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            },
            function(widget, action){
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
                ::ScreenManager.queueTransition(Screen.MAIN_MENU_SCREEN);
            }
        ];
        local endButtons = [];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
            endButtons.append(button);
        }
        mScreenComponents_[ExplorationScreenComponents.END_BUTTONS] <- endButtons;

        layoutLine.setSize(winWidth, winHeight);
        layoutLine.setPosition(0, 0);
        layoutLine.layout();

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