
::EXPTrailAction <- class extends WorldAction{

    mStartPos_ = null;
    mDirection_ = null;
    mNumEXP_ = 10;
    mCount_ = 0;

    constructor(creatorWorld, startPos, direction, numEXP){
        base.constructor(creatorWorld);

        mStartPos_ = startPos.copy();
        mDirection_ = direction.normalisedCopy();
        mNumEXP_ = numEXP;
    }

    function update(){
        mStartPos_.x += mDirection_.x;
        mStartPos_.z += mDirection_.y;
        mCreatorWorld_.mEntityFactory_.constructEXPOrb(mStartPos_);
        print("Spawning " + mCount_);

        mCount_++;

        return mCount_ < mNumEXP_;
    }

    function notifyStart(){

    }

    function notifyEnd(){

    }
};