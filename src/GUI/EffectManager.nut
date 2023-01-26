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

    "Effects": array(Screen.MAX, null),

    mActiveEffects_ = null

    function setup(){
        mActiveEffects_ = [];
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

    /**
     * Display and effect and set it to alive.
     * 
     * @param1:effectId: The id of the effect to create.
     * @param2:effectData: wrapped EffectData for both the effect to create as well as its data.
     */
    function displayEffect(effectId){
        local effectData = _wrapEffectData(effectId);
        local effectObject = _createEffectForId(effectData);

        if(!effectObject) return;
        mActiveEffects_.append(effectObject);

        effectObject.setup(effectData.data);
    }

    function update(){
        foreach(i in mActiveEffects_){
            i.update();
        }
    }
};