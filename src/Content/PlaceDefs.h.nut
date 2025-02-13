/*
#pragma once

#define PlaceIdConst(XX, YY) PlaceId YY
#define PlaceTypeConst(XX, YY) PlaceType YY
#define DEFINE_PLACE(XX, YY) mPlaces[(size_t)XX] = YY;

DEFINE_PLACE(PlaceIdConst(PlaceId.NONE, ::NONE), PlaceDef("None", "None", PlaceTypeConst(PlaceType.NONE, ::NONE), 0.0, 0));

DEFINE_PLACE(PlaceIdConst(PlaceId.GATEWAY, ::GATEWAY), PlaceDef("Gateway", "Gateway", PlaceTypeConst(PlaceType.GATEWAY, ::GATEWAY), 1.0, 0));

DEFINE_PLACE(PlaceIdConst(PlaceId.HAUNTED_WELL, ::HAUNTED_WELL), PlaceDef("Haunted Well", "The old haunted well.", PlaceTypeConst(PlaceType.LOCATION, ::LOCATION), 0.1, 10));
DEFINE_PLACE(PlaceIdConst(PlaceId.DARK_CAVE, ::DARK_CAVE), PlaceDef("Dark Cave", "A dark opening to a secluded cave.", PlaceTypeConst(PlaceType.LOCATION, ::LOCATION), 0.1, 10));
DEFINE_PLACE(PlaceIdConst(PlaceId.GOBLIN_VILLAGE, ::GOBLIN_VILLAGE), PlaceDef("Goblin Village", "The grotty and ramsacked goblin village.", PlaceTypeConst(PlaceType.VILLAGE, ::VILLAGE), 0.1, 10));
DEFINE_PLACE(PlaceIdConst(PlaceId.WIND_SWEPT_BEACH, ::WIND_SWEPT_BEACH), PlaceDef("Wind Swept Beach", "Grey, damp, and sandy.", PlaceTypeConst(PlaceType.LOCATION, ::LOCATION), 0.1, 10, 0));
DEFINE_PLACE(PlaceIdConst(PlaceId.ROTHERFORD, ::ROTHERFORD), PlaceDef("Rotherford", "The old town of rotherford", PlaceTypeConst(PlaceType.TOWN, ::TOWN), 0.1, 10, 0 | 0));

DEFINE_PLACE(PlaceIdConst(PlaceId.CITY_1, ::CITY_1), PlaceDef("City1", "City1", PlaceTypeConst(PlaceType.CITY, ::CITY), 0.1, 50));
DEFINE_PLACE(PlaceIdConst(PlaceId.CITY_2, ::CITY_2), PlaceDef("City2", "City2", PlaceTypeConst(PlaceType.CITY, ::CITY), 0.1, 50));
DEFINE_PLACE(PlaceIdConst(PlaceId.CITY_3, ::CITY_3), PlaceDef("City3", "City3", PlaceTypeConst(PlaceType.CITY, ::CITY), 0.1, 50));

DEFINE_PLACE(PlaceIdConst(PlaceId.TOWN_1, ::TOWN_1), PlaceDef("Town1", "Town1", PlaceTypeConst(PlaceType.TOWN, ::TOWN), 0.1, 30));
DEFINE_PLACE(PlaceIdConst(PlaceId.TOWN_2, ::TOWN_2), PlaceDef("Town1", "Town1", PlaceTypeConst(PlaceType.TOWN, ::TOWN), 0.1, 30));
DEFINE_PLACE(PlaceIdConst(PlaceId.TOWN_3, ::TOWN_3), PlaceDef("Town1", "Town1", PlaceTypeConst(PlaceType.TOWN, ::TOWN), 0.1, 30));

DEFINE_PLACE(PlaceIdConst(PlaceId.VILLAGE_1, ::VILLAGE_1), PlaceDef("Village1", "Village1", PlaceTypeConst(PlaceType.VILLAGE, ::VILLAGE), 0.1, 30));
DEFINE_PLACE(PlaceIdConst(PlaceId.VILLAGE_2, ::VILLAGE_2), PlaceDef("Village2", "Village2", PlaceTypeConst(PlaceType.VILLAGE, ::VILLAGE), 0.1, 30));
DEFINE_PLACE(PlaceIdConst(PlaceId.VILLAGE_3, ::VILLAGE_3), PlaceDef("Village3", "Village3", PlaceTypeConst(PlaceType.VILLAGE, ::VILLAGE), 0.1, 30));

DEFINE_PLACE(PlaceIdConst(PlaceId.LOCATION_1, ::LOCATION_1), PlaceDef("Dungeon", "Dungeon", PlaceTypeConst(PlaceType.LOCATION, ::LOCATION), 0.1, 10));


//#undef PlaceId.
//#undef PlaceType.
#undef DEFINE_PLACE

*/
//TODO sort the need for this thing out.
::testPlaceDefs <-{
function GenericPlacement(world, entityFactory, node, placeData, idx){
    return entityFactory.constructPlace(placeData, idx);
}

function GoblinCampPlacement(world, entityFactory, node, placeData, idx){
    //local entry = ActiveEnemyEntry(entityFactory.mConstructorWorld_, placeData.placeId, null, null);

    local parentNode = node.createChildSceneNode();

    local voxPos = Vec3(placeData.originX, 0, -placeData.originY);

    //Ensure the instances are unique.
    local spoils = function(){
        return [
            SpoilsEntry(SPOILS_ENTRIES.COINS, 3 + _random.randInt(3)),
        ];
    };

    entityFactory.constructSimpleItem(parentNode, "goblinTotem.voxMesh", voxPos + Vec3(4, 0, 3), 0.15, 0.05, spoils(), 10);
    local campfireEntity = entityFactory.constructSimpleItem(parentNode, "campfireBase.voxMesh", voxPos + Vec3(1, 0, 6), 0.4, null, spoils(), 10);
    //Attach the smoke particle effect to the fire.
    {
        local campfireNode = world.getEntityManager().getComponent(campfireEntity, EntityComponents.SCENE_NODE).mNode;
        local particleSystem = _scene.createParticleSystem("goblinBonfireSmoke");
        local animNode = campfireNode.createChildSceneNode();
        animNode.attachObject(particleSystem);
        particleSystem.fastForward(10);
    }

    local s = spoils();
    if(_random.randInt(3) == 0){
        s.append(
            SpoilsEntry(SPOILS_ENTRIES.SPAWN_ENEMIES, 1)
        );
    }
    entityFactory.constructSimpleItem(parentNode, "goblinTent.voxMesh", voxPos, 0.3, 2.5, s, 10);

    return null;
}

function GoblinCampAppearFunction(world, placeId, pos){
    world.createEnemy(EnemyId.GOBLIN, pos + Vec3(3, 0, 4));
    world.createEnemy(EnemyId.GOBLIN, pos + Vec3(-3, 0, 3));
    if(_random.randInt(0, 3) == 0){
        world.createEnemy(EnemyId.GOBLIN, pos + Vec3(-3, 0, -4));
    }
}

function DustMiteNestPlacement(world, entityFactory, node, placeData, idx){
    local parentNode = node.createChildSceneNode();
    local voxPos = Vec3(placeData.originX, 0, -placeData.originY);

    local teleData = {
        "actionType": ActionSlotType.DESCEND,
        "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
        "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
        "seed": _random.randInt(1000),
        "radius": 6,
        "width": 50,
        "height": 50
    };
    entityFactory.constructSimpleTeleportItem(parentNode, "dustMiteNest.voxMesh", voxPos, 0.5, teleData, 4);

    local spread = 7;
    for(local i = 0; i < 4 + _random.randInt(3); i++){
        local s = spread + _random.rand() * 10;
        local randDir = (_random.rand()*2-1) * PI;
        local dir = (Vec3(sin(randDir) * s, 0, cos(randDir) * s));
        local targetPos = voxPos + dir;
        local orientation = Quat(-PI/(_random.rand()*1.5+1), ::Vec3_UNIT_X);
        orientation *= Quat(_random.rand()*PI - PI/2, ::Vec3_UNIT_Y);
        local model = _random.randInt(4) == 0 ? "skeletonBody.voxMesh" : "skeletonHead.voxMesh";
        entityFactory.constructSimpleItem(parentNode, model, targetPos, 0.15, null, null, 10, orientation);
    }
}
function DustMiteNestAppearFunction(world, placeId, pos){
}

function GarritonPlacement(world, entityFactory, node, placeData, idx){
    local parentNode = node.createChildSceneNode();
    local voxPos = Vec3(placeData.originX, 0, -placeData.originY);

    /*
    local teleData = {
        "actionType": ActionSlotType.DESCEND,
        "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
        "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
        "seed": _random.randInt(1000),
        "radius": 6,
        "width": 50,
        "height": 50
    };
    entityFactory.constructSimpleTeleportItem(parentNode, "house1.voxMesh", voxPos, 0.5, teleData, 4);
    */

    local teleData = {
        "actionType": ActionSlotType.ENTER,
        "worldType": WorldTypes.VISITED_LOCATION_WORLD,
        "radius": 6,
        "mapName": "houseInterior"
    };
    local triggerWorld = world.getTriggerWorld();
    entityFactory.constructSimpleItem(parentNode, "house1.voxMesh", voxPos + Vec3(-10, 0, 0), 0.6, 7, null, null, null, Vec3(0, 0, 4));
    local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, voxPos.x, voxPos.z, 4, _COLLISION_PLAYER);

    entityFactory.constructSimpleItem(parentNode, "house1.voxMesh", voxPos + Vec3(30, 0, -20), 0.6, 7, null, null, null, Vec3(0, 0, 4));



}

function TemplePlacement(world, entityFactory, node, placeData, idx){
    local parentNode = node.createChildSceneNode();
    local voxPos = Vec3(placeData.originX, 0, -placeData.originY);

    local width = 1;
    local height = 1;
    local inv = array(width * height, null);
    inv[0] = ::Item(ItemId.BOOK_OF_GOBLIN_STORIES);
    entityFactory.constructChestObjectInventory(voxPos, parentNode, inv, width, height);

}

function initialisePlacesLists(){
    for(local i = 0; i < PlaceType.MAX; i++){
        ::PlacesByType[i] <- [];
    }
    foreach(c,i in ::Places){
        ::PlacesByType[i.getType()].append(c);
    }
}

function initialisePlaceEditorMeta(){
    foreach(c,i in ::Places){
        local placeFile = i.getPlaceFileName();
        if(placeFile == null) continue;
        local path = "res://build/assets/places/"+placeFile+"/editorMeta.json";
        if(!_system.exists(path)){
            continue;
        }
        local jsonTable = _system.readJSONAsTable(path);
        i.mCentre = Vec3(jsonTable.centreX, jsonTable.centreY, jsonTable.centreZ);
        i.mHalf = Vec3(jsonTable.halfX, jsonTable.halfY, jsonTable.halfZ);
        i.mRadius = jsonTable.radius;
    }
}
};

::Places <- array(PlaceId.MAX, null);

::Places[PlaceId.NONE] = PlaceDef("None", "None", PlaceType.NONE, 0.0, null, null, null, 0);

::Places[PlaceId.GATEWAY] = PlaceDef("Gateway", "Gateway", PlaceType.GATEWAY, 1.0, testPlaceDefs.GenericPlacement, null, null, 0);

::Places[PlaceId.GOBLIN_CAMP] = PlaceDef("Goblin Camp", "Spooky goblin camp", PlaceType.LOCATION, 1.0, testPlaceDefs.GoblinCampPlacement, testPlaceDefs.GoblinCampAppearFunction, null, 100);
::Places[PlaceId.DUSTMITE_NEST] = PlaceDef("Dust Mite Nest", "An entrance to a Dust Mite nest.", PlaceType.LOCATION, 1.0, testPlaceDefs.DustMiteNestPlacement, testPlaceDefs.DustMiteNestAppearFunction, null, 100);
::Places[PlaceId.GARRITON] = PlaceDef("Garriton", "A nice town", PlaceType.LOCATION, 1.0, null, null, "testPlace", 100);
::Places[PlaceId.TEMPLE] = PlaceDef("Temple", "Some sort of temple", PlaceType.LOCATION, 1.0, null, null, "temple", 100);

::PlacesByType <- {};

::getMapNameForPlace_ <- function(placeId){
    switch(placeId){
        case PlaceId.DUSTMITE_NEST:{
            return "chestLocationFirst";
        }
        default:{
            return null;
        }
    }
}


testPlaceDefs.initialisePlacesLists();
testPlaceDefs.initialisePlaceEditorMeta();