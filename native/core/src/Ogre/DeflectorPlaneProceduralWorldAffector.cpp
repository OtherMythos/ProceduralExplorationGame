/*
-----------------------------------------------------------------------------
Implementation of DeflectorPlaneProceduralWorldAffector
-----------------------------------------------------------------------------
*/
#include "DeflectorPlaneProceduralWorldAffector.h"

#include "OgreParticle.h"
#include "OgreParticleSystem.h"
#include "OgreStringConverter.h"
#include "GameplayState.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "OgreMath.h"

namespace Ogre
{
    class ParticleWrapper : public Ogre::Particle{
    public:
        Ogre::ParticleSystem* getParentSystem(){
            return mParentSystem;
        }
    };

    //Instantiate statics
    DeflectorPlaneProceduralWorldAffector::CmdBounce DeflectorPlaneProceduralWorldAffector::msBounceCmd;

    //-----------------------------------------------------------------------
    DeflectorPlaneProceduralWorldAffector::DeflectorPlaneProceduralWorldAffector(ParticleSystem *psys):
        ParticleAffector(psys),
        mBounce(1.0)
    {
        mType = "DeflectorPlaneProceduralWorld";

        //Set up parameters
        if(createParamDictionary("DeflectorPlaneProceduralWorldAffector"))
        {
            addBaseParameters();
            //Add extra parameters
            ParamDictionary *dict = getParamDictionary();
            dict->addParameter(
                ParameterDef("bounce",
                              "The amount of bouncing when a particle is deflected. 0 means no "
                              "deflection and 1 stands for 100 percent reflection.",
                              PT_REAL),
                &msBounceCmd);
        }
    }
    //-----------------------------------------------------------------------
    float DeflectorPlaneProceduralWorldAffector::calculateWorldYFromHeight(Ogre::Vector3 parentPos, Ogre::Vector3 parentScale, Ogre::Vector3 particlePos)
    {
        ProceduralExplorationGameCore::ExplorationMapData* mapData = ProceduralExplorationGameCore::GameplayState::getMapData();
        if(!mapData)
        {
            return 0.0f;
        }

        //Convert particle position to world coordinates
        int worldX = static_cast<int>(Math::Abs(particlePos.x));
        int worldZ = static_cast<int>(Math::Abs(particlePos.z));

        //Clamp to map bounds
        if(worldX >= static_cast<int>(mapData->width))
            worldX = mapData->width - 1;
        if(worldZ >= static_cast<int>(mapData->height))
            worldZ = mapData->height - 1;

        //Create world point and query height
        ProceduralExplorationGameCore::WorldPoint point = ProceduralExplorationGameCore::WRAP_WORLD_POINT(worldX, worldZ);
        const AV::uint8* heightPtr = ProceduralExplorationGameCore::VOX_PTR_FOR_COORD_CONST(mapData, point);
        AV::uint8 height = *heightPtr;

        const AV::uint32 WORLD_DEPTH = 20;
        const AV::uint32 ABOVE_GROUND = 0xFF - mapData->seaLevel;
        const float PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4;

        //Set Y position based on terrain height minus sea level
        int yVal = static_cast<int>(((static_cast<float>(height) - mapData->seaLevel) / (float)ABOVE_GROUND) * (float)WORLD_DEPTH);
        yVal = yVal < 0 ? 0 : yVal;
        float finalY = 0.5 + (float)yVal * PROCEDURAL_WORLD_UNIT_MULTIPLIER;

        return finalY;
    }
    //-----------------------------------------------------------------------
    void DeflectorPlaneProceduralWorldAffector::_affectParticles(ParticleSystem *pSystem, Real timeElapsed)
    {
        ParticleIterator pi = pSystem->_getIterator();

        Ogre::Vector3 parentPos = pSystem->getParentSceneNode()->_getDerivedPositionUpdated();
        Ogre::Vector3 parentScale = pSystem->getParentSceneNode()->_getDerivedScaleUpdated();

        Vector3 directionPart;

        while(!pi.end())
        {
            Particle *p = pi.getNext();

            //Calculate the terrain Y value at this particle's XZ position
            float terrainY = calculateWorldYFromHeight(parentPos, parentScale, p->mPosition);

            //Adjust terrain Y to particle's local space
            //float terrainYLocal = (terrainY / parentScale.y) - (parentPos.y / parentScale.y);
            float terrainYLocal = terrainY;
            terrainYLocal += 0.3;

            Vector3 direction(p->mDirection * timeElapsed);

            //Check if particle has crossed below terrain
            if(p->mPosition.y + direction.y <= terrainYLocal)
            {
                Real a = p->mPosition.y - terrainYLocal;
                if(a < 0.0)
                {
                    //for intersection point
                    directionPart = direction * (-a / (direction.y != 0.0 ? direction.y : 1.0));
                    //set new position
                    p->mPosition = (p->mPosition + directionPart) +
                                   ((directionPart - direction) * mBounce);

                    //reflect direction vector in Y axis
                    p->mDirection.y = (-p->mDirection.y) * mBounce;
                }
            }
        }
    }
    //-----------------------------------------------------------------------
    void DeflectorPlaneProceduralWorldAffector::setBounce(Real bounce) { mBounce = bounce; }
    //-----------------------------------------------------------------------
    Real DeflectorPlaneProceduralWorldAffector::getBounce() const { return mBounce; }

    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    //Command objects
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    String DeflectorPlaneProceduralWorldAffector::CmdBounce::doGet(const void *target) const
    {
        return StringConverter::toString(
            static_cast<const DeflectorPlaneProceduralWorldAffector *>(target)->getBounce());
    }
    void DeflectorPlaneProceduralWorldAffector::CmdBounce::doSet(void *target, const String &val)
    {
        static_cast<DeflectorPlaneProceduralWorldAffector *>(target)->setBounce(StringConverter::parseReal(val));
    }

}  // namespace Ogre
