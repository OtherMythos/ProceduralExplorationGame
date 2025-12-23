enum MessageInABottleEvents{
    PLAYER_NEAR,
    PLAYER_FAR
};

::MessageInABottleScript <- class{

    driftDirection = null;
    driftDuration = 0;
    maxDriftDuration = 300;
    movementSpeed = 0.01;

    constructor(eid){
        //Initialize with a random direction
        local angle = _random.rand() * PI * 2.0;
        driftDirection = Vec3(cos(angle), 0, sin(angle));
        driftDuration = maxDriftDuration;
    }

    function update(eid){
        //Update drift direction periodically
        driftDuration--;
        if(false && driftDuration <= 0){
            local angle = _random.rand() * PI * 2.0;
            driftDirection = Vec3(cos(angle), 0, sin(angle));
            maxDriftDuration = 150 + _random.randInt(150);
            driftDuration = maxDriftDuration;
        }

        if(driftDirection != null){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            //local currentPos = world.getEntityManager().getPosition(eid);
            world.getEntityManager().moveEntityCheckPotential(eid, (driftDirection * movementSpeed));
        }
    }

    function destroyed(eid, reason){
        //Cleanup handled by entity manager
    }
};
