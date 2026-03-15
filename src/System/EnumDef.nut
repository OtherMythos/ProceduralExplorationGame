/*
A class to wrap helper logic to define enums.

Multiple classes might want to contribute to the same enum, for instance to allow extendable content through extra scripts.
This class merges enum definition into a string and then compiles that as a Squirrel script.
*/
::EnumDef <- {

    mEnums_ = {}
    mEnumLookups_ = {}

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

    /**
     * Opt in an enum to have string lookup tables generated at commitEnums() time.
     * Generates two globals:
     *   ::XNames  - array of string names indexed by enum integer value
     *   ::XLookup - table mapping string name -> integer value
     */
    function enableLookup(name){
        mEnumLookups_.rawset(name, true);
    }

    function commitEnums(){
        foreach(c,i in mEnums_){
            i += "\nMAX\n};";
            //print(i);
            local buffer = _compileBuffer(i);
            buffer();
        }
        foreach(c,i in mEnumLookups_){
            buildLookupTables_(c);
        }
    }

    function buildLookupTables_(name){
        local raw = mEnums_.rawget(name);
        //Strip the leading 'enum X {\nNONE,' or 'enum X {\n' header.
        local headerEnd = raw.find("{");
        local body = raw.slice(headerEnd + 1);
        //Split into tokens on commas and newlines.
        local parts = split(body, ",\n");
        local names = [];
        local lookup = {};
        foreach(part in parts){
            local token = strip(part);
            if(token.len() == 0 || token == "MAX") continue;
            names.append(token);
            lookup.rawset(token, names.len() - 1);
        }
        getroottable().rawset(name + "Names", names);
        getroottable().rawset(name + "Lookup", lookup);
    }

};