::FoundObject <- class{
    type = FoundObjectType.NONE;
    obj = null;

    constructor(object=ItemId.NONE, objectType=FoundObjectType.NONE){
        type = objectType;
        obj = object == ItemId.NONE ? Item() : object;
    }

    function valid(){
        return type != FoundObjectType.NONE;
    }

    function isNone(){
        if(type == FoundObjectType.PLACE){
            return obj == Place.NONE;
        }
        return obj.isNone();
    }

    function toName(){
        if(type == FoundObjectType.ITEM){
            return obj.getName();
        }
        else if(type == FoundObjectType.PLACE){
            return ::Places[obj].getName();
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