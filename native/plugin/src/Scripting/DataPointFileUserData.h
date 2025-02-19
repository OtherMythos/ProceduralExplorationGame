#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"
#include "GamePrerequisites.h"

namespace ProceduralExplorationGameCore{
    class DataPointFileHandler;
}

namespace ProceduralExplorationGamePlugin{
    class DataPointFileParserUserData{
    public:
        DataPointFileParserUserData() = delete;
        ~DataPointFileParserUserData() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);

        struct WrappedDataPointFile{
            std::vector<ProceduralExplorationGameCore::DataPointData> data;
            ProceduralExplorationGameCore::DataPointFileHandler* file;
        };

        static void dataPointFileHandlerToUserData(HSQUIRRELVM vm, WrappedDataPointFile* fileHandler);

        static AV::UserDataGetResult readDataPointFileHandlerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, WrappedDataPointFile** outFileHandler);

    private:
        static SQObject DataPointFileDelegateTableObject;

        static SQInteger readFile(HSQUIRRELVM vm);
        static SQInteger getNumDataPoints(HSQUIRRELVM vm);
        static SQInteger getDataPointAt(HSQUIRRELVM vm);


        static SQInteger DataPointFileHandlerReleaseHook(SQUserPointer p, SQInteger size);
    };
}
