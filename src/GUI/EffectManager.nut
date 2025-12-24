::EffectManager <- {

    EffectData = class{
        id = Effect.EFFECT;
        data = null;
        constructor(id, data){
            this.id = id;
            this.data = data;
        }
        function _typeof(){
            return ObjectType.EFFECT_DATA;
        }
    }

    "Effects": array(Effect.MAX, null),

    mActiveEffects_ = null
    mQueuedDestructionEffects_ = null

    mTestPlane_ = null

    function setup(){
        mActiveEffects_ = [];
        mQueuedDestructionEffects_ = [];
        mTestPlane_ = Plane(::Vec3_UNIT_Z, Vec3(0, 0, 0));

        _event.subscribe(Event.SCREEN_CHANGED, function(id, data){
            destroyAllEffects();
        }, this);
    }

    function _wrapEffectData(data){
        if(data == null) return data;
        local effectData = data;
        if(typeof effectData != ObjectType.EFFECT_DATA){
            effectData = EffectData(data, null);
        }
        return effectData;
    }

    function _createEffectForId(effectData){
        if(effectData == null){
            return null;
        }
        return Effects[effectData.id](effectData);
    }

    function destroyAllEffects(){
        for(local i = 0; i < mActiveEffects_.len(); i++){
            shutdownEffect_(i);
        }
        mActiveEffects_.clear();
    }

    /**
     * Display an effect and set it to alive.
     *
     * @param1:effectId: The id of the effect to create.
     */
    function displayEffect(effectId){
        local effectData = _wrapEffectData(effectId);
        local effectObject = _createEffectForId(effectData);

        if(!effectObject) return;
        mActiveEffects_.append(effectObject);

        effectObject.setup(effectData.data);
    }

    function endEffect(idx){
        mQueuedDestructionEffects_.append(idx);
    }

    function processEndedEffects(){
        foreach(i in mQueuedDestructionEffects_){
            shutdownEffect_(i);
        }
        mQueuedDestructionEffects_.clear();

        purgeOldEffects_();
    }
    function purgeOldEffects_(){
        while(true){
            local idx = mActiveEffects_.find(null);
            if(idx == null) return

            mActiveEffects_.remove(idx);
        }
    }
    function shutdownEffect_(i){
        mActiveEffects_[i].destroy();
        mActiveEffects_[i] = null;
    }

    function shutdown(){
        foreach(c,i in mActiveEffects_){
            if(i == null) continue;
            shutdownEffect_(c);
        }
        mActiveEffects_.clear();
    }

    function update(){
        local destroyed = false;
        foreach(c,i in mActiveEffects_){
            local result = i.update();
            if(!result){
                endEffect(c);
                destroyed = true;
            }
        }

        if(destroyed){
            processEndedEffects();
        }
    }

    function getWorldPositionForWindowPos(winPos){
        local posX = winPos.x / _window.getWidth();
        local posY = winPos.y / _window.getHeight();

        local ray = ::FGEffectCamera.getCameraToViewportRay(posX, posY);
        local point = ray.intersects(mTestPlane_);
        assert(point != false);
        local windowPoint = ray.getPoint(point);

        return (windowPoint.xy());
    }
};