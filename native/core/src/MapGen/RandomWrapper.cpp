#include "RandomWrapper.h"

namespace ProceduralExplorationGameCore{

    RandomWrapper RandomWrapper::singleton;

    RandomWrapper::RandomWrapper()
        : engine(0) {
    }

    RandomWrapper::~RandomWrapper(){
        if(engine){
            delete engine;
        }
    }

    size_t RandomWrapper::rand(){
        return (*engine)();
    }

    void RandomWrapper::seed(unsigned int seed){
        if(engine){
            delete engine;
        }
        engine = new std::mt19937(seed);
    }

}
