/**
 * Store objects in a list, where they are updated each frame, until they return false.
 */
::LifetimePool <- class{

    mActiveObjects_ = null;
    mFreeList_ = null;

    constructor(){
        mActiveObjects_ = [];
        mFreeList_ = [];
    }

    function store(obj){
        if(mFreeList_.len() <= 0){
            mActiveObjects_.append(obj);
        }else{
            local idx = mFreeList_.top();
            mFreeList_.pop();
            mActiveObjects_[idx] = obj;
        }
    }

    function update(){
        local finishedSections = null;

        foreach(c,i in mActiveObjects_){
            if(i == null) continue;
            local running = i.update();
            if(!running){
                if(finishedSections == null){
                    finishedSections = [];
                }
                finishedSections.append(c);
            }
        }

        if(finishedSections == null) return;

        foreach(i in finishedSections){
            mActiveObjects_[i] = null;
            mFreeList_.append(i);
        }
    }

};