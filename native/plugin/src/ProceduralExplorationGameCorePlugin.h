#pragma once

#include "System/Plugins/Plugin.h"

namespace Ogre{
    class MovableObjectFactory;
}

namespace ProceduralExplorationGamePlugin{

    class ProceduralExplorationGameCorePlugin : public AV::Plugin {
    public:
        ProceduralExplorationGameCorePlugin();
        ~ProceduralExplorationGameCorePlugin();

        virtual void initialise() override;
        virtual void shutdown() override;

    private:
        Ogre::MovableObjectFactory* mMovableFactory;
    };
}
