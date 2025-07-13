#include "MapGenDataContainer.h"

namespace ProceduralExplorationGameCore{

    MapDataReadResult MapGenDataContainer::readEntry(const std::string& name, MapDataEntry *outEntry, MapDataEntryType expectedType) const{

        auto it = mEntries.find(name);
        if(it == mEntries.end()){
            return MapDataReadResult::NOT_FOUND;
        }

        const MapDataEntry& entry = it->second;

        if(expectedType != MapDataEntryType::ANY){
            if(entry.type != expectedType){
                return MapDataReadResult::TYPE_MISMATCH;
            }
        }

        *outEntry = entry;

        return MapDataReadResult::SUCCESS;
    }

    bool MapGenDataContainer::hasEntry(const std::string& name){
        MapDataEntry e;
        return readEntry(name, &e, MapDataEntryType::ANY) == MapDataReadResult::SUCCESS;
    }

    void MapGenDataContainer::setEntry(const std::string& name, MapDataEntry entry){
        mEntries[name] = entry;
    }

    AV::uint32 MapGenDataContainer::uint32(const std::string& name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::UINT32));

        return out.value.uint32;
    }

    void MapGenDataContainer::uint32(const std::string& name, AV::uint32 val){
        setEntry(name, {MapDataEntryType::UINT32, val});
    }


    size_t MapGenDataContainer::sizeType(const std::string& name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::SIZE_TYPE));

        return out.value.size;
    }

    void MapGenDataContainer::sizeType(const std::string& name, size_t val){
        MapDataEntry d;
        d.value.size = val;
        d.type = MapDataEntryType::SIZE_TYPE;
        setEntry(name, d);
    }


    void* MapGenDataContainer::voidPtr(const std::string& name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::VOID_PTR));

        return out.value.ptr;
    }

    void MapGenDataContainer::voidPtr(const std::string& name, void* val){
        MapDataEntry d;
        d.value.ptr = val;
        d.type = MapDataEntryType::VOID_PTR;
        setEntry(name, d);
    }


    WorldPoint MapGenDataContainer::worldPoint(const std::string& name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::WORLD_POINT));

        return out.value.worldPoint;
    }

    void MapGenDataContainer::worldPoint(const std::string& name, WorldPoint val){
        MapDataEntry d;
        d.value.worldPoint = val;
        d.type = MapDataEntryType::WORLD_POINT;
        setEntry(name, d);
    }

}
