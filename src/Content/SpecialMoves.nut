
::SpecialMoveDef <- class{
    mName_ = null;
    mCooldown_ = 10;
    mProjectile_ = null;
    mPerformanceFunction_ = null;
    constructor(name, cooldown=10, projectile=null, performanceFunction=null){
        mName_ = name;
        mCooldown_ = cooldown;
        mProjectile_ = projectile;
        mPerformanceFunction_ = performanceFunction;
    }
    function getName(){
        return mName_;
    }
    function getCooldown(){
        return mCooldown_;
    }
    function getProjectile(){
        return mProjectile_;
    }
    function getPerformanceFunction(){
        return mPerformanceFunction_;
    }
};

::SpecialMovePerformance <- class{
    mMoveDef_ = null;
    mFrame_ = 0;

    constructor(moveDef){
        mMoveDef_ = moveDef;
    }

    function update(){
        local f = mMoveDef_.getPerformanceFunction();
        if(f == null) return true;
        local ret = f(mFrame_);
        mFrame_++;
        return ret;
    }
}