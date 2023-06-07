::generateFloorGrid <- function(){
    local gridArraySpacing = 1;
    local gridSize = 50;
    local numLines = gridSize / gridArraySpacing;

    //+2 so that the lines are closed off. The loops run for <=, meaning there's +1 of whatever numLines is. As there's 2 loops we add 2 here.
    local verticesCount = (numLines + numLines + 2) * 3 * 2;
    local c_originalVertices = array(verticesCount);

    local indexSize = (numLines + numLines + 2) * 2;
    local c_indexData = array(indexSize);

    local count = 0;
    local idxCount = 0;
    for(local y = 0; y <= numLines; y++){
        c_originalVertices[count++] = 0;
        c_originalVertices[count++] = 0;
        c_originalVertices[count++] = y * gridArraySpacing;

        c_originalVertices[count++] = gridSize;
        c_originalVertices[count++] = 0;
        c_originalVertices[count++] = y * gridArraySpacing;

        c_indexData[idxCount] = idxCount;
        idxCount++;
        c_indexData[idxCount] = idxCount;
        idxCount++;
    }
    for(local x = 0; x <= numLines; x++){
        c_originalVertices[count++] = x * gridArraySpacing;
        c_originalVertices[count++] = 0;
        c_originalVertices[count++] = 0;

        c_originalVertices[count++] = x * gridArraySpacing;
        c_originalVertices[count++] = 0;
        c_originalVertices[count++] = gridSize;

        c_indexData[idxCount] = idxCount;
        idxCount++;
        c_indexData[idxCount] = idxCount;
        idxCount++;
    }
    assert(idxCount == indexSize);
    assert(count == verticesCount);

    local b = blob(c_originalVertices.len() * 4);
    b.seek(0);
    foreach(i in c_originalVertices){
        b.writen(i, 'f');
    }
    local indiceStride = 2;
    local bb = blob(c_indexData.len() * indiceStride);
    bb.seek(0);
    local strideVal = 'w';
    foreach(i in c_indexData){
        bb.writen(i, strideVal);
    }


    local outMesh = _graphics.createManualMesh("floorGrid");
    local subMesh = outMesh.createSubMesh();

    local elemVec = _graphics.createVertexElemVec();
    elemVec.pushVertexElement(_VET_FLOAT3, _VES_POSITION);
    local buffer = _graphics.createVertexBuffer(elemVec, verticesCount, verticesCount, b);
    local indexBuffer = _graphics.createIndexBuffer(indiceStride == 2 ? _IT_16BIT : _IT_32BIT, bb, c_indexData.len());

    local vao = _graphics.createVertexArrayObject(buffer, indexBuffer, _OT_LINE_LIST);

    subMesh.pushMeshVAO(vao, _VP_NORMAL);

    local halfBounds = Vec3(gridSize/2, 1, gridSize/2);
    local bounds = AABB(halfBounds, halfBounds);
    outMesh.setBounds(bounds);
    outMesh.setBoundingSphereRadius(bounds.getRadius());


    //Add it to the scene.
    local targetNode = _scene.getRootSceneNode().createChildSceneNode();
    targetNode.setPosition(-25, 0, -25);
    local item = _scene.createItem(outMesh);
    targetNode.attachObject(item);
}