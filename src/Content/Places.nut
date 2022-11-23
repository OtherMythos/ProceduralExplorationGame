::Places <- {

    function placeToName(place){
        switch(place){
            case Place.NONE: return PlaceNames.NONE;
            case Place.HAUNTED_WELL: return PlaceNames.HAUNTED_WELL;
            case Place.DARK_CAVE: return PlaceNames.DARK_CAVE;
            case Place.GOBLIN_VILLAGE: return PlaceNames.GOBLIN_VILLAGE;
            case Place.WIND_SWEPT_BEACH: return PlaceNames.WIND_SWEPT_BEACH;
            default:
                assert(false);
        }
    }

    function placeToDescription(place){
        switch(place){
            case Place.NONE: return "None";
            case Place.HAUNTED_WELL: return "The old haunted well.";
            case Place.DARK_CAVE: return "A dark opening to a secluded cave.";
            case Place.GOBLIN_VILLAGE: return "The grotty and ramsacked goblin village.";
            case Place.WIND_SWEPT_BEACH: return "Grey, damp, and sandy."
            default:
                assert(false);
        }
    }
};