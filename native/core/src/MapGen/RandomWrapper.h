#pragma once

#include <random>

namespace ProceduralExplorationGameCore{

    class RandomWrapper{
    public:
        RandomWrapper();
        ~RandomWrapper();

        static RandomWrapper singleton;

        size_t rand();
        void seed(unsigned int seed);

    private:
        std::mt19937* engine;
    };

}
