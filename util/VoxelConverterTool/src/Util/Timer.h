#pragma once

#include <chrono>
#include <iostream>

namespace VoxelConverterTool{

    class Timer{
    public:
        Timer();
        ~Timer();

        void start();
        void stop();

        float getTimeTotal() const;

        friend std::ostream& operator << (std::ostream& o, const Timer &t);

    private:
        std::chrono::high_resolution_clock::time_point mBegin;
        std::chrono::high_resolution_clock::time_point mEnd;
        bool mRunning;
    };

}

