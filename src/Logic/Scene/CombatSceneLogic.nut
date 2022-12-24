/**
 * Logic for combat scenes, specifically things like positioning enemy models in the scene, animating them, etc.
 */
::CombatSceneLogic <- class{

    mCombatData_ = null;

    mParentNode_ = null;
    mEnemyEntries = null;

    SceneEnemyEntry = class{
        mParent_ = null;
        mAnim_ = null;

        mAnimCount = 0.0;

        constructor(parentNode, childNode){
            mParent_ = parentNode;
            mAnim_ = childNode;

            #Seed with a random value for some variation.
            mAnimCount = _random.rand();
        }

        function updateAnim(){
            mAnimCount += 0.15;
            local nodePos = Vec3(0, fabs(sin(mAnimCount)), 0);
            mAnim_.setPosition(nodePos);
        }
    }

    constructor(combatData){
        mCombatData_ = combatData;

        setup();
    }

    function setup(){
        mEnemyEntries = [];

        createScene();
    }

    function shutdown(){
        mParentNode_.destroyNodeAndChildren();
    }

    function update(){
        animateEnemies();
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        createLights_();
        createEnemies_();
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

            local entry = SceneEnemyEntry(sceneNode, animNode);
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
        parentNode.attachObject(item);
        return item.getLocalRadius();
    }

};