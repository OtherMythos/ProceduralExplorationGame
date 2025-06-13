#include "GameplayConstants.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    GameplayConstants::PlacesVec GameplayConstants::mPlaces;
    GameplayConstants::PlacesByTypeVec GameplayConstants::mPlacesByType;

    const GameplayConstants::PlacesVec& GameplayConstants::getPlaces() { return GameplayConstants::mPlaces; }
    const GameplayConstants::PlacesByTypeVec& GameplayConstants::getPlacesByType() { return GameplayConstants::mPlacesByType; }

    void GameplayConstants::initialise(){
        //mPlaces.resize((size_t)PlaceId::MAX);
        //#include "../../../src/Content/PlaceDefs.h.nut"

        /*
        mPlacesByType.resize((size_t)PlaceType::MAX);
        for(size_t i = 0; i < (size_t)PlaceId::MAX; i++){
            const PlaceDef& p = mPlaces[i];
            mPlacesByType[(size_t)p.t].push_back(i);
        }
         */
    }

}
