#pragma once

namespace ProceduralExplorationGameCore{

    class PerlinNoise{
    public:
        PerlinNoise(int seed);

        float perlin2d(float x, float y, float freq, int depth);

    private:
        int mSeed;
    };

}