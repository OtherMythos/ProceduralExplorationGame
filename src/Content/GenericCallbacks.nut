::GenericCallbacks <- {
    function placeBeaconDistance(entityManager, eid, distance){
        //printf("distance " + distance.tostring());
        local datablockComp = entityManager.getComponent(eid, EntityComponents.DATABLOCK);
        local diffuse = (distance / 100.0);
        diffuse = diffuse < 0.0 ? 0.0 : diffuse;
        diffuse = diffuse > 1.0 ? 1.0 : diffuse
        datablockComp.mDatablock.setTransparency(diffuse * 0.5, _PBS_TRANSPARENCY_FADE);

        //local distanceMod = (distance / 100.0);
        //distanceMod = distanceMod < 0.0 ? 0.0 : distanceMod;
        //distanceMod = distanceMod > 1.0 ? 1.0 : distanceMod
        //local node = entityManager.getComponent(eid, EntityComponents.SCENE_NODE).mNode;
        //node.getChild(0).setScale(distanceMod * 1.5, 100, distanceMod * 1.5);
    }
};