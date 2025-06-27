#pragma once

#include "MapGenStep.h"

#include <string>

namespace ProceduralExplorationGameCore{

    class MapGenStepMarker : public MapGenStep{
    public:
        MapGenStepMarker(const std::string& name);
    };

}
