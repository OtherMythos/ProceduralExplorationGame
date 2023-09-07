::IdPool <- class{

    mIdPool_ = null;
    mCount_ = 0;

    constructor(){
        mIdPool_ = [];
    }

    function getId(){
        if(mIdPool_.len() > 0){
            local id = mIdPool_.top();
            mIdPool_.pop();
            return id;
        }

        return mCount_++;
    }

    function recycleId(id){
        mIdPool_.append(id);
    }

};