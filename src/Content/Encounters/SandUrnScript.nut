enum SandUrnEvents{
    PLAYER_NEAR,
    PLAYER_FAR
};

::SandUrnScript <- class{

    driftDirection = null;
    driftDuration = 0;
    maxDriftDuration = 900;
    movementSpeed = 0.003; //Much slower than message in a bottle

    constructor(eid){
        //Initialize with a random direction
        local angle = _random.rand() * PI * 2.0;
        driftDirection = Vec3(cos(angle), 0, sin(angle));
        driftDuration = maxDriftDuration;
    }

    function update(eid){
        //Update drift direction periodically
        driftDuration--;
        if(driftDuration <= 0){
            local angle = _random.rand() * PI * 2.0;
            driftDirection = Vec3(cos(angle), 0, sin(angle));
            maxDriftDuration = 150 + _random.randInt(150);
            driftDuration = maxDriftDuration;
        }

        if(driftDirection != null){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            world.getEntityManager().moveEntityCheckPotential(eid, (driftDirection * movementSpeed));

            //Update z position to match terrain height
            local currentPos = world.getEntityManager().getPosition(eid);
            currentPos.y = world.getZForPos(currentPos);
            world.getEntityManager().setEntityPosition(eid, currentPos);
        }
    }

    function destroyed(eid, reason){
        //Cleanup handled by entity manager
    }
};
