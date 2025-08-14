
::ProceduralExplorationWorld.ProceduralExplorationWorldRegionAnimator <- class{

    mPool_ = null

    constructor(){
        mPool_ = ::LifetimePool();
    }

    function update(){
        mPool_.update();

        _gameCore.regionAnimationUpload();
    }

    function addFoundSection(world, x, y, radius){
        local section = FoundSectionRadius(world, x, y, radius);
        //mActiveFoundSections_.append(section);

        mPool_.store(section);
    }

};

::FoundSection <- class{
    mWorld_ = null;
    mX_ = 0;
    mY_ = 0;

    mTotalFrames_ = 10;
    constructor(world, x, y){
        mWorld_ = world;
        mX_ = x.tointeger();
        mY_ = y.tointeger();
    }

    function update(){
        mTotalFrames_--;
        if(mTotalFrames_ > 0){
            return true;
        }
        return false;
    }

    function regionSetValue(x, y){
        local idx = (x + y * 600).tointeger();
        _gameCore.regionAnimationSetValue(idx, 0);
        mWorld_.notifyRegionCoordAppeared(x, y, 6, idx);
    }
}

::FoundSectionRadius <- class extends ::FoundSection{
    mRadius_ = 0;
    constructor(world, x, y, radius){
        base.constructor(world, x, y);
        mRadius_ = radius.tointeger();
        mTotalFrames_ = mRadius_;
    }

    function update(){
        local radius = (mRadius_ - mTotalFrames_);
        for(local y = mY_ - radius; y < mY_ + radius; y++){
            for(local x = mX_ - radius; x < mX_ + radius; x++){
                regionSetValue(x, y);
            }
        }

        return base.update();
    }
}