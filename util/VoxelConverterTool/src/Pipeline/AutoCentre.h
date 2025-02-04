#pragma once

namespace VoxelConverterTool{

    struct ParsedVoxFile;

    class AutoCentre{
    public:
        AutoCentre();
        ~AutoCentre();

        void centreForParsedFile(ParsedVoxFile& p);
    };

}
