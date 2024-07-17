#include "DeterminePlacesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "GameplayConstants.h"

namespace ProceduralExplorationGameCore{

    DeterminePlacesMapGenStep::DeterminePlacesMapGenStep(){

    }

    DeterminePlacesMapGenStep::~DeterminePlacesMapGenStep(){

    }

    LandId determinePlaces_determineLandmassForPlace(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace, PlaceId placeId){
        const PlaceDef& place = GameplayConstants::getPlaces()[(size_t)placeId];
        PlaceType placeType = place.t;
        if(placeType == PlaceType::CITY || placeType == PlaceType::GATEWAY){
            //This being the largest landmass, place the city there.
            return 0;
        }
        LandId retLandmass = findRandomLandmassForSize(mapData->landData, workspace->landWeighted, place.minLandmass);

        return retLandmass;
    }
    WorldPoint determinePlaces_determinePointForPlace(ExplorationMapData* mapData, LandId landmass){
        static const float RADIUS = 10;
        for(int i = 0; i < 100; i++){
            WorldPoint intended = findRandomPointInLandmass(mapData->landData[landmass]);
            AV::uint32 intendedX, intendedY;
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
        LandId landmassId = determinePlaces_determineLandmassForPlace(mapData, workspace, id);
        if(landmassId == INVALID_LAND_ID) return false;
        const FloodFillEntry* landmass = mapData->landData[landmassId];

        WorldPoint point = INVALID_WORLD_POINT;
        if(id == PlaceId::GATEWAY){
            point = mapData->gatewayPosition;
        }else{
            point = determinePlaces_determinePointForPlace(mapData, landmassId);
        }

        if(point == INVALID_WORLD_POINT) return false;

        //Determine the region.
        const AV::uint8* regionPtr = REGION_PTR_FOR_COORD_CONST(mapData, point);
        RegionId region = *(regionPtr);

        AV::uint32 xx;
        AV::uint32 yy;
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
        for(size_t c = 0; c < (int)PlaceType::MAX; c++){
            AV::uint16 currentFrequency = input->placeFrequency[c];
            for(AV::uint16 i = 0; i < currentFrequency; i++){
                //To get around the NONE.
                const std::vector<size_t> placesForType = placesByType[c];
                if(placesForType.size() == 0) break;
                size_t targetPlace = mapGenRandomIndex(placesForType);
                const PlaceDef& place = places[targetPlace];
                PlaceData d;
                bool success = determinePlaces_place(mapData, workspace, (PlaceId)targetPlace, &d);
                if(success){
                    mapData->placeData.push_back(d);
                }
            }
        }
    }

}
