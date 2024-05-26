const FOUND_ITEM_EFFECT_Z = 11;

::EffectManager.Effects[Effect.FOUND_ITEM_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mParticles_ = null;
    mParticleData_ = null;

    mBoxCentre_ = null;
    mBoxHalfSize_ = null;

    mCount_ = 0.0;
    mParticleScale_ = 0.2;

    function setup(data){
        mBoxCentre_ = data.centre;
        mBoxHalfSize_ = data.extents;

        mTotalLifetimeCount_ = 30;

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mParticles_ = createParticles(mParentNode_, 100);
        mParticleData_ = createParticleData(100);
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
            local scale = 1 - animVal;
            child.setScale(scaleAnimVal, scaleAnimVal, 1);
            i.move(0, mParticleData_[c] * animVal, 0);
        }

        return tickLifetime();
    }

    function createParticles(parent, numParticles){
        local finishedParticles = array(numParticles, null);

        local boxExtents = mBoxHalfSize_ - mBoxCentre_;
        local topLeft = mBoxCentre_ - boxExtents;
        local bottomLeft = mBoxCentre_.copy();
        bottomLeft.x -= mBoxCentre_.x;
        bottomLeft.y += mBoxCentre_.y;

        for(local i = 0; i < numParticles; i++){
            local newNode = parent.createChildSceneNode();
            local animNode = newNode.createChildSceneNode();
            local particleItem = _scene.createItem("plane");
            particleItem.setRenderQueueGroup(65);
            animNode.attachObject(particleItem);
            animNode.setScale(mParticleScale_, mParticleScale_, mParticleScale_);

            finishedParticles[i] = newNode;
        }

        local yOffset = boxExtents.y * 0.1;
        local half = numParticles / 2;
        for(local i = 0; i < numParticles; i++){
            local node = finishedParticles[i];
            local targetPos = topLeft.x + (boxExtents.x * 2) * _random.rand();
            local targetY = 0;
            if(i >= half){
                targetY = yOffset + topLeft.y + boxExtents.y * 2;
            }else{
                targetY = topLeft.y - yOffset;
            }
            node.setPosition(targetPos, targetY, 0);
        }

        return finishedParticles;
    }

    function createParticleData(numParticles){
        local finished = array(numParticles, null);

        local half = numParticles / 2;
        local reducer = 0.1;
        for(local i = 0; i < half; i++){
            finished[i] = _random.rand() * reducer;
        }
        for(local i = half; i < numParticles; i++){
            finished[i] = -_random.rand() * reducer;
        }

        return finished;
    }

};