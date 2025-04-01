const FOUND_ITEM_IDLE_EFFECT_Z = 12;

::EffectManager.Effects[Effect.FOUND_ITEM_IDLE_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mParticles_ = null;
    mParticleData_ = null;

    mBoxCentre_ = null;
    mBoxHalfSize_ = null;

    mCount_ = 0.0;
    mParticleScale_ = 0.1;
    mTotalParticles_ = 20;
    mStartPos_ = null;

    static LIFETIME_SHIFT = 8;

    function setup(data){
        mBoxCentre_ = data.centre;
        mBoxHalfSize_ = data.extents;

        mTotalLifetimeCount_ = 30;
        mStartPos_ = Vec3(mBoxCentre_.x, mBoxCentre_.y, FOUND_ITEM_IDLE_EFFECT_Z);

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mParticles_ = createParticles(mParentNode_, mTotalParticles_);
        mParticleData_ = createParticleData(mTotalParticles_);
    }

    function destroy(){
        mParentNode_.destroyNodeAndChildren();
    }

    function update(){
        mCount_ += 0.01;

        local percentage = getCurrentPercentage();
        local orientation = Quat(mCount_, ::Vec3_UNIT_Z);

        local anim = (1 - percentage);
        local animVal = 1 - pow(1 - anim, 5);
        local scaleAnimVal = anim * anim * anim * anim * mParticleScale_;

        foreach(c,i in mParticles_){
            local child = i.getChild(0);
            child.setOrientation(orientation);

            local idxVal = c * 2;
            i.move(mParticleData_[idxVal] * 0.4);

            local lifetimeVal = mParticleData_[idxVal + 1];
            local currentLife = 0xFF & lifetimeVal;
            local maxLifetime = 0xFF & (lifetimeVal >> LIFETIME_SHIFT);
            if(currentLife >= maxLifetime){
                //The particle has outlived its lifetime and needs to be reset.
                local pos = i.getPosition();
                i.setPosition(mStartPos_);
                mParticleData_[idxVal + 1] = _random.randInt(50, 100) << LIFETIME_SHIFT;
                child.setScale(0, 0, 0);
                continue;
            }
            local percentage = (1.0 - (currentLife.tofloat() / maxLifetime.tofloat())) * mParticleScale_;
            child.setScale(percentage, percentage, percentage);
            mParticleData_[idxVal + 1] = lifetimeVal + 1;
        }

        return true;
    }

    function createParticles(parent, numParticles){
        local finishedParticles = array(numParticles, null);

        for(local i = 0; i < numParticles; i++){
            local newNode = parent.createChildSceneNode();
            local animNode = newNode.createChildSceneNode();
            local particleItem = _scene.createItem("plane");
            particleItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
            animNode.attachObject(particleItem);
            animNode.setScale(mParticleScale_, mParticleScale_, mParticleScale_);

            newNode.setPosition(mStartPos_);

            finishedParticles[i] = newNode;
        }

        return finishedParticles;
    }

    function createParticleData(numParticles){
        local finished = array(numParticles * 2, null);

        local reducer = 0.1;
        for(local i = 0; i < finished.len(); i+=2){
            local vec = _random.randVec3();
            vec -= 0.5;
            finished[i] = vec * reducer;
            local lifetime = _random.randInt(50, 100);
            finished[i+1] = lifetime << LIFETIME_SHIFT;
        }

        return finished;
    }

};