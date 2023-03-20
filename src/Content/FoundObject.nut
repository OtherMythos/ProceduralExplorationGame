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
            return obj == PlaceId.NONE;
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
        else if(type == FoundObjectType.NONE){
            return "None";
        }
        else{
            assert(false);
        }
    }

    function getMesh(){
        if(type == FoundObjectType.ITEM){
            return obj.getMesh();
        }
        return null;
    }

    function _tostring(){
        return ::wrapToString(::FoundObject, "FoundObject", toName());
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