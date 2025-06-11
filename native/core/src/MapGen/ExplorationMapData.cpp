#include "ExplorationMapData.h"

namespace ProceduralExplorationGameCore{

    MapDataReadResult ExplorationMapData::readEntry(std::string name, MapDataEntry *outEntry, MapDataEntryType expectedType) const{

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

    void ExplorationMapData::setEntry(std::string name, MapDataEntry entry){
        mEntries[name] = entry;
    }

    AV::uint32 ExplorationMapData::uint32(std::string name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::UINT32));

        return out.value.uint32;
    }

    void ExplorationMapData::uint32(std::string name, AV::uint32 val){
        setEntry(name, {MapDataEntryType::UINT32, val});
    }


    size_t ExplorationMapData::sizeType(std::string name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::SIZE_TYPE));

        return out.value.size;
    }

    void ExplorationMapData::sizeType(std::string name, size_t val){
        MapDataEntry d;
        d.value.size = val;
        d.type = MapDataEntryType::SIZE_TYPE;
        setEntry(name, d);
    }


    void* ExplorationMapData::voidPtr(std::string name) const{
        MapDataEntry out;
        MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::VOID_PTR));

        return out.value.ptr;
    }

    void ExplorationMapData::voidPtr(std::string name, void* val){
        MapDataEntry d;
        d.value.ptr = val;
        d.type = MapDataEntryType::VOID_PTR;
        setEntry(name, d);
    }

}
