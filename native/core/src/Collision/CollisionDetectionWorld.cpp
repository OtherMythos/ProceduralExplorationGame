#include "CollisionDetectionWorld.h"

namespace ProceduralExplorationGameCore{

    CollisionDetectionWorld::CollisionDetectionWorld(int worldId, int width, int height)
        : AV::CollisionWorldBruteForce(worldId),
        mWidth(width),
        mHeight(height) {

    }

    CollisionDetectionWorld::~CollisionDetectionWorld(){

    }

    bool CollisionDetectionWorld::checkCollisionPoint(float x, float y, float radius){
        bool pointCheck = CollisionWorldBruteForce::checkCollisionPoint(x, y, radius);

        if(mCollisionGrid.empty()) return pointCheck;

        for(int yy = int(y - radius); yy < int(y + radius); yy++){
            for(int xx = int(x - radius); xx < int(x + radius); xx++){
                int xxx = xx / 5;
                int yyy = yy / 5;
                if(xxx < 0 || yyy < 0 || xxx >= mWidth || yyy >= mHeight) continue;
                if(mCollisionGrid[xxx + yyy * width]){
                    return true;
                }
            }
        }

        return false;
    }

    void CollisionDetectionWorld::setCollisionGrid(std::vector<bool>& collisionGrid){
        mCollisionGrid = std::move(collisionGrid);
    }

}
