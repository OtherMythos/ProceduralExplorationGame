::VersionPool <- class{

    mObject_ = null;
    mObjectVersions_ = null;
    mFreeList_ = null;
    mCount_ = 0;

    constructor(){
        mObject_ = [];
        mObjectVersions_ = [];
        mFreeList_ = [];
    }

    function store(storedObject){
        local outIdx = null;
        local outVersion = null;
        if(mFreeList_.len() <= 0){
            outIdx = mObject_.len();
            mObject_.append(storedObject);
            mObjectVersions_.append(0);
            outVersion = 0;
        }else{
            local idx = mFreeList_.top();
            mFreeList_.pop();
            mObject_[idx] = storedObject;
            outVersion = mObjectVersions_[idx];
            outIdx = idx;
        }
        return (outVersion << 32) | outIdx;
    }

    function unstore(id){
        local version = (id >> 32) & 0xFFFFFFFF;
        local idx = (id) & 0xFFFFFFFF;
        mObjectVersions_[idx]++;
        mObject_[idx] = null;
        mFreeList_.append(idx);
    }

    function get(id){
        return mObject_[id & 0xFFFFFFFF];
    }

    function valid(id){
        return mObjectVersions_[id & 0xFFFFFFFF] == ((id >> 32) & 0xFFFFFFFF);
    }

};