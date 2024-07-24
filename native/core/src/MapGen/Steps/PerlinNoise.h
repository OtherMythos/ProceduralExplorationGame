#pragma once

namespace ProceduralExplorationGameCore{

    class PerlinNoise{
    public:
        PerlinNoise(int seed);

        float perlin2d(float x, float y, float freq, int depth);

    private:
        int mSeed;

        int noise2(int seed, int x, int y);
        float lin_inter(float x, float y, float s);
        float smooth_inter(float x, float y, float s);
        float noise2d(int seed, float x, float y);
    };

}