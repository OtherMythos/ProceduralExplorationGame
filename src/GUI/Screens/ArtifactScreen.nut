::ArtifactWidget <- class{
    mParentWindow_ = null;
    mBackgroundPanel_ = null;
    mButton_ = null;
    mIconPanel_ = null;
    mGradientPanel_ = null;
    mRenderIcon_ = null;
    mLabel_ = null;
    mArtifactId_ = ArtifactId.NONE;
    mAnimTime_ = 0.0;

    constructor(parentWindow){
        mParentWindow_ = parentWindow;
    }

    function setup(size, position){
        //Background panel
        mBackgroundPanel_ = mParentWindow_.createPanel();
        mBackgroundPanel_.setSize(size);
        mBackgroundPanel_.setSkinPack("Panel_midGrey");

        //Icon panel (receives render icon datablock for 3D display)
        local iconSize = Vec2(size.x * 0.4, size.y * 0.6);

        mGradientPanel_ = mParentWindow_.createPanel();
        mGradientPanel_.setSize(iconSize * 1.5);
        mGradientPanel_.setDatablock("simpleGradient");
        mGradientPanel_.setClickable(false);

        mIconPanel_ = mParentWindow_.createPanel();
        mIconPanel_.setSize(iconSize);

        mRenderIcon_ = ::RenderIconManager.createIcon("readables.noteScrap.voxMesh", true, true);
        mRenderIcon_.setSize(iconSize.x, iconSize.y);
        local orientation = Quat();
        orientation += Quat(0.5, ::Vec3_UNIT_Y);
        orientation += Quat(-0.5, ::Vec3_UNIT_Z);
        orientation += Quat(1.0, ::Vec3_UNIT_X);
        mRenderIcon_.setOrientation(orientation);
        local datablock = mRenderIcon_.getDatablock();
        if(datablock != null){
            mIconPanel_.setDatablock(datablock);
        }

        //Label
        mLabel_ = mParentWindow_.createLabel();
        mLabel_.setSize(size.x - 20, size.y * 0.3);
        mLabel_.setClickable(false);
        mLabel_.setText("Artifact", false);
        mLabel_.sizeToFit(size.x * 0.9);

        //Button for callback handling
        mButton_ = mParentWindow_.createButton();
        mButton_.setSize(size);
        mButton_.setVisualsEnabled(false);
        mButton_.attachListenerForEvent(function(widget, action){
            onArtifactSelected_();
        }, _GUI_ACTION_PRESSED, this);
    }

    function setPosition(position){
        local size = mBackgroundPanel_.getSize();

        //Background panel and button at origin
        mBackgroundPanel_.setPosition(position);
        //mBackgroundPanel_.setColour(ColourValue(0.1, 0.1, 0.1, 0.8));
        mButton_.setPosition(position);

        //Icon positioned in upper-middle area
        local iconX = position.x + (size.x / 2 - mIconPanel_.getSize().x / 2);
        local iconY = position.y;
        local iconCentreX = iconX + mIconPanel_.getSize().x / 2;
        local iconCentreY = iconY + 10 + mIconPanel_.getSize().y / 2;
        mGradientPanel_.setCentre(iconCentreX, iconCentreY);
        mIconPanel_.setPosition(iconX, iconY + 10);
        mIconPanel_.setClickable(false);

        //Centre render icon on icon panel
        local iconCentre = mIconPanel_.getPosition() + mIconPanel_.getSize() / 2;
        mRenderIcon_.setPosition(iconCentre);

        //Label positioned below icon
        local labelY = position.y + mIconPanel_.getSize().y + 5;
        mLabel_.setPosition(position.x + 10, labelY);
    }

    function setArtifact(artifactId){
        mArtifactId_ = artifactId;
        local artifactDef = ::Artifacts[artifactId];
        mLabel_.setText(artifactDef.getName());
        mLabel_.sizeToFit(mBackgroundPanel_.getSize().x * 0.9);

        //Update render icon mesh
        mRenderIcon_.setMesh(::Items[ItemId.NOTE_SCRAP].getMesh());
        local datablock = mRenderIcon_.getDatablock();
        if(datablock != null){
            mIconPanel_.setDatablock(datablock);
        }

        //Adjust background panel size to cover entire label
        local position = mBackgroundPanel_.getPosition();
        local labelPos = mLabel_.getPosition();
        local labelSize = mLabel_.getSize();
        local labelEnd = labelPos.y + labelSize.y;
        local panelNewHeight = labelEnd - position.y;
        local panelSize = mBackgroundPanel_.getSize();
        mBackgroundPanel_.setSize(panelSize.x, panelNewHeight);
        mButton_.setSize(mBackgroundPanel_.getSize());
    }

    function update(){
        mAnimTime_ += 0.01;
        local rotY = Quat(sin(mAnimTime_ * 1.5), ::Vec3_UNIT_Y);
        local rotX = Quat(sin(mAnimTime_ * 2.0), ::Vec3_UNIT_X);
        local baseOrient = Quat();
        baseOrient += Quat(0.5, ::Vec3_UNIT_Y);
        baseOrient += Quat(-0.5, ::Vec3_UNIT_Z);
        baseOrient += Quat(1.0, ::Vec3_UNIT_X);
        local animatedOrient = baseOrient;
        animatedOrient += rotY;
        animatedOrient += rotX;
        mRenderIcon_.setOrientation(animatedOrient);
    }

    function onArtifactSelected_(){
        local artifactDef = ::Artifacts[mArtifactId_];
        local path = artifactDef.getScript();
        if(path != null){
            ::Base.mExplorationLogic.readReadable(path);
        }
    }

    function shutdown(){
        if(mIconPanel_ != null){
            mIconPanel_.setDatablock("simpleGrey");
        }
        if(mRenderIcon_ != null){
            mRenderIcon_.destroy();
            mRenderIcon_ = null;
        }
        _gui.destroy(mBackgroundPanel_);
        _gui.destroy(mGradientPanel_);
        _gui.destroy(mButton_);
        _gui.destroy(mIconPanel_);
        _gui.destroy(mLabel_);
    }
};

::ScreenManager.Screens[Screen.ARTIFACT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mArtifactScrollPanel_ = null;
    mArtifactWidgets_ = null;
    mActionSetId_ = null;
    mPaddingTop_ = 0;

    function setup(data){
        createBackgroundScreen_();
        createBackgroundCloseButton_();

        mWindow_ = _gui.createWindow("ArtifactScreen");
        mWindow_.setSize(::drawable.x, ::drawable.y * 100000);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setBreadthFirst(true);

        local insets = _window.getScreenSafeAreaInsets();
        local padding = 20;
        mPaddingTop_ = padding + insets.top;
        local windowWidth = mWindow_.getSize().x - (padding * 2);
        local windowHeight = mWindow_.getSize().y - (mPaddingTop_ + padding);

        //Title
        local titleLabel = mWindow_.createLabel();
        titleLabel.setText("Artifacts");
        //titleLabel.setFontHeight(36);
        titleLabel.setPosition(padding, mPaddingTop_);

        //Close button
        local closeButton = mWindow_.createButton();
        local closeSize = 64;
        closeButton.setSize(closeSize, closeSize);
        closeButton.setPosition(mWindow_.getSize().x - closeSize - padding, mPaddingTop_);
        closeButton.setUserId(0);
        closeButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.SELECTION);
            closeScreen();
        }, _GUI_ACTION_PRESSED, this);

        local closeIcon = mWindow_.createPanel();
        closeIcon.setDatablock("backButtonIcon");
        closeIcon.setClickable(false);
        closeIcon.setSize(closeSize, closeSize);
        closeIcon.setPosition(closeButton.getPosition());

        //Scroll area for artifacts
        local scrollStartY = mPaddingTop_ + 50;
        local scrollHeight = windowHeight - 50;

        //mArtifactScrollPanel_ = mWindow_.createScrollPanel();
        //mArtifactScrollPanel_.setSize(windowWidth, scrollHeight);
        //mArtifactScrollPanel_.setPosition(padding, scrollStartY);
        //mArtifactScrollPanel_.setVisualsEnabled(true);
        mArtifactScrollPanel_ = mWindow_;

        //Populate artifact types
        populateArtifacts_();

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);

        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.sizeScrollToFit();
    }

    function populateArtifacts_(){
        local artifactTypes = {};

        //Group artifacts by type
        foreach(artifactId in ::Base.mArtifactCollection.getArtifacts()){
            local artifactDef = ::Artifacts[artifactId];
            local typeId = artifactDef.getType();
            if(!artifactTypes.rawin(typeId)){
                artifactTypes.rawset(typeId, []);
            }
            artifactTypes[typeId].append(artifactId);
        }

        //Create UI for each artifact type
        local layoutLine = _gui.createLayoutLine();
        //layoutLine.setOrientation(_ORIENTATION_VERTICAL);
        mArtifactWidgets_ = [];
        local artifactIds = [];

        foreach(typeId, ids in artifactTypes){
            //Type title
            local typeLabel = mArtifactScrollPanel_.createLabel();
            typeLabel.setText(getArtifactTypeName_(typeId));
            //typeLabel.setColour(0.8, 0.8, 0.8);
            typeLabel.setExpandHorizontal(true);
            layoutLine.addCell(typeLabel);

            //Artifact items for this type
            ids.sort();
            foreach(artifactId in ids){
                local artifactWidget = ::ArtifactWidget(mArtifactScrollPanel_);
                artifactWidget.setup(Vec2(150, 100), Vec2(0, 0));
                layoutLine.addCell(artifactWidget.mBackgroundPanel_);
                mArtifactWidgets_.append(artifactWidget);
                artifactIds.append(artifactId);
            }
        }

        //If no artifacts, show message
        if(artifactTypes.len() == 0){
            local emptyLabel = mArtifactScrollPanel_.createLabel();
            emptyLabel.setText("No artifacts collected yet.");
            //emptyLabel.setColour(0.6, 0.6, 0.6);
            emptyLabel.setExpandHorizontal(true);
            layoutLine.addCell(emptyLabel);
        }

        layoutLine.setMarginForAllCells(0, 10);
        layoutLine.setPosition(20, mPaddingTop_ + 80);
        layoutLine.setSize(::drawable.x - (20 * 2), mWindow_.getSize().y);
        layoutLine.layout();

        //Position widgets after layout
        foreach(widget in mArtifactWidgets_){
            widget.setPosition(widget.mBackgroundPanel_.getPosition());
        }

        //Set artifacts after layout and positioning
        for(local i = 0; i < mArtifactWidgets_.len(); i++){
            mArtifactWidgets_[i].setArtifact(artifactIds[i]);
        }

        layoutLine.layout();

        //Position widgets after layout
        foreach(widget in mArtifactWidgets_){
            widget.setPosition(widget.mBackgroundPanel_.getPosition());
        }
    }

    function getArtifactTypeName_(typeId){
        switch(typeId){
            case ArtifactType.MESSAGE_IN_A_BOTTLE_SCRAP:
                return "Message in a Bottle Scraps";
            case ArtifactType.ROCK_FRAGMENT:
                return "Rock Fragments";
            default:
                return "Unknown Type";
        }
    }

    function update(){
        if(mArtifactWidgets_ == null) return;
        foreach(widget in mArtifactWidgets_){
            widget.update();
        }
    }

    function shutdown(){
        if(mArtifactWidgets_ != null){
            foreach(widget in mArtifactWidgets_){
                widget.shutdown();
            }
            mArtifactWidgets_ = null;
        }
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }

    function recreate(){
        if(mWindow_ == null){
            setup({});
        }
    }
};
