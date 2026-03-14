//Helper functions for packing and unpacking the 32-bit world seed.
//Layout: bits[31:16] = base (16-bit), bits[15:8] = moisture (8-bit), bits[7:0] = variation (8-bit).
::SeedHelper <- {

    function pack(seedBase, moisture, variation){
        return (seedBase << 16) | (moisture << 8) | variation;
    }

    function getBase(seed){
        return (seed >> 16) & 0xFFFF;
    }

    function getMoisture(seed){
        return (seed >> 8) & 0xFF;
    }

    function getVariation(seed){
        return seed & 0xFF;
    }

    //Returns the seed formatted as an 8-digit hex string e.g. "0x01C0D0DE".
    function toHex(seed){
        return format("0x%08X", seed);
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
        local baseSeed = _random.randInt(0x10000);
        local moisture = _random.randInt(0x100);
        local variation = _random.randInt(0x100);

        //NOTE: For now reduce the complexity as only in the range of 1000 was tested.
        baseSeed = _random.randInt(1000);

        return pack(baseSeed, moisture, variation);
    }

};
