
::ObjectDropAction <- class extends WorldAction{

    mStartPos_ = null;
    mEndPos_ = null;

    mCount_ = 0;
    mFrames_ = 10;

    mItem_ = null;

    constructor(createdItem, creatorWorld, startPos, endPos){
        base.constructor(creatorWorld);

        mStartPos_ = startPos.copy();
        mEndPos_ = endPos.copy();

        mFrames_ = 10 + _random.randInt(0, 5);

        mItem_ = createdItem;

        mCreatorWorld_.getEntityManager().setEntityPosition(mItem_, mStartPos_);
    }

    function update(){

        local anim = mCount_.tofloat() / mFrames_.tofloat();
        local pos = ::calculateSimpleAnimation(mStartPos_, mEndPos_, anim);
        pos.y = sin(anim * PI);

        mCreatorWorld_.getEntityManager().setEntityPosition(mItem_, pos);

        mCount_++;
        return mCount_ < mFrames_;
    }

    function notifyStart(){

    }

    function notifyEnd(){

    }
};