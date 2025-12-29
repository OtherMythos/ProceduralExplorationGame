#pragma once

#include "System/Util/Collision/CollisionWorldBruteForce.h"

namespace ProceduralExplorationGameCore{

    class CollisionDetectionWorld : public AV::CollisionWorldBruteForce{
    public:
        CollisionDetectionWorld(int worldId);
        ~CollisionDetectionWorld();

        bool checkCollisionPoint(float x, float y, float radius, AV::uint8 mask=0xFF);
        void setCollisionGrid(std::vector<bool>& collisionGrid, int width, int height, int scaleResolution=1);

    private:
        std::vector<bool> mCollisionGrid;

        int mWidth, mHeight;
        int mScaleResolution;
    };

}
