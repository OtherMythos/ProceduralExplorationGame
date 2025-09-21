::GuiWidgets.PlayerBasicStatsWidget <- class{

    mPlayerHealthBar_ = null;
    mCoinLabel_ = null;
    mEXPOrbLabel_ = null;

    mWindow_ = null;
    mSize_ = null;

    function setPosition(pos){
        mWindow_.setPosition(pos);
    }

    function getSize(){
        return mSize_;
    }

    function getPosition(){
        return mWindow_.getPosition();
    }

    function setVisible(vis){
        mWindow_.setVisible(vis);
    }

    function getEXPCounter(){
        return ::EffectManager.getWorldPositionForWindowPos(mEXPOrbLabel_.getDerivedCentre());
    }

    function getMoneyCounter(){
        return ::EffectManager.getWorldPositionForWindowPos(mCoinLabel_.getDerivedCentre());
    }

    function setup(parentWindow){

        local window = parentWindow.createWindow();

        local statsSize = Vec2(::drawable.x, 50);
        local leftCount = 0;
        mSize_ = statsSize;

        window.setSize(statsSize);
        window.setVisualsEnabled(false);
        window.setClipBorders(0, 0, 0, 0);
        mWindow_ = window;

        /*
        local debugBackground = window.createPanel();
        debugBackground.setSize(statsSize);
        debugBackground.setPosition(0, 0);
        debugBackground.setDatablock("playerMapIndicator");
        */

        {
            local heartIcon = window.createPanel();
            heartIcon.setDatablock("healthIcon");
            heartIcon.setSize(48, 48);
            heartIcon.setPosition(0, 0);
            leftCount += 50;

            local healthBar = ::GuiWidgets.ProgressBar(window);
            local barSize = statsSize.x / 2 - leftCount;
            local barHeight = 35;
            healthBar.setSize(barSize, barHeight);
            healthBar.setPercentage(0.5);
            healthBar.setBorder(2);
            healthBar.setPosition(leftCount, statsSize.y / 2 - barHeight / 2);
            healthBar.setLabel("120/240");
            mPlayerHealthBar_ = healthBar;
            leftCount += barSize;
        }

        {
            local orbIcon = window.createPanel();
            orbIcon.setDatablock("orbsIcon");
            orbIcon.setSize(48, 48);
            orbIcon.setPosition(leftCount, 0);
            leftCount += 48;

            mEXPOrbLabel_ = window.createLabel();
            mEXPOrbLabel_.setDefaultFontSize(mEXPOrbLabel_.getDefaultFontSize() * 1.2);
            mEXPOrbLabel_.setText("999");
            mEXPOrbLabel_.setPosition(leftCount, 0);
            leftCount += mEXPOrbLabel_.getSize().x;
        }

        {
            local coinIcon = window.createPanel();
            coinIcon.setDatablock("coinsIcon");
            coinIcon.setSize(48, 48);
            coinIcon.setPosition(leftCount, 0);
            leftCount += 48;

            mCoinLabel_ = window.createLabel();
            mCoinLabel_.setDefaultFontSize(mCoinLabel_.getDefaultFontSize() * 1.2);
            mCoinLabel_.setText("999");
            mCoinLabel_.setPosition(leftCount, 0);
            leftCount += mCoinLabel_.getSize().x;
        }

        mEXPOrbLabel_.setText("0");
        mCoinLabel_.setText("0");

        _event.subscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.subscribe(Event.EXP_ORBS_ADDED, receiveEXPAnimFinished, this);
        _event.subscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.subscribe(Event.MONEY_CHANGED, receiveMoneyChanged, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.unsubscribe(Event.EXP_ORBS_ADDED, receiveEXPAnimFinished, this);
        _event.unsubscribe(Event.MONEY_ADDED, receiveMoneyAnimFinished, this);
        _event.unsubscribe(Event.MONEY_CHANGED, receiveMoneyChanged, this);
    }

    function receiveMoneyAnimFinished(id, data){
        //addForAnimation(data);
        addCoinAmount_(data);
    }

    function receiveMoneyChanged(id, data){
        mCoinLabel_.setText(data.tostring());
    }

    function addCoinAmount_(amount){
        local numCoins = mCoinLabel_.getText().tointeger();
        mCoinLabel_.setText((numCoins + amount).tostring());
    }

    function playerHealthChanged(id, data){
        mPlayerHealthBar_.setPercentage(data.percentage);
        mPlayerHealthBar_.setLabel(format("%i/%i", data.health, data.max));
    }

    function receiveEXPAnimFinished(id, data){
        local numEXP = mEXPOrbLabel_.getText().tointeger();
        //TODO bit of a hack
        mEXPOrbLabel_.setText((numEXP + data).tostring());
    }

};