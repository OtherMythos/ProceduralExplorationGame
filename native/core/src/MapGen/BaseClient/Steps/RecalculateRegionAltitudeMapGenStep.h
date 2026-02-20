#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{
    class RecalculateRegionAltitudeMapGenStep : public MapGenStep{
    public:
        RecalculateRegionAltitudeMapGenStep();
        ~RecalculateRegionAltitudeMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };
}
