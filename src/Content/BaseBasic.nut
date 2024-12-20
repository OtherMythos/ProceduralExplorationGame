::BaseBasic <- class extends ::BaseImpl{

    function setup(){

    }

    function update(){

    }

    function loadEnumFiles(){
        _doFile("res://src/Content/ItemEnums.nut");
        _doFile("res://src/Content/EnemyEnums.nut");
        _doFile("res://src/Content/PlaceEnums.nut");
    }

    function loadDefFiles(){

    }

    function loadContentFiles(){
        _doFile("res://src/Content/ItemDefs.nut");
        _doFile("res://src/Content/EnemyDefs.nut");
        _doFile("res://src/Content/PlaceDefs.h.nut");
    }

    function setupFirst(){

    }

    function setupSecondary(){

    }

}