//A class to manage writing the data points file, which is derived by recursively iterating the scene tree and lifting data point positions.
::SceneEditorDataPointWriter <- class{

    constructor(){

    }

    function performSave(filePath, tree){
        if(_system.exists(filePath)){
            _system.remove(filePath);
        }
        _system.createBlankFile(filePath);
        writeToFile(filePath, tree);
    }

    function writeToFile(path, tree){
        printf("Writing data point file to path '%s'", path);

        local outFile = File();
        outFile.open(path);

        local totalUserData = 0;

        local parents = [];
        local indent = 0;
        local current = null;
        foreach(i in tree.mEntries_){
            local nodeType = i.nodeType;
            if(nodeType == SceneEditorFramework_SceneTreeEntryType.CHILD){
                indent++;
                if(current != null){
                    parents.append(current);
                }
                continue;
            }
            else if(nodeType == SceneEditorFramework_SceneTreeEntryType.TERM){
                indent--;
                assert(indent >= 0);
                if(parents.len() < 0){
                    parents.pop();
                }
                continue;
            }
            current = i;

            if(i.nodeType == SceneEditorFramework_SceneTreeEntryType.USER1){
                //Determine all the parents position.
                local resolvedPosition = Vec3();
                foreach(d in parents){
                    resolvedPosition += d.position;
                }
                resolvedPosition += i.position;

                outFile.write(format("%f,%f,%f,%s", resolvedPosition.x, resolvedPosition.y, resolvedPosition.z, i.data.value));
                outFile.write("\n");

                totalUserData++;
            }
        }

        if(totalUserData == 0){
            _system.remove(path);
        }
    }

};