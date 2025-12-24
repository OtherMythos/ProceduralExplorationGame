
::ScreenManager.Screens[Screen.ARTIFACT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mArtifactScrollPanel_ = null;
    mActionSetId_ = null;

    function setup(data){
        createBackgroundScreen_();
        createBackgroundCloseButton_();

        mWindow_ = _gui.createWindow("ArtifactScreen");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setBreadthFirst(true);

        local padding = 20;
        local windowWidth = mWindow_.getSize().x - (padding * 2);
        local windowHeight = mWindow_.getSize().y - (padding * 2);

        //Title
        local titleLabel = mWindow_.createLabel();
        titleLabel.setText("Artifacts");
        //titleLabel.setFontHeight(36);
        titleLabel.setPosition(padding, padding);

        //Close button
        local closeButton = mWindow_.createButton();
        local closeSize = 50;
        closeButton.setSize(closeSize, closeSize);
        closeButton.setPosition(mWindow_.getSize().x - closeSize - padding, padding);
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
        local scrollStartY = padding + 50;
        local scrollHeight = windowHeight - 50;

        //mArtifactScrollPanel_ = mWindow_.createScrollPanel();
        //mArtifactScrollPanel_.setSize(windowWidth, scrollHeight);
        //mArtifactScrollPanel_.setPosition(padding, scrollStartY);
        //mArtifactScrollPanel_.setVisualsEnabled(true);
        mArtifactScrollPanel_ = mWindow_;

        //Populate artifact types
        populateArtifacts_();

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
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

        foreach(typeId, artifactIds in artifactTypes){
            //Type title
            local typeLabel = mArtifactScrollPanel_.createLabel();
            typeLabel.setText(getArtifactTypeName_(typeId));
            //typeLabel.setColour(0.8, 0.8, 0.8);
            typeLabel.setExpandHorizontal(true);
            layoutLine.addCell(typeLabel);

            //Artifact items for this type
            foreach(artifactId in artifactIds){
                local artifactDef = ::Artifacts[artifactId];

                local nameLabel = mArtifactScrollPanel_.createLabel();
                nameLabel.setText(artifactDef.getName());
                nameLabel.setExpandHorizontal(true);
                layoutLine.addCell(nameLabel);
            }
        }

        //If no artifacts, show message
        if(artifactTypes.len() == 0){
            local emptyLabel = mArtifactScrollPanel_.createLabel();
            emptyLabel.setText("No artifacts collected yet.");
            emptyLabel.setColour(0.6, 0.6, 0.6);
            emptyLabel.setExpandHorizontal(true);
            layoutLine.addCell(emptyLabel);
        }

        layoutLine.setMarginForAllCells(0, 10);
        layoutLine.setPosition(20, 80);
        layoutLine.setSize(::drawable.x - 40, ::drawable.y - 120);
        layoutLine.layout();
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

    function shutdown(){
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }

    function recreate(){
        if(mWindow_ == null){
            setup({});
        }
    }
};
