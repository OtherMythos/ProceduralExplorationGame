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
    if(val < min) return val;
    if(val > max) return val;
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