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

::PlaceDef <- class{
    mName = null;
    mDesc = null;

    constructor(name, desc){
        mName = name;
        mDesc = desc;
    }

    function getName(){ return mName; }
    function getDescription(){ return mDesc; }
}

::Places <- array(Place.MAX, null);

//-------------------------------
::Places[Place.HAUNTED_WELL] = PlaceDef("Haunted Well", "The old haunted well.");
::Places[Place.DARK_CAVE] = PlaceDef("Dark Cave", "A dark opening to a secluded cave.");
::Places[Place.GOBLIN_VILLAGE] = PlaceDef("Goblin Village", "The grotty and ramsacked goblin village.");
::Places[Place.WIND_SWEPT_BEACH] = PlaceDef("Wind Swept Beach", "Grey, damp, and sandy.");
::Places[Place.ROTHERFORD] = PlaceDef("Rotherford", "The old town of rotherford");
//-------------------------------