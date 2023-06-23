::ScreenManager.Screens[Screen.COMBAT_SCREEN].CombatStatsDisplay <- class{
    mWindow_ = null;

    mDataDisplays_ = null;

    constructor(parentWin, combatBus){
        combatBus.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow(parentWin);

        mDataDisplays_ = [];

        local playerHealthBar = ::GuiWidgets.ProgressBar(mWindow_);
        playerHealthBar.setLabel("Player");
        mDataDisplays_.append(playerHealthBar);

        local combatData = combatBus.mCombatData;
        foreach(i in combatData.mOpponentStats){
            local healthBar = ::GuiWidgets.ProgressBar(mWindow_);
            healthBar.setLabel(::Enemies[enemyType].getName());
            mDataDisplays_.append(healthBar);
        }

        notifyCombatChange(combatData);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(1);
    }

    function notifyCombatChange(data){
        setStat_(data.mPlayerStats, mDataDisplays_[0], 0);
        for(local i = 0; i < data.mOpponentStats.len(); i++){
            local stats = data.mOpponentStats[i];
            if(stats.mDead) continue;
            local idx = i+1;
            setStat_(stats, mDataDisplays_[idx], idx);
        }
    }

    function setStat_(statObj, guiStat, idx){
        guiStat.setPercentage(statObj.mHealth.tofloat() / statObj.mMaxHealth.tofloat());
        guiStat.setPosition(0, idx * (guiStat.getSize().y * 1.1));
    }

    function removeForOpponent(opponentId){
        local idx = opponentId + 1;
        mDataDisplays_[idx].destroy();
        mDataDisplays_[idx] = null;
    }

    function notifyResize(){
        local winSize = mWindow_.getSizeAfterClipping();
        foreach(i in mDataDisplays_){
            i.setSize(winSize.x, i.getSize().y);
        }

        mWindow_.setPosition(200, mWindow_.getPosition().y);
    }

    function busCallback(event, data){
    }
};