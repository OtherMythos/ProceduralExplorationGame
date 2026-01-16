#include "PlacedItemManager.h"

#include <algorithm>
#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

void PlacedItemManager::initialiseGrid(AV::uint32 width, AV::uint32 height){
    mWidth_ = width;
    mHeight_ = height;
    mGrid_.clear();
    mGrid_.resize(static_cast<size_t>(width) * height, 0);
    mPlacedItems_.clear();
}

void PlacedItemManager::registerPlacedItem(AV::uint32 placedItemId, AV::uint64 eid, AV::uint32 x, AV::uint32 y){
    if(x >= mWidth_ || y >= mHeight_){
        return;
    }

    size_t index = static_cast<size_t>(x) + static_cast<size_t>(y) * mWidth_;
    mGrid_[index] = eid;

    WorldPoint worldPoint = WRAP_WORLD_POINT(x, y);
    mPlacedItems_[eid] = {placedItemId, worldPoint};
}

void PlacedItemManager::removePlacedItem(AV::uint64 eid){
    auto it = mPlacedItems_.find(eid);
    if(it == mPlacedItems_.end()){
        return;
    }

    //Find and clear from grid
    auto gridIt = std::find(mGrid_.begin(), mGrid_.end(), eid);
    if(gridIt != mGrid_.end()){
        *gridIt = 0;
    }

    mPlacedItems_.erase(it);
}

const PlacedItemEntry* PlacedItemManager::getPlacedItem(AV::uint64 eid) const{
    auto it = mPlacedItems_.find(eid);
    if(it == mPlacedItems_.end()){
        return nullptr;
    }
    return &it->second;
}

AV::uint64 PlacedItemManager::getPlacedItemAtPosition(AV::uint32 x, AV::uint32 y) const{
    if(x >= mWidth_ || y >= mHeight_){
        return 0;
    }

    size_t index = static_cast<size_t>(x) + static_cast<size_t>(y) * mWidth_;
    return mGrid_[index];
}

std::vector<AV::uint64> PlacedItemManager::getPlacedItemsInRadius(float x, float y, float radius) const{
    std::vector<AV::uint64> result;

    //Calculate bounding box in grid coordinates
    int minX = static_cast<int>(x - radius);
    int maxX = static_cast<int>(x + radius);
    int minY = static_cast<int>(y - radius);
    int maxY = static_cast<int>(y + radius);

    //Clamp to grid bounds
    if(minX < 0) minX = 0;
    if(maxX >= static_cast<int>(mWidth_)) maxX = mWidth_ - 1;
    if(minY < 0) minY = 0;
    if(maxY >= static_cast<int>(mHeight_)) maxY = mHeight_ - 1;

    //Pre-calculate radius squared to avoid square root
    float radiusSquared = radius * radius;

    //Iterate over bounding box
    for(int gridY = minY; gridY <= maxY; ++gridY){
        for(int gridX = minX; gridX <= maxX; ++gridX){
            AV::uint64 eid = getPlacedItemAtPosition(static_cast<AV::uint32>(gridX), static_cast<AV::uint32>(gridY));
            if(eid == 0) continue; //No item at this position

            //Check if this grid position is within the circle
            float dx = static_cast<float>(gridX) - x;
            float dy = static_cast<float>(gridY) - y;
            float distanceSquared = dx * dx + dy * dy;

            if(distanceSquared <= radiusSquared){
                result.push_back(eid);
            }
        }
    }

    return result;
}

}
