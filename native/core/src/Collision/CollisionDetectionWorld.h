#pragma once

#include "System/Util/Collision/CollisionWorldBruteForce.h"

namespace ProceduralExplorationGameCore{

    class CollisionDetectionWorld : public AV::CollisionWorldBruteForce{
    public:
        CollisionDetectionWorld(int worldId);
        ~CollisionDetectionWorld();

        bool checkCollisionPoint(float x, float y, float radius);

    };

}