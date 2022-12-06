::VisitedPlacesScreen <- class extends ::Screen{

    mWindow_ = null;
    mPlayerStats_ = null;

    PlacesContainer = class{
        mWindow_ = null;

        mLayoutTable_ = null;
        buttonThing = null;

        function buttonPressed(widget, action){
            print("Going to " + ::Places.placeToName(widget.getUserId()));
            ::ScreenManager.transitionToScreenForId(Screen.STORY_CONTENT_SCREEN);
        }

        constructor(parentWindow, stats){

            mWindow_ = _gui.createWindow(parentWindow);
            mWindow_.setSize(100, 100);

            mLayoutTable_ = _gui.createLayoutLine();

            //for(local i = 0; i < stats.mPlacesVisited_.len(); i++){
            foreach(i,c in stats.mLeanPlacesVisited_){
                if(c == Place.NONE) continue;

                local button = mWindow_.createButton();
                button.setUserId(c);
                button.setText(::Places.placeToName(c));
                button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
                mLayoutTable_.addCell(button);
            }

            mLayoutTable_.layout();
            mWindow_.sizeScrollToFit();
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setProportionVertical(1);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
        }

        function sizeInner(){
            //mLayoutTable_.setSize(mWindow_.getSize());
            //mLayoutTable_.layout();
            //mWindow_.sizeScrollToFit();
            //mWindow_.setMaxScroll(mWindow_.getSize());

            //TODO make this sized programmatically.
            mWindow_.setSize(mWindow_.getSize().x, 600);
            //mWindow_.setMaxScroll(0, 1200);
            //mWindow_.sizeScrollToFit();
        }
    };

    function setup(data){
        mPlayerStats_ = data.stats;

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        {
            local backButton = mWindow_.createButton();
            backButton.setText("Back");
            backButton.setPosition(5, 25);
            backButton.attachListenerForEvent(function(widget, action){
                ::ScreenManager.backupScreen(0);
            }, _GUI_ACTION_PRESSED, this);
        }

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Visited Places", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        local container = PlacesContainer(mWindow_, mPlayerStats_);
        container.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 5);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.layout();

        container.sizeInner();
    }

    function update(){

    }
};