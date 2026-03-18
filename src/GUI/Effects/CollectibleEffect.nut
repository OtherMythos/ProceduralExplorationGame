const COLLECTIBLE_EFFECT_ITEM_Z = 10;
const COLLECTIBLE_EFFECT_VIBRATION_AMOUNT = 0.10;
const COLLECTIBLE_EFFECT_ROTATION_AMOUNT = 0.1;
const COLLECTIBLE_EFFECT_NUM_BEAMS = 4;
const COLLECTIBLE_EFFECT_BEAM_LENGTH = 5.0;
const COLLECTIBLE_EFFECT_BEAM_THICKNESS = 150;
const COLLECTIBLE_EFFECT_BEAM_TILT_AMOUNT = 0.3; //Radians of tilt applied per beam appearance
const COLLECTIBLE_EFFECT_RETURN_SPEED = 0.08; //How quickly the item tries to return to default orientation each frame


enum CollectibleEffectStages{
    NONE,
    MOVE_TO_CENTRE,
    VIBRATE_AND_ROTATE,
    BREAK,

    MAX
}
local CollectibleEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(CollectibleEffectStages.MAX);
};

{
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.MOVE_TO_CENTRE] = class extends ::Util.State{
        mTotalCount_ = 15
        mNextState_ = CollectibleEffectStages.VIBRATE_AND_ROTATE;
        function start(data){
            //Start at the initial position
        }
        function update(p, data){
            //Interpolate position from start to centre, while scaling in
            local currentPos = data.startPos + (data.centre - data.startPos) * p;
            data.bottle.setPosition(currentPos.x, currentPos.y, COLLECTIBLE_EFFECT_ITEM_Z);

            //Scale in during movement
            local scaleNode = data.bottle.getChild(0);
            local newScale = p * data.scale;
            scaleNode.setScale(newScale, newScale, newScale);
        }
    };
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.VIBRATE_AND_ROTATE] = class extends ::Util.State{
        mTotalCount_ = 100
        mNextState_ = CollectibleEffectStages.BREAK;
        mBeams_ = null;
        mBeamLengthMultipliers_ = null;
        mTiltX_ = 0.0;
        mTiltZ_ = 0.0;

        function start(data){
            data.bottle.setPosition(data.centre.x, data.centre.y, COLLECTIBLE_EFFECT_ITEM_Z);
            mBeams_ = array(COLLECTIBLE_EFFECT_NUM_BEAMS);
            mBeamLengthMultipliers_ = array(COLLECTIBLE_EFFECT_NUM_BEAMS);
            //Random small base tilt so the item never starts perfectly upright
            mTiltX_ = ((rand() % 200) - 100) / 1000.0; //-0.1 to 0.1
            mTiltZ_ = ((rand() % 200) - 100) / 1000.0; //-0.1 to 0.1
            for(local i = 0; i < COLLECTIBLE_EFFECT_NUM_BEAMS; i++){
                mBeams_[i] = null;
                mBeamLengthMultipliers_[i] = 0.5 + (rand() % 1000) / 1000.0; //0.5 to 1.5
            }
        }

        function update(p, data){
            //Apply vibration based on sine wave
            local vibrationX = sin(p * 3.14159 * 8) * COLLECTIBLE_EFFECT_VIBRATION_AMOUNT * data.scale;
            local vibrationY = cos(p * 3.14159 * 8) * COLLECTIBLE_EFFECT_VIBRATION_AMOUNT * data.scale;

            data.bottle.setPosition(data.centre.x + vibrationX, data.centre.y + vibrationY, COLLECTIBLE_EFFECT_ITEM_Z);

            //Tilt returns towards default orientation each frame
            mTiltX_ = mTiltX_ * (1.0 - COLLECTIBLE_EFFECT_RETURN_SPEED);
            mTiltZ_ = mTiltZ_ * (1.0 - COLLECTIBLE_EFFECT_RETURN_SPEED);

            //Create and animate beams progressively
            local beamStartDelay = 0.2; //Delay before first beam appears
            for(local i = 0; i < COLLECTIBLE_EFFECT_NUM_BEAMS; i++){
                local beamStartTime = beamStartDelay + (i * 0.10); //Each beam starts 0.10 of the state later
                if(p >= beamStartTime){
                    if(mBeams_[i] == null){
                        //Create new beam and apply a tilt kick
                        mBeams_[i] = data.effect.createBeam(data, i);
                        local tiltDir = (rand() % 628) / 100.0;
                        mTiltX_ += cos(tiltDir) * COLLECTIBLE_EFFECT_BEAM_TILT_AMOUNT;
                        mTiltZ_ += sin(tiltDir) * COLLECTIBLE_EFFECT_BEAM_TILT_AMOUNT;
                    }

                    //Animate beam - appears more quickly as the state progresses
                    local beamP = (p - beamStartTime) / (1.0 - beamStartTime);
                    if(beamP > 0.0 && beamP < 1.0){
                        local progress = beamP * beamP; //Quadratic easing for acceleration
                        local length = COLLECTIBLE_EFFECT_BEAM_LENGTH * 0.5 + COLLECTIBLE_EFFECT_BEAM_LENGTH * progress * mBeamLengthMultipliers_[i];
                        local scaleNode = mBeams_[i].getChild(0);
                        scaleNode.setScale(4, 4, COLLECTIBLE_EFFECT_BEAM_THICKNESS + COLLECTIBLE_EFFECT_BEAM_THICKNESS);
                    }
                }
            }

            //Apply accumulated tilt to the item's orientation
            local quatX = Quat(mTiltX_, Vec3(1, 0, 0));
            local quatZ = Quat(mTiltZ_, Vec3(0, 0, 1));
            data.bottle.setOrientation(quatX * quatZ);
        }
    };
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.BREAK] = class extends ::Util.State{
        mTotalCount_ = 10
        mNextState_ = CollectibleEffectStages.NONE;
        function start(data){
            //Remove the original bottle and prepare for break animation
            //In future, this will create two broken pieces and animate them
        }
        function update(p, data){
            //Scale down the bottle as it breaks
            local scaleNode = data.bottle.getChild(0);
            local newScale = (1.0 - p) * data.scale;
            scaleNode.setScale(newScale, newScale, newScale);
        }
    };
}

::EffectManager.Effects[Effect.COLLECTABLE_OPEN_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mItem_ = null;
    mVoxItem_ = null;
    mBeamAngles_ = null;

    mCentre_ = Vec2(0, 0);
    mStartPos_ = Vec2(0, 0);
    mScale_ = 1.0;
    mMeshName_ = "collectables.messageInABottle.voxMesh";

    mStateMachine_ = null;

    function setup(data){
        mCentre_ = ::Vec2_ZERO;
        mStartPos_ = ::Vec2_ZERO;
        mBeamAngles_ = array(COLLECTIBLE_EFFECT_NUM_BEAMS);
        if("startPos" in data){
            mStartPos_ = data.startPos;
        }
        if("itemScale" in data){
            mScale_ = data.itemScale;
        }
        if("meshName" in data){
            mMeshName_ = data.meshName;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mItem_ = createVoxelItem(mParentNode_, mStartPos_, mScale_, mMeshName_);

        local stateMachineData = {
            "bottle": mItem_,
            "centre": mCentre_,
            "startPos": mStartPos_,
            "scale": mScale_,
            "effect": this
        };

        mStateMachine_ = CollectibleEffectStateMachine(stateMachineData);
        mStateMachine_.setState(CollectibleEffectStages.MOVE_TO_CENTRE);
    }

    function destroy(){
        mParentNode_.destroyNodeAndChildren();
    }

    function createVoxelItem(parentNode, centre, scale, meshName){
        local itemNode = parentNode.createChildSceneNode();
        local animNode = itemNode.createChildSceneNode();
        mVoxItem_ = _gameCore.createVoxMeshItem(meshName);
        mVoxItem_.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
        animNode.attachObject(mVoxItem_);
        animNode.setScale(scale, scale, scale);

        return itemNode;
    }

    function anglesSimilar(angle1, angle2, margin){
        local diff = fabs(angle1 - angle2);
        //Handle wraparound at 2*PI
        if(diff > 3.14159){
            diff = 6.28318 - diff;
        }
        return diff < margin;
    }

    function generateUniqueAngles(beamIndex, margin){
        local attempts = 0;
        local maxAttempts = 50;

        while(attempts < maxAttempts){
            local angle1 = (rand() % 628) / 100.0;
            local angle2 = (rand() % 628) / 100.0;
            local angle3 = (rand() % 628) / 100.0;

            local isSimilar = false;
            for(local i = 0; i < beamIndex; i++){
                if(mBeamAngles_[i] != null){
                    if(anglesSimilar(angle1, mBeamAngles_[i].angle1, margin) ||
                       anglesSimilar(angle2, mBeamAngles_[i].angle2, margin) ||
                       anglesSimilar(angle3, mBeamAngles_[i].angle3, margin)){
                        isSimilar = true;
                        break;
                    }
                }
            }

            if(!isSimilar){
                return {"angle1": angle1, "angle2": angle2, "angle3": angle3};
            }

            attempts++;
        }

        //Fallback if we can't find unique angles
        return {"angle1": (rand() % 628) / 100.0, "angle2": (rand() % 628) / 100.0, "angle3": (rand() % 628) / 100.0};
    }

    function createBeam(data, beamIndex){
        //Get the AABB of the voxel item to find its centre
        local aabb = mVoxItem_.getLocalAabb();
        local centre = aabb.getCentre();

        //Create a beam node as a child of the item so it inherits rotation/vibration
        local beamNode = mItem_.createChildSceneNode();

        local animNode = beamNode.createChildSceneNode();

        //Create positioning node to offset the beam so its bottom is at the origin
        local positionNode = animNode.createChildSceneNode();
        positionNode.setPosition(0, 0, 1.0);

        //Create a cube for the beam
        local cube = _scene.createItem("cube");
        cube.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
        positionNode.attachObject(cube);

        //Generate unique angles to avoid similar beam directions
        local angleMargin = 0.8; //Radians
        local angles = generateUniqueAngles(beamIndex, angleMargin);
        local randomAngle1 = angles.angle1;
        local randomAngle2 = angles.angle2;
        local randomAngle3 = angles.angle3;

        //Store angles for this beam
        mBeamAngles_[beamIndex] = angles;

        local quat = Quat(randomAngle1, Vec3(1, 0, 0));
        quat = quat * Quat(randomAngle2, Vec3(0, 1, 0));
        //quat = quat * Quat(randomAngle3, Vec3(0, 0, 1));
        beamNode.setOrientation(quat);

        //Position at the item centre plus a slight offset
        local offsetAmount = 0.5;
        local offset = Vec3(
            cos(randomAngle1) * offsetAmount,
            sin(randomAngle2) * offsetAmount,
            cos(randomAngle3) * offsetAmount
        );
        beamNode.setPosition(centre.x + offset.x, centre.y + offset.y, centre.z + offset.z);

        //Initially scaled to a small size, will grow during animation
        animNode.setScale(0.1, 0.1, 0.1);

        return beamNode;
    }

    function update(){
        return mStateMachine_.update();
    }
};
