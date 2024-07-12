#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"
#include "ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    class Biome{
    public:
        typedef MapVoxelTypes (*DetermineVoxFunction)(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData);
        typedef void (*PlaceObjectFunction)(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture);

        Biome(DetermineVoxFunction voxFunction, PlaceObjectFunction placementFunction);
        ~Biome();

        static const Biome& getBiomeForId(RegionType regionId);

    private:
        DetermineVoxFunction mVoxFunction;
        PlaceObjectFunction mPlacementFunction;

    public:
        DetermineVoxFunction getVoxFunction() const { return mVoxFunction; }
        PlaceObjectFunction getPlacementFunction() const { return mPlacementFunction; }
    };

};