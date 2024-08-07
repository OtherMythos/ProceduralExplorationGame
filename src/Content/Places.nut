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
function DEFINE_PLACE(placeId, def){
    ::Places[placeId] = def;
}
::PlaceIdConst <- function(id, second){
    return id;
}
::PlaceTypeConst <- ::PlaceIdConst;
getroottable().setdelegate({
    "_get": function(idx){
        return null;
    }
});
_doFileWithContext("script://PlaceDefs.h.nut", this);
getroottable().setdelegate(null);
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