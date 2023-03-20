enum PlaceId{
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

::Place <- class{
    mPlaceId_ = PlaceId.NONE;
    mPlace_ = null;
    mData_ = null;

    function getData() { return mData_; }
    function isNone() { return mPlaceId_ == PlaceId.NONE; }
    function getDef(){ return mItem_; }

    function getName(){ return mPlace.getName(); }
    function getDescription(){ return mPlace.getDescription(); }
    function getType(){ return mPlace.getType(); }
    function getRarity(){ return mPlace.getRarity(); }
    function getMinLandmass(){ return mPlace.getMinLandmass(); }
    function getNecessaryFeatures(){ return mPlace.getNecessaryFeatures(); }
}

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

::Places <- array(PlaceId.MAX, null);

//-------------------------------
::Places[PlaceId.NONE] = PlaceDef("None", "None", PlaceType.NONE, 0.0, 0);
::Places[PlaceId.HAUNTED_WELL] = PlaceDef("Haunted Well", "The old haunted well.", PlaceType.LOCATION, 0.1, 10);
::Places[PlaceId.DARK_CAVE] = PlaceDef("Dark Cave", "A dark opening to a secluded cave.", PlaceType.LOCATION, 0.1, 10);
::Places[PlaceId.GOBLIN_VILLAGE] = PlaceDef("Goblin Village", "The grotty and ramsacked goblin village.", PlaceType.VILLAGE, 0.1, 10);
::Places[PlaceId.WIND_SWEPT_BEACH] = PlaceDef("Wind Swept Beach", "Grey, damp, and sandy.", PlaceType.LOCATION, 0.1, 10, PlaceNecessaryFeatures.OCEAN);
::Places[PlaceId.ROTHERFORD] = PlaceDef("Rotherford", "The old town of rotherford", PlaceType.TOWN, 0.1, 10, PlaceNecessaryFeatures.RIVER | PlaceNecessaryFeatures.OCEAN);
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

/*
Mortford
Garriton - the capitol

*/