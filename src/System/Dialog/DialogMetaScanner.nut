::DialogManager.DialogMetaScanner <- class{

    #Static
    mRichTextTypes_ = {}

    RichTextType = class{
        mColour_ = null;
        constructor(colour=null){
            mColour_ = colour;
        }

        function getColour(){
            return mColour_ == null ? "1 1 1 1" : mColour_;
        }
    }

    /**
    Get the rich text entries from a value.
    @param1:String: The dialog string to parse.
    @param2:Array: Output array.
    First entry is the output string. This will have been stripped of any rich text markers. Null if no rich text markers were found.
    Second is the rich text array.
    @returns True if a rich text value was found and false if not.
    */
    function getRichText(dialog, out){
        out[0] = null;
        out[1] = null;

        local currentStart = 0;
        local outContainer = array(3);

        //Some rich text was found in the string.
        local richTextEntries = [];
        local strippedText = "";

        local foundEntry = false;
        while(true){
            local result = getRichTextEntry(dialog, currentStart, outContainer);
            if(result < 0){
                if(!foundEntry){
                    strippedText = null;
                    richTextEntries = null;
                }
                break;
            }

            foundEntry = true;

            local baseStart = strippedText.len();
            strippedText += dialog.slice(currentStart, outContainer[2]);
            local baseEnd = strippedText.len();
            richTextEntries.push( {"offset": baseStart, "len": baseEnd - baseStart, "col": "1 1 1 1"} );

            //Add the contents to the string.
            local strippedStart = strippedText.len();
            strippedText += outContainer[0];
            local strippedEnd = strippedText.len();

            local targetColour = "1 1 1 1";
            targetColour = getColourForRichText_(outContainer[1]);
            richTextEntries.push( {"offset": strippedStart, "len": strippedEnd - strippedStart, "col": targetColour} );

            //TODO allow for animations to be described by rich text entries.

            //So it's not inclusive.
            currentStart = result+1;
        }

        out[0] = strippedText;
        out[1] = richTextEntries;

        return foundEntry;
    }

    function getColourForRichText_(id){
        if(!mRichTextTypes_.rawin(id)){
            //TODO constant here.
            return "1 1 1 1";
        }
        return mRichTextTypes_[id].getColour();
    }

    /**
    Get a rich text entry.
    This is a piece of text wrapped around tags, i.e [20]hello[20]
    The tagType is 20 and the tagContents is hello.
    @param1:string:The dialog string.
    @param2:integer:Index in the string to start searching from.
    @param3:array:An array to be populated with the output of type tagContents, tagType, and the idx of where the rich text starts.
    @returns The index where the tags end. -1 if an error occured.
    */
    function getRichTextEntry(dialog, start, out){
        //TODO make the container global so it's only created once.
        local container = array(3);
        local _start = -1;
        local _end = -1;

        local first = getTag(dialog, container, start);
        if(!first) return -1;
        local actualStart = container[0];
        _start = container[1];
        local tagType = container[2];

        local second = getTag(dialog, container, _start);
        if(!second) return -1;
        _end = container[1];
        //Tag types do not match.
        if(tagType != container[2]) return -1;

        out[0] = dialog.slice(_start+1, container[0]);
        out[1] = tagType;
        out[2] = actualStart;

        return _end;
    }

    /**
    Get the next tag from a position.
    @returns true is success, false otherwise.
    */
    function getTag(dialog, container, start){

        local currentIdx = start;
        local startIdx = dialog.find("[", currentIdx);
        if(startIdx == null){
            return false;
        }
        local endIdx = dialog.find("]", startIdx);
        if(endIdx == null){
            throw "Could not find terminator for ]";
        }
        currentIdx = endIdx;

        container[0] = startIdx;
        container[1] = endIdx;
        container[2] = dialog.slice(startIdx+1, endIdx);

        return true;
    }

};

function registerRichTextType(name, obj){
    local richTextTypes = ::DialogManager.DialogMetaScanner.mRichTextTypes_;
    if(richTextTypes.rawin(name)){
        throw format("Rich Text type with name '%s' already exists.", name);
    }

    richTextTypes.rawset(name, obj);
}

local RichTextType = ::DialogManager.DialogMetaScanner.RichTextType;
registerRichTextType("RED", RichTextType("1 0 0 1"));
registerRichTextType("GREEN", RichTextType("1 0 1 0"));
registerRichTextType("BLUE", RichTextType("1 1 0 0"));

registerRichTextType("IMPORTANT", RichTextType("1 1 0 0"));