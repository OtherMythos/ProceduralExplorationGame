#include "VisitedPlacesParser.h"

#include "VisitedPlacesPrerequisites.h"

#include "TerrainChunkFileHandler.h"
#include "TileDataParser.h"
#include "DataPointFileHandler.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    std::string VisitedPlacesParser::mMapsDirectory = "res://build/assets/maps/";

    VisitedPlacesParser::VisitedPlacesParser()
        : mMapData(0),
        mCurrentStage(0)
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
        TerrainChunkFileHandler handler(mMapsDirectory);
        handler.readMapData(mMapData, mapName);

        TileDataParser tileData(mMapsDirectory);
        tileData.readMapData(mMapData, mapName);

        DataPointFileHandler dataPointHandler(mMapsDirectory);
        dataPointHandler.readMapData(mMapData, mapName);

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
