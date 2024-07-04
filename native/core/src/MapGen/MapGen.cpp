#include "MapGen.h"

#include <thread>

namespace ProceduralExplorationGameCore{

    MapGen::MapGen(){

    }

    MapGen::~MapGen(){

    }

    int MapGen::getCurrentStage() const{
        return mCurrentStage;
    }

    void MapGen::beginMapGen(){
        std::thread* parentThread = new std::thread(&MapGen::beginMapGen_, this);

    }

    //TODO remove
    static const int TEMP_END_NUM = 5;
    void MapGen::beginMapGen_(){

        for(int i = 0; i < TEMP_END_NUM; i++){
            std::this_thread::sleep_for(std::chrono::milliseconds(1000));

            mCurrentStage++;
        }
    }

    int MapGen::getNumTotalStages(){
        return TEMP_END_NUM;
    }

    bool MapGen::isFinished() const{
        return mCurrentStage >= TEMP_END_NUM;
    };
};
