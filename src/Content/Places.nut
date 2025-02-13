/*
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
*/

::PlaceDef <- class{
    mName = null;
    mDesc = null;
    mType = null;
    mRarity = null;
    mMinLandmass = 10;
    mNecessaryFeatures = 0;
    mPlacementFunction = null;
    mRegionAppearFunction = null;
    mPlaceFileName = null;

    //Editor meta
    mHalf = null;
    mCentre = null;
    mRadius = 10;
    //

    constructor(name, desc, placeType, rarity, placementFunction, regionAppearFunction, placeFileName, minLandmass = 10, necessaryFeatures = 0){
        mName = name;
        mDesc = desc;
        mType = placeType;
        mRarity = rarity;
        mMinLandmass = minLandmass;
        mNecessaryFeatures = necessaryFeatures;
        mPlacementFunction = placementFunction;
        mRegionAppearFunction = regionAppearFunction;
        mPlaceFileName = placeFileName;
    }

    function getName(){ return mName; }
    function getDescription(){ return mDesc; }
    function getType(){ return mType; }
    function getRarity(){ return mRarity; }
    function getMinLandmass(){ return mMinLandmass; }
    function getNecessaryFeatures(){ return mNecessaryFeatures; }
    function getPlacementFunction(){ return mPlacementFunction; }
    function getRegionAppearFunction(){ return mRegionAppearFunction; }
    function getPlaceFileName(){ return mPlaceFileName; }

    function _tostring(){
        return ::wrapToString(::PlaceDef, "Place", getName());
    }
}

/*
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
*/
