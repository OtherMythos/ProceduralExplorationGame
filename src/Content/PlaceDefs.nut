::testPlaceDefs <- {
function initialisePlacesLists(){
    for(local i = 0; i < PlaceType.MAX; i++){
        ::PlacesByType[i] <- [];
    }
    foreach(c,i in ::Places){
        ::PlacesByType[i.getType()].append(c);
    }
}

function initialisePlaceEditorMeta(){
    if(!getroottable().rawin("_system")){
        //Determine which environment this is being executed in.
        //Don't process this if we're in the map gen vm.
        return;
    }

    //Write the values to the array
    local placeData = array(::Places.len() * 7);
    local count = 0;
    foreach(c,i in ::Places){
        local placeFile = i.getPlaceFileName();
        if(placeFile == null) continue;
        local path = "res://build/assets/places/"+placeFile+"/editorMeta.json";
        if(!_system.exists(path)){
            continue;
        }
        local jsonTable = _system.readJSONAsTable(path);

        local centreX = jsonTable.centreX
        local centreY = jsonTable.centreY;
        local centreZ = jsonTable.centreZ;

        local halfX = jsonTable.halfX
        local halfY = jsonTable.halfY;
        local halfZ = jsonTable.halfZ;

        local radius = jsonTable.radius;

        i.mCentre = Vec3(centreX, centreY, centreZ);
        i.mHalf = Vec3(halfX, halfY, halfZ);
        i.mRadius = radius;

        local count = c * 7;
        placeData[count] = centreX;
        placeData[count + 1] = centreY;
        placeData[count + 2] = centreZ;
        placeData[count + 3] = halfX;
        placeData[count + 4] = halfY;
        placeData[count + 5] = halfZ;
        placeData[count + 6] = radius;
    }

    _gameCore.deepCopyToMapGenVM("placeData", placeData);
}
};

::Places <- array(PlaceId.MAX, null);

::Places[PlaceId.NONE] = PlaceDef("None", "None", PlaceType.NONE, 0.0, null, 0);

::Places[PlaceId.GATEWAY] = PlaceDef("Gateway", "Gateway", PlaceType.GATEWAY, 1.0, "gateway", 0);

::Places[PlaceId.GOBLIN_CAMP] = PlaceDef("Goblin Camp", "Spooky goblin camp", PlaceType.LOCATION, 1.0, "goblinCampsite", 100);
::Places[PlaceId.DUSTMITE_NEST] = PlaceDef("Dust Mite Nest", "An entrance to a Dust Mite nest.", PlaceType.LOCATION, 1.0, "dustMiteNest", 100);
::Places[PlaceId.GARRITON] = PlaceDef("Garriton", "A nice town", PlaceType.LOCATION, 1.0, "testPlace", 100);
::Places[PlaceId.TEMPLE] = PlaceDef("Temple", "Some sort of temple", PlaceType.LOCATION, 1.0, "temple", 100);
::Places[PlaceId.GRAVEYARD] = PlaceDef("Graveyard", "An old graveyard", PlaceType.LOCATION, 1.0, "graveyard", 100);

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