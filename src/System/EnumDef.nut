/*
A class to wrap helper logic to define enums.

Multiple classes might want to contribute to the same enum, for instance to allow extendable content through extra scripts.
This class merges enum definition into a string and then compiles that as a Squirrel script.
*/
::EnumDef <- {

    mEnums_ = {}

    function addToEnum(name, content){
        if(!mEnums_.rawin(name)){
            local root = format("enum %s {\nNONE,", name);
            mEnums_.rawset(name, root);
        }
        print(mEnums_[name])
        mEnums_[name] += content;
        print(mEnums_[name])
    }

    function commitEnums(){
        foreach(c,i in mEnums_){
            i += "\nMAX\n};";
            print(i);
            local buffer = _compileBuffer(i);
            buffer();
        }
    }

};