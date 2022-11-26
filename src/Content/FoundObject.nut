::FoundObject <- class{
    type = FoundObjectType.NONE;
    obj = Item.NONE;

    constructor(object=Item.NONE, objectType=FoundObjectType.NONE){
        type = objectType;
        obj = object;
    }

    function valid(){
        return type != FoundObjectType.NONE;
    }

    function isNone(){
        return obj == Item.NONE;
    }

    function toName(){
        if(type == FoundObjectType.ITEM){
            return ::Items.itemToName(obj);
        }
        else if(type == FoundObjectType.PLACE){
            return ::Places.placeToName(obj);
        }
        else{
            assert(false);
        }
    }

    function getButtonSkinPack(){
        if(type == FoundObjectType.ITEM){
            return "ItemButton";
        }
        else if(type == FoundObjectType.PLACE){
            return "PlaceButton";
        }
        else{
            assert(false);
        }
    }
};