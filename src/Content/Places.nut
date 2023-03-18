//TODO This should be PlaceId to match items.
//Consider wrapping defs around a mutable wrapper same as items.
enum Place{
    NONE,
    HAUNTED_WELL,
    DARK_CAVE,
    GOBLIN_VILLAGE,
    WIND_SWEPT_BEACH,

    ROTHERFORD,

    MAX
};

enum PlaceType{
    NONE,
    CITY,
    TOWN,
    VILLAGE,
    LOCATION,

    MAX
};

//Squirrel doesn't let you shift bits in place :( so this will do fine.
enum PlaceNecessaryFeatures{
    RIVER = 0x1,
    OCEAN = 0x2,
    LAKE = 0x4,
};

::PlaceDef <- class{
    mName = null;
    mDesc = null;
    mType = null;
    mRarity = null;
    mMinLandmass = 10;
    mNecessaryFeatures = 0;

    constructor(name, desc, placeType, rarity, minLandmass = 10, necessaryFeatures = 0){
        mName = name;
        mDesc = desc;
        mType = placeType;
        mRarity = rarity;
        mMinLandmass = minLandmass;
        mNecessaryFeatures = necessaryFeatures;
    }

    function getName(){ return mName; }
    function getDescription(){ return mDesc; }
    function getType(){ return mType; }
    function getRarity(){ return mRarity; }
    function getMinLandmass(){ return mMinLandmass; }
    function getNecessaryFeatures(){ return mNecessaryFeatures; }

    function _tostring(){
        return ::wrapToString(::PlaceDef, "Place", getName());
    }
}

::Places <- array(Place.MAX, null);

//-------------------------------
::Places[Place.NONE] = PlaceDef("None", "None", PlaceType.NONE, 0.0, 0);
::Places[Place.HAUNTED_WELL] = PlaceDef("Haunted Well", "The old haunted well.", PlaceType.LOCATION, 0.1, 10);
::Places[Place.DARK_CAVE] = PlaceDef("Dark Cave", "A dark opening to a secluded cave.", PlaceType.LOCATION, 0.1, 10);
::Places[Place.GOBLIN_VILLAGE] = PlaceDef("Goblin Village", "The grotty and ramsacked goblin village.", PlaceType.VILLAGE, 0.1, 10);
::Places[Place.WIND_SWEPT_BEACH] = PlaceDef("Wind Swept Beach", "Grey, damp, and sandy.", PlaceType.LOCATION, 0.1, 10, PlaceNecessaryFeatures.OCEAN);
::Places[Place.ROTHERFORD] = PlaceDef("Rotherford", "The old town of rotherford", PlaceType.TOWN, 0.1, 10, PlaceNecessaryFeatures.RIVER | PlaceNecessaryFeatures.OCEAN);
//-------------------------------

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