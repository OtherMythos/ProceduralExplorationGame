/**
 * Logic for combat scenes, specifically things like positioning enemy models in the scene, animating them, etc.
 */
::CombatSceneLogic <- class{

    mCombatData_ = null;

    mParentNode_ = null;
    mEnemyEntries = null;
    mPlayerEntry = null;

    mPlayerParentNode_ = null;

    SceneActorEntry = class{
        mParent_ = null;
        mAnim_ = null;

        mAnimCount_ = 0.0;
        mCurrentAnim_ = CombatOpponentAnims.NONE;

        constructor(parentNode, childNode){
            mParent_ = parentNode;
            mAnim_ = childNode;

            setAnim(CombatOpponentAnims.HOPPING);
            #Seed with a random value for some variation.
            mAnimCount_ = _random.rand();
        }

        function updateAnim(){
            mAnimCount_ += 0.01;
            switch(mCurrentAnim_){
                case CombatOpponentAnims.HOPPING:{
                    local anim = mAnimCount_ * 15;
                    local nodePos = Vec3(0, fabs(sin(anim)), 0);
                    mAnim_.setPosition(nodePos);
                    return;
                }
                case CombatOpponentAnims.DYING:{
                    local anim = mAnimCount_ * 8;
                    if(anim < 1.5){
                        local newOrientation = Quat(-anim, Vec3(0, 0, 1));
                        mAnim_.setOrientation(newOrientation);
                    }else{
                        setAnim(CombatOpponentAnims.NONE)
                    }
                    return;
                }
                case CombatOpponentAnims.NONE:
                default:{
                    return;
                }
            }
        }

        function setAnim(anim){
            mCurrentAnim_ = anim;
            mAnimCount_ = 0;
        }

        function notifyDeath(){
            setAnim(CombatOpponentAnims.DYING)
        }

        function getCentre(){
            local item = mAnim_.getAttachedObject(0)
            return item.getLocalRadius();
        }
    }

    constructor(combatData){
        mCombatData_ = combatData;
    }

    function setup(){
        mEnemyEntries = [];
        print("Creating combat scene");
        createScene();
        createPlayerScene();
    }

    function shutdown(){
        mParentNode_.destroyNodeAndChildren();
        mPlayerParentNode_.destroyNodeAndChildren();
        mParentNode_ = null;
        mPlayerParentNode_ = null;

        mEnemyEntries.clear();
        mPlayerEntry = null;
    }

    function update(){
        animateEnemies();
        mPlayerEntry.updateAnim();
    }

    function notifyOpponentDied(opponentId){
        local enemy = mEnemyEntries[opponentId];
        enemy.notifyDeath();
    }

    function createPlayerScene(){
        mPlayerParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        local animNode = mPlayerParentNode_.createChildSceneNode();
        local item = _scene.createItem("player.mesh");
        item.setRenderQueueGroup(25);
        animNode.attachObject(item);

        mPlayerEntry = SceneActorEntry(mPlayerParentNode_, animNode);

        {
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.COMBAT_PLAYER)
            assert(camera != null);
            local parentNode = camera.getParentNode();
            local centre = mPlayerEntry.getCentre();
            parentNode.setPosition(0, centre, 25);
            camera.lookAt(0, centre, 0);
        }
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        createLights_();
        createEnemies_();

        {
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.COMBAT)
            assert(camera != null);
            local parentNode = camera.getParentNode();
            parentNode.setPosition(5, 10, 30);
            camera.lookAt(0, 0, 0);
        }
    }

    function createEnemies_(){
        local parent = mParentNode_.createChildSceneNode();

        local radius = 0.0;
        local totalRadius = 0.0;
        foreach(c,i in mCombatData_.mOpponentStats){
            local sceneNode = parent.createChildSceneNode();
            local animNode = sceneNode.createChildSceneNode();

            radius = createEnemy_(animNode, i);
            sceneNode.setPosition(totalRadius, 0, 0);
            totalRadius += radius * 1.8;

            local entry = SceneActorEntry(sceneNode, animNode);
            mEnemyEntries.append(entry);
        }
        #TODO clean this up.
        parent.setPosition(-totalRadius / 2 + (radius*1.8) / 2, -radius / 2, 0);
    }

    function animateEnemies(){
        foreach(i in mEnemyEntries){
            i.updateAnim();
        }
    }

    function createLights_(){
        local light = _scene.createLight();
        local lightNode = mParentNode_.createChildSceneNode();
        lightNode.attachObject(light);

        light.setType(_LIGHT_DIRECTIONAL);
        light.setDirection(-1, -1, -1);
        light.setPowerScale(PI);

        _scene.setAmbientLight(0xffffffff, 0xffffffff, Vec3(0, 1, 0));
    }

    function createEnemy_(parentNode, combatStats){
        local item = _scene.createItem("goblin.mesh");
        item.setRenderQueueGroup(20);
        parentNode.attachObject(item);
        return item.getLocalRadius();
    }

};