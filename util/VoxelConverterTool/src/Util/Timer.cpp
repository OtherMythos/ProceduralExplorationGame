#include "Timer.h"

namespace VoxelConverterTool{
    Timer::Timer()
    : mRunning(false){
        mBegin = std::chrono::high_resolution_clock::now();
        mEnd = mBegin;
    }

    Timer::~Timer(){

    }

    void Timer::start(){
        mRunning = true;
        mBegin = std::chrono::high_resolution_clock::now();
    }

    void Timer::stop(){
        mEnd = std::chrono::high_resolution_clock::now();
        mRunning = false;
    }

    float Timer::getTimeTotal() const{
        std::chrono::duration<float> duration = std::chrono::duration_cast<std::chrono::nanoseconds>(mEnd - mBegin);

        return duration.count();
    }

    std::ostream& operator << (std::ostream& o, const Timer &t){
        o << t.getTimeTotal();
        return o;
    }
}
