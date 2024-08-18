#include "VisitedPlacesParser.h"

#include "VisitedPlacesPrerequisites.h"

#include "TerrainChunkFileHandler.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    VisitedPlacesParser::VisitedPlacesParser()
        : mMapData(0)
    {

    }

    VisitedPlacesParser::~VisitedPlacesParser(){

    }

    int VisitedPlacesParser::getCurrentStage() const{
        return mCurrentStage;
    }

    void VisitedPlacesParser::beginMapGen(const std::string& mapName){
        assert(!mMapData);
        mMapData = new VisitedPlaceMapData();
        mMapData->mapName = mapName;
        mParentThread = new std::thread(&VisitedPlacesParser::beginMapGen_, this, mapName);
    }

    void VisitedPlacesParser::beginMapGen_(const std::string& mapName){
        TerrainChunkFileHandler handler("res://build/assets/maps/");
        handler.readMapData(mMapData, mapName);
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
