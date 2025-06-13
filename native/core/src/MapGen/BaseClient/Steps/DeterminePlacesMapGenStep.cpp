#if 0
#include "DeterminePlacesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "GameplayConstants.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    DeterminePlacesMapGenStep::DeterminePlacesMapGenStep() : MapGenStep("Determine Places"){

    }

    DeterminePlacesMapGenStep::~DeterminePlacesMapGenStep(){

    }

    LandId determinePlaces_determineLandmassForPlace(const std::vector<FloodFillEntry*>& landData, ExplorationMapGenWorkspace* workspace, PlaceId placeId){
        const PlaceDef& place = GameplayConstants::getPlaces()[(size_t)placeId];
        PlaceType placeType = place.t;
        if(placeType == PlaceType::CITY || placeType == PlaceType::GATEWAY){
            //This being the largest landmass, place the city there.
            return 0;
        }
        LandId retLandmass = findRandomLandmassForSize(landData, workspace->landWeighted, place.minLandmass);

        return retLandmass;
    }
    WorldPoint determinePlaces_determinePointForPlace(const std::vector<FloodFillEntry*>& landData, LandId landmass){
        static const float RADIUS = 10;
        for(int i = 0; i < 100; i++){
            WorldPoint intended = findRandomPointInLandmass(landData[landmass]);
            WorldCoord intendedX, intendedY;
            READ_WORLD_POINT(intended, intendedX, intendedY);
            //Try another point if it collides with the pre-existing points.
            //if(collisionWorld.checkCollisionPoint(intendedX, intendedY, RADIUS)) continue;
            //if(!checkPointValidForFlags(noiseBlob, intended, MapVoxelTypes.RIVER)) continue;
            //collisionWorld.addCollisionPoint(intendedX, intendedY, RADIUS);
            return intended;
        }
        return INVALID_WORLD_POINT;
    }
    bool determinePlaces_place(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace, PlaceId id, PlaceData* outData){
        const std::vector<FloodFillEntry*>& landData = (*mapData->ptr<std::vector<FloodFillEntry*>>("landData"));

        LandId landmassId = determinePlaces_determineLandmassForPlace(mapData, workspace, id);
        if(landmassId == INVALID_LAND_ID) return false;
        if(landmassId > landData.size()) return false;
        const FloodFillEntry* landmass = landData[landmassId];

        WorldPoint point = INVALID_WORLD_POINT;
        if(id == PlaceId::GATEWAY){
            point = mapData->gatewayPosition;
        }else{
            point = determinePlaces_determinePointForPlace(landData, landmassId);
        }

        if(point == INVALID_WORLD_POINT) return false;

        //Determine the region.
        const AV::uint8* regionPtr = REGION_PTR_FOR_COORD_CONST(landData, point);
        RegionId region = *(regionPtr);

        WorldCoord xx, yy;
        READ_WORLD_POINT(point, xx, yy);
        outData->originX = static_cast<AV::uint16>(xx);
        outData->originY = static_cast<AV::uint16>(yy);
        outData->region = region;
        outData->type = id;

        return true;
    }

    void DeterminePlacesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const GameplayConstants::PlacesByTypeVec& placesByType = GameplayConstants::getPlacesByType();
        const GameplayConstants::PlacesVec& places = GameplayConstants::getPlaces();
        for(size_t c = ((size_t)PlaceType::NONE)+1; c < (size_t)PlaceType::MAX; c++){
            AV::uint16 currentFrequency = input->placeFrequency[c];
            for(AV::uint16 i = 0; i < currentFrequency; i++){
                const std::vector<size_t> placesForType = placesByType[c];
                if(placesForType.size() == 0) break;
                size_t targetIndex = mapGenRandomIndex(placesForType);
                size_t targetPlace = placesForType[targetIndex];
                assert(targetPlace != 0);
                PlaceData d;
                bool success = determinePlaces_place(mapData, workspace, (PlaceId)targetPlace, &d);
                if(success){
                    mapData->placeData.push_back(d);
                }
            }
        }
    }

}

#endif