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

function GenericPlacement(world, entityFactory, node, placeData, idx){
    return entityFactory.constructPlace(placeData, idx);
}

function GoblinCampPlacement(world, entityFactory, node, placeData, idx){
    //local entry = ActiveEnemyEntry(entityFactory.mConstructorWorld_, placeData.placeId, null, null);

    local parentNode = node.createChildSceneNode();

    local voxPos = Vec3(placeData.originX, 0, -placeData.originY);

    entityFactory.constructSimpleItem(parentNode, "goblinTotem.voxMesh", voxPos + Vec3(4, 0, 3), 0.15);
    entityFactory.constructSimpleItem(parentNode, "goblinTent.voxMesh", voxPos, 0.3);
    entityFactory.constructSimpleItem(parentNode, "campfireBase.voxMesh", voxPos + Vec3(1, 0, 6), 0.4);

    world.createEnemy(EnemyId.GOBLIN, voxPos + Vec3(3, 0, 4));
    world.createEnemy(EnemyId.GOBLIN, voxPos + Vec3(-3, 0, 3));
    if(_random.randInt(0, 3) == 0){
        world.createEnemy(EnemyId.GOBLIN, voxPos + Vec3(-3, 0, -4));
    }

    return null;
}

::Places <- array(PlaceId.MAX, null);

::Places[PlaceId.NONE] = PlaceDef("None", "None", PlaceType.NONE, 0.0, null, 0);

::Places[PlaceId.GATEWAY] = PlaceDef("Gateway", "Gateway", PlaceType.GATEWAY, 1.0, GenericPlacement, 0);

::Places[PlaceId.GOBLIN_CAMP] = PlaceDef("Goblin Camp", "Spooky goblin camp", PlaceType.LOCATION, 1.0, GoblinCampPlacement, 0);

::PlacesByType <- {};

function initialisePlacesLists(){
    for(local i = 0; i < PlaceType.MAX; i++){
        ::PlacesByType[i] <- [];
    }
    foreach(c,i in ::Places){
        ::PlacesByType[i.getType()].append(c);
    }
}

initialisePlacesLists();