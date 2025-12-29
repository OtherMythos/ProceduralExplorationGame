#include "CollisionDetectionWorld.h"

namespace ProceduralExplorationGameCore{

    CollisionDetectionWorld::CollisionDetectionWorld(int worldId)
        : AV::CollisionWorldBruteForce(worldId), mScaleResolution(1) {

    }

    CollisionDetectionWorld::~CollisionDetectionWorld(){

    }

    bool CollisionDetectionWorld::checkCollisionPoint(float x, float y, float radius, AV::uint8 mask){
        bool pointCheck = CollisionWorldBruteForce::checkCollisionPoint(x, y, radius, mask);

        if(mCollisionGrid.empty()) return pointCheck;

        for(int yy = int(y - radius); yy < int(y + radius); yy++){
            for(int xx = int(x - radius); xx < int(x + radius); xx++){
                //Scale the position based on the resolution scale
                int scaledX = xx * mScaleResolution / 5;
                int scaledY = yy * mScaleResolution / 5;
                if(scaledX < 0 || scaledY < 0 || scaledX >= mWidth || scaledY >= mHeight) continue;
                if(mCollisionGrid[scaledX + scaledY * mWidth]){
                    return true;
                }
            }
        }

        return pointCheck;
    }

    void CollisionDetectionWorld::setCollisionGrid(std::vector<bool>& collisionGrid, int width, int height, int scaleResolution){
        mWidth = width;
        mHeight = height;
        mScaleResolution = scaleResolution;
        mCollisionGrid = std::move(collisionGrid);
    }

}
