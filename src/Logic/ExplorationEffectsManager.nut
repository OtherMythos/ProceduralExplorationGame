enum ExplorationEffects{

    HEALTH_DAMAGE,

    MAX

};

::ExplorationEffectsManager <- class{

    Effects = null;
    mActiveEffects_ = null;

    constructor(){
        mActiveEffects_ = array(ExplorationEffects.MAX, 0);

        Effects = array(ExplorationEffects.MAX);
        Effects[ExplorationEffects.HEALTH_DAMAGE] = {
            "time": 30,
            "update": function(time){
                local material = _graphics.getMaterialByName("Postprocess/GameplayEffects");
                local gpuParams = material.getFragmentProgramParameters(0, 0);

                local anim = 0.0;
                if(time > 25){
                    anim = ::calculateSimpleAnimationInRange(1.0, 0.0, time, 25, 30);
                }else{
                    anim = ::calculateSimpleAnimationInRange(0.0, 1.0, time, 0, 25);
                }
                gpuParams.setNamedConstant("amount", anim);
            }
        };
    }

    function update(){
        local activeEffect = false;
        foreach(c,i in mActiveEffects_){
            if(i == 0) continue;

            activeEffect = true;
            Effects[c].update(i);
            mActiveEffects_[c]--;
        }

        if(!activeEffect){
            ::CompositorManager.setGameplayEffectsActive(false);
        }
    }

    function activateEffect(effect){
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            return;
        }
        ::CompositorManager.setGameplayEffectsActive(true);

        mActiveEffects_[effect] = Effects[effect].time;
    }

};