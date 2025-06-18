#pragma once

#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <vector>

namespace ProceduralExplorationGameCore{

    class GameplayConstants{
    public:
        GameplayConstants() = delete;
        ~GameplayConstants() = delete;

        static void initialise();

        typedef std::vector<PlaceDef> PlacesVec;
        typedef std::vector<size_t> PlaceForTypeVec;
        typedef std::vector<PlaceForTypeVec> PlacesByTypeVec;
    private:
        static PlacesVec mPlaces;
        static PlacesByTypeVec mPlacesByType;

    public:
        static const PlacesVec& getPlaces();
        static const PlacesByTypeVec& getPlacesByType();
    };

}
