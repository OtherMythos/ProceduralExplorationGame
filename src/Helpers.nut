::Vec3_ZERO <- Vec3(0, 0, 0);
::Vec3_UNIT_X <- Vec3(1, 0, 0);
::Vec3_UNIT_Y <- Vec3(0, 1, 0);
::Vec3_UNIT_Z <- Vec3(0, 0, 1);
::Vec3_NEGATIVE_UNIT_X <- Vec3(-1, 0, 0);
::Vec3_NEGATIVE_UNIT_Y <- Vec3(0, -1, 0);
::Vec3_NEGATIVE_UNIT_Z <- Vec3(0, 0, -1);
::Vec3_UNIT_SCALE <- Vec3(1, 1, 1);
::Vec2_ZERO <- Vec2(0, 0);
::Quat_IDENTITY <- Quat();
::Colour_WHITE <- ColourValue(1, 1, 1, 1);

::wrapToString <- function(obj, name, desc=null){
    return (desc == null ?
        format("(%s '%s')", typeof obj, name) :
        format("(%s '%s: %s')", typeof obj, name, desc)
    );
}


::determineGitHash <- function(){
    if(getconsttable().rawin("GIT_HASH")){
        return getconsttable().rawget("GIT_HASH");
    }

    //Otherwise try and read it from the git directory.
    local directory = _settings.getDataDirectory();
    local path = directory + "/.git/refs/heads/master";
    if(_system.exists(path)){
        local f = File();
        f.open(path);
        local hash = f.getLine();
        return hash.slice(0, 8);
    }

    return null;
}
::getVersionInfo <- function(){
    local hash = determineGitHash();
    local suffix = GAME_VERSION_SUFFIX;
    if(hash != null){
        suffix += ("-" + hash);
    }

    local engine = _settings.getEngineVersion();
    local versionTotal = format("%i.%i.%i-%s-%s", GAME_VERSION_MAJOR, GAME_VERSION_MINOR, GAME_VERSION_PATCH, engine.build, suffix);
    local engineVersionTotal = format("Engine: %i.%i.%i-%s-%s-%s", engine.major, engine.minor, engine.patch, engine.build, engine.suffix, engine.hash);

    return {
        "info": versionTotal,
        "engineInfo": engineVersionTotal
    };
}

::accelerationClampCoordinate_ <- function(coord, target=0.0, change=0.1){
    if(coord == target) return coord;

    if(coord > target){
        coord -= change;
        if(coord < target) coord = target;
    }else{
        coord += change;
        if(coord > target) coord = target;
    }

    return coord;
}

//Calculate an approximate max width for the label.
::calculateFontWidth_ <- function(label, targetWidth)
{
    local minSize = 1.0;
    //Upper bound
    local maxSize = label.getDefaultFontSize() * 16.0;
    local bestSize = label.getDefaultFontSize();

    //Binary search
    while((maxSize - minSize) > 0.5){
        local midSize = (minSize + maxSize) * 0.5;

        label.setDefaultFontSize(midSize);
        label.setText(label.getText());
        local labelSize = label.getSize();

        if(labelSize.x < targetWidth){
            bestSize = midSize;
            minSize = midSize;
        }else{
            maxSize = midSize;
        }
    }

    //Apply final best size
    label.setDefaultFontSize(bestSize);
    label.setText(label.getText());
}


::toggleDrawWireframe <- function(){
    ::drawWireframe = !::drawWireframe;
    ::setDrawWireframe(::drawWireframe);
}
::setDrawWireframe <- function(wireframe){
    ::drawWireframe = wireframe;
    foreach(i in ["baseVoxelMaterial", "MaskedWorld", "waterBlock", "outsideWaterBlock"]){
        local datablock = _hlms.getDatablock(i);
        if(datablock == null) continue;
        datablock.setMacroblock(_hlms.getMacroblock({
            "polygonMode": wireframe ? _PM_WIREFRAME : _PM_SOLID
        }));
    }
}

::printTextBox <- function(strings){
    local max = 0;
    foreach(i in strings){
        local len = i.len();
        if(len > max){
            max = len;
        }
    }

    local decorator = "";
    local padding = "** ";
    local paddingRight = " **";
    local maxExtent = max + (padding.len() * 2);
    for(local i = 0; i < maxExtent; i++){
        decorator += "*";
    }

    print(decorator);
    foreach(i in strings){
        local starting = padding + i;
        local remainder = maxExtent - starting.len() - padding.len();
        local spaces = "";
        for(local i = 0; i < remainder; i++){
            spaces += " ";
        }
        print(starting + spaces + paddingRight);
    }
    print(decorator);
}

::printVersionInfos <- function(){
    local infos = getVersionInfo();
    local strings = [];
    strings.append(GAME_TITLE.toupper());
    strings.append(infos.info);
    strings.append(infos.engineInfo);

    ::printTextBox(strings);

}

::clampValue <- function(val, min, max){
    if(val < min) return min;
    if(val > max) return max;
    return val;
}

::calculateSimpleAnimationInRange <- function(start, end, anim, animStart, animEnd){
    local animCount = ::clampValue(anim, animStart, animEnd) - animStart;
    animCount = animCount / (animEnd - animStart).tofloat();
    return ::calculateSimpleAnimation(start, end, animCount);
}

::calculateSimpleAnimation <- function(start, end, anim){
    if(anim >= 1.0) return end;
    if(anim <= 0.0) return start;

    return start + ((end - start) * anim);
}

::randDistanceFromPoint <- function(pos, radius, minRadius=0.0){
    local diff = _random.randVec3();
    diff -= 0.5;
    diff.y = 0;
    return pos + (diff * (minRadius + radius));
}

::evenOutButtonsForHeight <- function(buttons){
    local maxHeight = 0;
    foreach(i in buttons){
        local size = i.getSize().y;
        if(size > maxHeight) maxHeight = size;
    }
    foreach(i in buttons){
        i.setSize(i.getSize().x, maxHeight);
    }

    return maxHeight;
}

::mix <- function(a, b, amount) {
    return a * (1.0 - amount) + b * amount;
}

::Easing <- {

    function easeInSine(x) {
        return 1 - cos((x * PI) / 2);
    }

    function easeOutSine(x) {
        return sin((x * PI) / 2);
    }

    function easeInOutSine(x) {
        return -(cos(PI * x) - 1) / 2;
    }

    function easeInQuad(x) {
        return x * x;
    }

    function easeOutQuad(x) {
        return 1 - (1 - x) * (1 - x);
    }

    function easeInOutQuad(x) {
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;
    }

    function easeInCubic(x) {
        return x * x * x;
    }

    function easeOutCubic(x) {
        return 1 - pow(1 - x, 3);
    }

    function easeInOutCubic(x) {
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
    }

    function easeInQuart(x) {
        return x * x * x * x;
    }

    function easeOutQuart(x) {
        return 1 - pow(1 - x, 4);
    }

    function easeInOutQuart(x) {
        return x < 0.5 ? 8 * x * x * x * x : 1 - pow(-2 * x + 2, 4) / 2;
    }

    function easeInQuint(x) {
        return x * x * x * x * x;
    }

    function easeOutQuint(x) {
        return 1 - pow(1 - x, 5);
    }

    function easeInOutQuint(x) {
        return x < 0.5 ? 16 * x * x * x * x * x : 1 - pow(-2 * x + 2, 5) / 2;
    }

    function easeInExpo(x) {
        return x == 0 ? 0 : pow(2, 10 * x - 10);
    }

    function easeOutExpo(x) {
        return x == 1 ? 1 : 1 - pow(2, -10 * x);
    }

    function easeInOutExpo(x) {
        return x == 0
            ? 0
            : x == 1
            ? 1
            : x < 0.5 ? pow(2, 20 * x - 10) / 2
            : (2 - pow(2, -20 * x + 10)) / 2;
    }

    function easeInCirc(x) {
        return 1 - sqrt(1 - pow(x, 2));
    }

    function easeOutCirc(x) {
        return sqrt(1 - pow(x - 1, 2));
    }

    function easeInOutCirc(x) {
        return x < 0.5
            ? (1 - sqrt(1 - pow(2 * x, 2))) / 2
            : (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2;
    }

    function easeInBack(x) {
        local c1 = 1.70158;
        local c3 = c1 + 1;

        return c3 * x * x * x - c1 * x * x;
    }

    function easeOutBack(x) {
        local c1 = 1.70158;
        local c3 = c1 + 1;

        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2);
    }

    function easeInOutBack(x) {
        local c1 = 1.70158;
        local c2 = c1 * 1.525;

        return x < 0.5
            ? (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
            : (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
    }

    function easeInElastic(x) {
        local c4 = (2 * PI) / 3;

        return x == 0
            ? 0
            : x == 1
            ? 1
            : -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4);
    }

    function easeOutElastic(x) {
        local c4 = (2 * PI) / 3;

        return x == 0
            ? 0
            : x == 1
            ? 1
            : pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
    }

    function easeInOutElastic(x) {
        local c5 = (2 * PI) / 4.5;

        return x == 0
            ? 0
            : x == 1
            ? 1
            : x < 0.5
            ? -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
            : (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1;
    }

    function easeInBounce(x) {
        return 1 - easeOutBounce(1 - x);
    }

    function easeOutBounce(x) {
        local n1 = 7.5625;
        local d1 = 2.75;

        if (x < 1 / d1) {
            return n1 * x * x;
        } else if (x < 2 / d1) {
            return n1 * (x -= 1.5 / d1) * x + 0.75;
        } else if (x < 2.5 / d1) {
            return n1 * (x -= 2.25 / d1) * x + 0.9375;
        } else {
            return n1 * (x -= 2.625 / d1) * x + 0.984375;
        }
    }

    function easeInOutBounce(x) {
        return x < 0.5
            ? (1 - easeOutBounce(1 - 2 * x)) / 2
            : (1 + easeOutBounce(2 * x - 1)) / 2;
    }

};