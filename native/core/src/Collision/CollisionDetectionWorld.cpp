#include "CollisionDetectionWorld.h"

namespace ProceduralExplorationGameCore{

    CollisionDetectionWorld::CollisionDetectionWorld(int worldId)
        : AV::CollisionWorldBruteForce(worldId) {

    }

    CollisionDetectionWorld::~CollisionDetectionWorld(){

    }

    bool CollisionDetectionWorld::checkCollisionPoint(float x, float y, float radius){
        return CollisionWorldBruteForce::checkCollisionPoint(x, y, radius);
    }

}
