#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"

#include <vector>
#include <map>
#include <cstdint>

namespace ProceduralExplorationGameCore{

    struct PlacedItemEntry{
        AV::uint32 placedItemId;
        WorldPoint worldPoint;
    };

    class PlacedItemManager{
    public:
        PlacedItemManager() = default;
        ~PlacedItemManager() = default;

        //Initialise the grid with given dimensions
        void initialiseGrid(AV::uint32 width, AV::uint32 height);

        //Register a placed item
        void registerPlacedItem(AV::uint32 placedItemId, AV::uint64 eid, AV::uint32 x, AV::uint32 y);

        //Remove a placed item
        void removePlacedItem(AV::uint64 eid);

        //Get placed item by EID
        const PlacedItemEntry* getPlacedItem(AV::uint64 eid) const;

        //Get EID at grid position (0 if none)
        AV::uint64 getPlacedItemAtPosition(AV::uint32 x, AV::uint32 y) const;

        //Get all placed items within a radius
        std::vector<AV::uint64> getPlacedItemsInRadius(float x, float y, float radius) const;

        //Get a random placed item EID (returns 0 if none exist)
        AV::uint64 getRandomPlacedItem() const;

    private:
        std::vector<AV::uint64> mGrid_;
        std::map<AV::uint64, PlacedItemEntry> mPlacedItems_;
        AV::uint32 mWidth_ = 0;
        AV::uint32 mHeight_ = 0;
    };

}
