/**
A class to abstract logic for Base.
Projects might include multiple sections, for instance if modes or additions such as DLC are included.
Allowing multiple Bases makes it easy to support this logic.
*/
::BaseImpl <- class{

    //Called each frame
    function update(){

    }

    //Specifically load script files which register enums with the EnumDef.nut class.
    function loadEnumFiles(){

    }

    //Once all enums are defined load any content specific to them here.
    function loadContentFiles(){

    }

    //Function called before base setup has been called.
    function setupFirst(){

    }

    //Function called after base setup has been called.
    function setupSecondary(){

    }

    //Function called at the end of Base's loadFiles() function.
    function loadFilesEnd(){

    }

}