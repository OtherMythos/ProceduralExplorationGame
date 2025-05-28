::CharacterDumper <- {

    function dump(directory){
        if(!_system.exists(directory)){
            _system.mkdir(directory);
        }

        for(local i = 0; i < CharacterModelType.MAX; i++){
            dumpCharacterModel(directory, i);
        }
    }

    function switchVoxMesh(mesh){
        local filename = mesh;
        local foundIdx = filename.find(".voxMesh");
        if(foundIdx != null){
            filename = filename.slice(0, foundIdx) + ".obj";
        }

        return filename;
    }

    function vecArray(v, pos){
        if(v == null) return null;
        if(pos){
            return [v.x, -v.z, v.y];
        }else{
            return [v.x, v.y, v.z];
        }
    }

    function dumpCharacterModel(directory, modelType){
        local modelData = {};

        local modelName = ::ConstHelper.CharacterModelTypeToString(modelType);
        local modelFile = directory + "/" + modelName + ".json";

        local m = ::ModelTypes[modelType]
        if(m == null) return;
        modelData.name <- modelName;
        modelData.nodes <- [];
        foreach(n in m.mNodes){
            local filename = switchVoxMesh(n.mMesh);

            modelData.nodes.append({
                "name": filename,
                "pos": vecArray(n.mPos, true),
                "scale": vecArray(n.mScale, false),
                "animId": n.mPart
            });
        }

        _system.writeJsonAsFile(modelFile, modelData, true);

        printf("Exported character model '%s' to %s", modelName, modelFile);
    }
};

::AnimationDumper <- {

    function dump(directory){
        if(!_system.exists(directory)){
            _system.mkdir(directory);
        }

        for(local i = 0; i < CharacterModelAnimId.MAX; i++){
            dumpAnimation(directory, i);
        }
    }

    function dumpAnimation(directory, animType){
        local animData = {};

        local anim = ::CharacterModelAnims[animType];
        local animName = anim.mName;
        if(animName == null) return;

        local animFile = directory + "/" + animName + ".json";

        local animParts = [];
        foreach(i in anim.mUsedNodes){
            animParts.append(i);
        }

        animData.name <- animName;
        animData.animIds <- animParts;

        _system.writeJsonAsFile(animFile, animData, true);

        printf("Exported character animation '%s' to %s", animName, animFile);
    }

};