::ScreenManager.Screens[Screen.GAME_TITLE_SCREEN] = class extends ::Screen{
    mBusId_ = null;

    mTitlePanel_ = null;
    mTitleLabel_ = null;
    mCreditLabel_ = null;
    mTapToStartLabel_ = null;
    mScreenButton_ = null;

    mAnimCount_ = 1.0;
    mAnimFinished_ = true;
    mTitleFullScreen_ = false;
    mTitleMainScreenPanel_ = null;
    mTitlePanelCoords_ = null;
    mAnimateIn_ = false;
    mSkipWindupAnimation_ = false;

    mPulseTime_ = 0.0;
    mTapStartBaseFontSize_ = null;
    mTapStartBaseCentre_ = null;

    function setup( data ){
        mBusId_ = data.bus.registerCallback( busCallback, this );

        mTitlePanelCoords_ = {
            "pos": data.pos,
            "size": data.size
        };

        mAnimateIn_ = data.animateIn;
        mSkipWindupAnimation_ = ("skipWindupAnimation" in data) && data.skipWindupAnimation;

        //Subscribe to splash screen finished event
        if(!::Base.isProfileActive(GameProfile.DISABLE_SPLASH_SCREEN)){
            _event.subscribe(Event.SPLASH_SCREEN_FINISHED, receiveSplashScreenEnded, this);
        }else{
            //If splash screen is disabled, notify immediately
            ::OverworldLogic.notifyTitleScreenAnimationReady();
        }

        base.setup( data );
    }

    function receiveSplashScreenEnded(widget, action){
        ::OverworldLogic.notifyTitleScreenAnimationReady();
    }

    function recreate(){
        mWindow_ = _gui.createWindow( "GameTitleScreen" );
        mWindow_.setSize( ::drawable );
        mWindow_.setClipBorders( 0, 0, 0, 0 );
        mWindow_.setVisualsEnabled( false );

        _gameCore.setCameraForNode( "renderMainGameplayNode", "compositor/camera0" );

        mTitleMainScreenPanel_ = mWindow_.createPanel();
        mTitleMainScreenPanel_.setVisible( false );

        local titleLabel = mWindow_.createLabel();
        titleLabel.setTextHorizontalAlignment( _TEXT_ALIGN_CENTER );
        titleLabel.setText( "Procedural Exploration Game", false );
        titleLabel.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        ::calculateFontWidth_( titleLabel, ::drawable.x * 0.9 );
        local labelSize = titleLabel.getSize();
        titleLabel.setPosition( Vec2( ::drawable.x / 2 - labelSize.x / 2, ::drawable.y * 0.2 - labelSize.y / 2 ) );
        mTitleLabel_ = titleLabel;

        //Credit label
        local creditLabel = mWindow_.createLabel();
        creditLabel.setTextHorizontalAlignment( _TEXT_ALIGN_CENTER );
        creditLabel.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        creditLabel.setDefaultFontSize( creditLabel.getDefaultFontSize() * 1.2 );
        creditLabel.setDefaultFont(6);
        creditLabel.setText( "By Edward Herbert");
        creditLabel.setCentre( titleLabel.getCentre() + Vec2(0, labelSize.y) );
        mCreditLabel_ = creditLabel;

        //Tap to start label
        local tapLabel = mWindow_.createLabel();
        tapLabel.setTextHorizontalAlignment( _TEXT_ALIGN_CENTER );
        tapLabel.setText( "Tap to Start");
        tapLabel.setDefaultFontSize( tapLabel.getDefaultFontSize() * 0.8 );
        tapLabel.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mTapStartBaseFontSize_ = tapLabel.getDefaultFontSize();
        local tapSize = tapLabel.getSize();
        local tapPos = Vec2( ::drawable.x / 2 - tapSize.x / 2, ::drawable.y * 0.85 - tapSize.y / 2 );
        tapLabel.setPosition( tapPos );
        mTapStartBaseCentre_ = tapLabel.getCentre();
        mTapToStartLabel_ = tapLabel;
        setTitleOpacity_(mAnimateIn_ ? 0.0 : 1.0);

        ::OverworldLogic.requestSetup();
        ::OverworldLogic.setTitleScreenMode(mSkipWindupAnimation_);

        local datablock = ::OverworldLogic.getCompositorDatablock();
        mTitleMainScreenPanel_.setDatablock( datablock );

        mTitleMainScreenPanel_.setSize( ::drawable );
        mTitleMainScreenPanel_.setPosition( Vec2( 0, 0 ) );
        mTitleMainScreenPanel_.setVisible( true );

        local screenButton = mWindow_.createButton();
        screenButton.setSize( ::drawable );
        screenButton.setPosition( Vec2( 0, 0 ) );
        screenButton.setVisualsEnabled( false );
        screenButton.attachListenerForEvent( function( widget, action ){
            processCloseScreen_();
        }, _GUI_ACTION_PRESSED, this );
        mScreenButton_ = screenButton;

        if( mAnimateIn_ ){
            setTitleFullscreen( false );
        }else{
            setTitleFullscreen( true );
            mAnimCount_ = 1.0;
        }
    }

    function shutdown(){
        if( mBusId_ != null ){
            mScreenData_.data.bus.deregisterCallback( mBusId_ );
        }
        _event.unsubscribe(Event.SPLASH_SCREEN_FINISHED, receiveSplashScreenEnded, this);
        if( mScreenData_.data != null ){
            mScreenData_.data.bus.notifyEvent( GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_FINISHED, null );
        }
        mTitleMainScreenPanel_.setDatablock( "simpleGrey" );
        base.shutdown();
        ::OverworldLogic.requestShutdown();
        ::Base.applyCompositorModifications()
    }

    function receiveSelectionChangeEvent( id, data ){
        //not used for title screen
    }

    function processCloseScreen_(){
        if( !mAnimFinished_ ) return;

        ::HapticManager.triggerSimpleHaptic(HapticType.MEDIUM);
        setTitleFullscreen( false );
    }

    function getTitlePanelCoords(){
        return mTitlePanelCoords_;
    }

    function setTitleFullscreen( fullscreen ){
        local changed = (mTitleFullScreen_ != fullscreen);
        mTitleFullScreen_ = fullscreen;

        mAnimCount_ = 0.0;
        mAnimFinished_ = false;
    }

    function getTitleStartEndValues(){
        local d = null;

        local panelStart = mTitlePanelCoords_;

        if( mAnimateIn_ ){
            d = {
                "startPos": panelStart.pos,
                "startSize": panelStart.size,
                "endPos": ::Vec2_ZERO,
                "endSize": ::drawable,
            };
        }else{
            d = {
                "endPos": panelStart.pos,
                "endSize": panelStart.size,
                "startPos": ::Vec2_ZERO,
                "startSize": ::drawable,
            };
        }

        return d;
    }

    function updateTitleAnimation(){
        if( mAnimCount_ == 1.0 ){
            if( mAnimFinished_ == false ){
                if( !mTitleFullScreen_ ){
                    if( mScreenData_.data.bus != null ){
                        mScreenData_.data.bus.notifyEvent( GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_FINISHED, null );
                    }
                    if(!mAnimateIn_ ){
                        ::ScreenManager.transitionToScreen( null, null, mLayerIdx );
                        ::OverworldLogic.requestState(OverworldStates.ZOOMED_OUT);
                    }
                    mTitleFullScreen_ = true;
                    if( mAnimateIn_ ){
                        mAnimateIn_ = false;
                    }
                }else{
                    if( mScreenData_.data.bus != null ){
                        mScreenData_.data.bus.notifyEvent( GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_FINISHED, null );
                    }
                }
            }

            mAnimFinished_ = true;
            return;
        }
        mAnimCount_ = ::accelerationClampCoordinate_( mAnimCount_, 1.0, 0.02 );

        {
            local animStart = mTitleFullScreen_ ? 0.0 : 0.2;
            local animEnd = mTitleFullScreen_ ? 0.8 : 1.0;

            local v = getTitleStartEndValues();
            local startPos = v.startPos;
            local startSize = v.startSize;

            local endPos = v.endPos;
            local endSize = v.endSize;

            local animPos = ::calculateSimpleAnimationInRange( startPos, endPos, mAnimCount_, animStart, animEnd );
            local animSize = ::calculateSimpleAnimationInRange( startSize, endSize, mAnimCount_, animStart, animEnd );

            mTitleMainScreenPanel_.setPosition( animPos );
            mTitleMainScreenPanel_.setSize( animSize );

            ::OverworldLogic.setRenderableSize( animPos, animSize );
        }

        //Title label
        {
            local animStart = mAnimateIn_ ? 0.8 : 0.0;
            local animEnd = mAnimateIn_ ? 1.0 : 0.2;

            local startCol = mAnimateIn_ ? 0.0 : 1.0;
            local endCol = mAnimateIn_ ? 1.0 : 0.0;
            local animCol = ::calculateSimpleAnimationInRange( startCol, endCol, mAnimCount_, animStart, animEnd );

            setTitleOpacity_(animCol);
        }
    }

    function setTitleOpacity_(opacity){
        mTitleLabel_.setTextColour(1, 1, 1, opacity);
        mCreditLabel_.setTextColour(1, 1, 1, opacity);
        mTapToStartLabel_.setTextColour(1, 1, 1, opacity);
    }

    function update(){
        mPulseTime_ += 0.05;

        //Update pulse animation for tap to start label with size
        local val = sin(mPulseTime_) * 0.15;
        if(val < 0) val = -val;
        local pulseAmount = val + 2;
        local newFontSize = mTapStartBaseFontSize_ * pulseAmount;
        mTapToStartLabel_.setDefaultFontSize(newFontSize);
        mTapToStartLabel_.sizeToFit();
        mTapToStartLabel_.setCentre(mTapStartBaseCentre_);

        updateTitleAnimation();

        ::OverworldLogic.applyCameraDelta( Vec2( 0.0, 0.0 ) );
        ::OverworldLogic.applyZoomDelta( 0.0 );
    }

    function busCallback( event, data ){
        if( mScreenData_.data == null ) return;

        if( event == GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_STARTED ){
            mTitlePanelCoords_ = data;
            setTitleFullscreen( true );
        }
        else if( event == GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_STARTED ){
            setTitleFullscreen( false );
        }
    }

};
