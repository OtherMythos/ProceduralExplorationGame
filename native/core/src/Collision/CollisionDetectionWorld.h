#pragma once

#include "System/Util/Collision/CollisionWorldBruteForce.h"

namespace ProceduralExplorationGameCore{

    class CollisionDetectionWorld : public AV::CollisionWorldBruteForce{
    public:
        CollisionDetectionWorld(int worldId, int width, int height);
        ~CollisionDetectionWorld();

        bool checkCollisionPoint(float x, float y, float radius);
        void setCollisionGrid(std::vector<bool>& collisionGrid);

    private:
        std::vector<bool> mCollisionGrid;

        int mWidth, mHeight;
    };

}
