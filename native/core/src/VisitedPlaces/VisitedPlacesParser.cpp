#include "VisitedPlacesParser.h"

#include "VisitedPlacesPrerequisites.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    VisitedPlacesParser::VisitedPlacesParser(){

    }

    VisitedPlacesParser::~VisitedPlacesParser(){

    }

    int VisitedPlacesParser::getCurrentStage() const{
        return mCurrentStage;
    }

    void VisitedPlacesParser::beginMapGen(const std::string& mapName){
        assert(!mMapData);
        mMapData = new VisitedPlaceMapData();
        mParentThread = new std::thread(&VisitedPlacesParser::beginMapGen_, this, mapName);
    }

    void VisitedPlacesParser::beginMapGen_(const std::string& mapName){
        mCurrentStage++;
    }

    bool VisitedPlacesParser::isFinished() const{
        return mCurrentStage >= 1;
    };

    VisitedPlaceMapData* VisitedPlacesParser::claimMapData(){
        if(!isFinished()) return 0;
        mParentThread->join();
        delete mParentThread;
        VisitedPlaceMapData* out = mMapData;
        mMapData = 0;
        return out;
    }

};
