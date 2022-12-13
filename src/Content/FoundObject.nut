::FoundObject <- class{
    type = FoundObjectType.NONE;
    obj = ItemId.NONE;

    constructor(object=ItemId.NONE, objectType=FoundObjectType.NONE){
        type = objectType;
        obj = object;
    }

    function valid(){
        return type != FoundObjectType.NONE;
    }

    function isNone(){
        return obj == ItemId.NONE;
    }

    function toName(){
        if(type == FoundObjectType.ITEM){
            return ::Items[obj].getName();
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