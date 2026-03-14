//Helper functions for packing and unpacking the 64-bit world seed.
//Layout: bits[63:32] = base (32-bit), bits[31:16] = moisture (16-bit), bits[15:0] = variation (16-bit).
::SeedHelper <- {

    function pack(seedBase, moisture, variation){
        return (seedBase << 32) | (moisture << 16) | variation;
    }

    function getBase(seed){
        return (seed >> 32) & 0xFFFFFFFF;
    }

    function getMoisture(seed){
        return (seed >> 16) & 0xFFFF;
    }

    function getVariation(seed){
        return seed & 0xFFFF;
    }

    //Returns the seed formatted as a 16-digit hex string e.g. "0x00001234ABCD0099".
    function toHex(seed){
        local hi = (seed >> 32) & 0xFFFFFFFF;
        local lo = seed & 0xFFFFFFFF;
        return format("0x%08X%08X", hi, lo);
    }

    //Parses a hex string (with or without "0x" prefix) into a 64-bit seed value.
    function parseHex(hexStr){
        local str = hexStr;
        //Remove 0x prefix if present
        if(str.len() > 2 && str.slice(0, 2) == "0x"){
            str = str.slice(2);
        }
        //Squirrel tointeger() should handle hex with 0x, but to be safe, parse manually
        local result = 0;
        foreach(ch in str){
            local digit = 0;
            if(ch >= '0' && ch <= '9'){
                digit = ch - '0';
            }else if(ch >= 'A' && ch <= 'F'){
                digit = ch - 'A' + 10;
            }else if(ch >= 'a' && ch <= 'f'){
                digit = ch - 'a' + 10;
            }else{
                throw format("Invalid hex character: %c", ch);
            }
            result = (result << 4) | digit;
        }
        return result;
    }

    //Generates a new random seed with full-range components.
    function generate(){
        local baseLow = _random.randInt(0x10000);
        local baseHigh = _random.randInt(0x10000);
        local baseSeed = (baseHigh << 16) | baseLow;
        local moisture = _random.randInt(0x10000);
        local variation = _random.randInt(0x10000);

        //NOTE: For now reduce the complexity as only in the range of 1000 was tested.
        baseSeed = _random.randInt(1000);
        moisture = _random.randInt(1000);
        variation = _random.randInt(1000);

        return pack(baseSeed, moisture, variation);
    }

};
