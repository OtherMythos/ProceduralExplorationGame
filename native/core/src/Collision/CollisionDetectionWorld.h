#pragma once

#include "System/Util/Collision/CollisionWorldBruteForce.h"

namespace ProceduralExplorationGameCore{

    class CollisionDetectionWorld : public AV::CollisionWorldBruteForce{
    public:
        CollisionDetectionWorld(int worldId);
        ~CollisionDetectionWorld();

        bool checkCollisionPoint(float x, float y, float radius);
        void setCollisionGrid(std::vector<bool>& collisionGrid, int width, int height);

    private:
        std::vector<bool> mCollisionGrid;

        int mWidth, mHeight;
    };

}
