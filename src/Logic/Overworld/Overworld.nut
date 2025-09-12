::Overworld <- class extends ::ProceduralExplorationWorld{

    #Override
    function getWorldType(){
        return WorldTypes.OVERWORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Overworld";
    }

    #Override
    function notifyPlayerMoved(){

    }

    function createScene(){

    }

    #Override
    function constructPlayerEntry_(){

    }

};