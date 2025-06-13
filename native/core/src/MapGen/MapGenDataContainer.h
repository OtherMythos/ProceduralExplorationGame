#pragma once

#include <map>
#include <vector>
#include <cassert>

#include "GamePrerequisites.h"

namespace ProceduralExplorationGameCore{

    enum class MapDataEntryType{
        ANY,

        UINT32,
        WORLD_POINT,
        VOID_PTR,
        SIZE_TYPE
    };
    union MapDataEntryValue{
        AV::uint32 uint32;
        WorldPoint worldPoint;
        void* ptr;
        size_t size;
    };
    enum class MapDataReadResult{
        SUCCESS,
        TYPE_MISMATCH,
        NOT_FOUND
    };

    struct MapDataEntry{
        MapDataEntryType type;
        MapDataEntryValue value;
    };

    #define MAP_ASSERT_RESULT(XX) \
        MapDataReadResult __mapError = XX; \
        assert(__mapError == MapDataReadResult::SUCCESS);

    /**
    A class to store map gen values that can be read easily from both c++ and Squirrel scripts.
    Entires are separated into data types and id'd with a key, similar to how scripts work.
    This also improves extendability for mods.
    */
    class MapGenDataContainer{
    private:
        std::map<std::string, MapDataEntry> mEntries;
    public:

        MapDataReadResult readEntry(const std::string& name, MapDataEntry* outEntry, MapDataEntryType expectedType = MapDataEntryType::ANY) const;

        void setEntry(const std::string& name, MapDataEntry entry);

        AV::uint32 uint32(const std::string& name) const;
        void uint32(const std::string& name, AV::uint32 val);

        size_t sizeType(const std::string& name) const;
        void sizeType(const std::string& name, size_t val);

        void* voidPtr(const std::string& name) const;
        void voidPtr(const std::string& name, void* val);

        template <typename T>
        T* ptr(const std::string& name){
            MapDataEntry out;
            MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::VOID_PTR));

            return reinterpret_cast<T*>(out.value.ptr);
        }

        WorldPoint worldPoint(const std::string& name) const;
        void worldPoint(const std::string& name, WorldPoint val);
    };
}
