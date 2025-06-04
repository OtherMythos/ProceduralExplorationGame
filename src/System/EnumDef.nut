/*
A class to wrap helper logic to define enums.

Multiple classes might want to contribute to the same enum, for instance to allow extendable content through extra scripts.
This class merges enum definition into a string and then compiles that as a Squirrel script.
*/
::EnumDef <- {

    mEnums_ = {}

    function addToEnum(name, content, includeNone=true){
        if(!mEnums_.rawin(name)){
            local val = "enum %s {\nNONE,";
            if(!includeNone){
                val = "enum %s {\n";
            }
            local root = format(val, name);
            mEnums_.rawset(name, root);
        }
        //print(mEnums_[name])
        mEnums_[name] += content;
        //print(mEnums_[name])
    }

    /**
     * Define string to match enum, for instance
     * enum Screen { MAIN_MENU, SECOND_MENU }
     * ::ScreenStrings <- ["mainMenu", "secondMenu"]
     */
    function addToString(name, content, includeNone=true){
        if(!getroottable().rawin(name)){
            if(includeNone){
                content.insert(0, "none");
            }
            getroottable().rawset(name, content);
        }else{
            getroottable().rawget(name).extend(content);
        }
    }

    function commitEnums(){
        foreach(c,i in mEnums_){
            i += "\nMAX\n};";
            //print(i);
            local buffer = _compileBuffer(i);
            buffer();
        }
    }

};