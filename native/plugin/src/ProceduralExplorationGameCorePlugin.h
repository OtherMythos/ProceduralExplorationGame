#pragma once

#include "System/Plugins/Plugin.h"

namespace ProceduralExplorationGamePlugin{

    class ProceduralExplorationGameCorePlugin : public AV::Plugin {
    public:
        ProceduralExplorationGameCorePlugin();
        ~ProceduralExplorationGameCorePlugin();

        virtual void initialise() override;
    };
}
