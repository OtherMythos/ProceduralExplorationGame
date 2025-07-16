#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"
#include "ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    class Biome{
    public:
        struct BiomeColour{
            float r, g, b, a;
        };
        typedef MapVoxelTypes (*DetermineVoxFunction)(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData);
        typedef AV::uint8 (*DetermineAltitudeFunction)(AV::uint8 altitude, AV::uint8 moisture, AV::uint8 regionDistance, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData);
        typedef void (*PlaceObjectFunction)(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance);
        typedef void (*FinalVoxChangeFunction)(const ExplorationMapData* mapData, AV::uint32* vox, AV::uint32* secondary, AV::uint16 x, AV::uint16 y);
        typedef BiomeColour (*WaterTextureColourFunction)(bool mask, const ExplorationMapData* mapData);

        Biome(DetermineVoxFunction voxFunction, PlaceObjectFunction placementFunction, DetermineAltitudeFunction altitudeFunction, FinalVoxChangeFunction finalVoxFunction, WaterTextureColourFunction waterTexFunction);
        ~Biome();

        static const Biome& getBiomeForId(RegionType regionId);

    private:
        DetermineVoxFunction mVoxFunction;
        DetermineAltitudeFunction mAltitudeFunction;
        PlaceObjectFunction mPlacementFunction;
        FinalVoxChangeFunction mFinalVoxChangeFunction;
        WaterTextureColourFunction mWaterTextureColourFunction;

    public:
        DetermineVoxFunction getVoxFunction() const { return mVoxFunction; }
        PlaceObjectFunction getPlacementFunction() const { return mPlacementFunction; }
        DetermineAltitudeFunction getAltitudeFunction() const { return mAltitudeFunction; }
        FinalVoxChangeFunction getFinalVoxFunction() const { return mFinalVoxChangeFunction; }
        WaterTextureColourFunction getWaterTextureColourFunction() const { return mWaterTextureColourFunction; }
    };

};
