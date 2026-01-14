//Definition structure for camera effects
local CameraEffectDef = class{
    mId = null;
    mEffectClass = null;

    constructor(id, effectClass){
        mId = id;
        mEffectClass = effectClass;
    }

    function createEffect(cameraEffectManager, animationNode, params){
        return mEffectClass(cameraEffectManager, animationNode, params);
    }
};

::CameraEffects <- array(CameraEffectId.MAX, null);

//-------------------------------

//SHAKE camera effect with default parameters.
//Params: {magnitude, duration, frequency}
::CameraEffects[CameraEffectId.SHAKE] = CameraEffectDef(CameraEffectId.SHAKE, ::CameraShakeEffect);

//-------------------------------
