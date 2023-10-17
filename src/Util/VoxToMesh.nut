/**
 * A helper class to generate a triangulated mesh from voxel data.
 */
::VoxToMesh <- class{

    MASKS = null;
    FACES_VERTICES = null;
    FACES_NORMALS = null;
    VERTICES_POSITIONS = null;

    static COLS_WIDTH = 16;
    static COLS_HEIGHT = 16;
    TILE_WIDTH = null;
    TILE_HEIGHT = null;

    mTimer_ = null;

    MASKS = [
        0, -1, 0,
        0, 1, 0,
        0, 0, -1,
        0, 0, 1,
        1, 0, 0,
        -1, 0, 0,
    ];
    FACES_VERTICES = [
        0, 1, 2, 3,
        5, 4, 7, 6,
        0, 4, 5, 1,
        2, 6, 7, 3,
        1, 5, 6, 2,
        0, 3, 7, 4
    ];
    VERTICES_POSITIONS = [
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, 1.0, 1.0,
        0.0, 1.0, 1.0
    ];
    FACES_NORMALS = [
        0, -1,  0,
        0,  1,  0,
        0,  0, -1,
        0,  0,  1,
        1,  0,  0,
        -1,  0,  0,
    ];

    mVertexElemVec_ = null;
    mFaceExclusionMask_ = 0;
    mYMult_ = 1;

    mNumTris_ = 0;

    /**
     * @param exclusionMask Allows for certain faces to always be rejected, for instance not drawing the bottom face in a terrain.
     */
    constructor(timer = null, exclusionMask = 0, yMult=1){
        mFaceExclusionMask_ = exclusionMask;
        mTimer_ = timer;
        mYMult_ = yMult;

        TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0;
        TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0;

        mVertexElemVec_ = _graphics.createVertexElemVec();
        mVertexElemVec_.pushVertexElement(_VET_FLOAT3, _VES_POSITION);
        mVertexElemVec_.pushVertexElement(_VET_FLOAT1, _VES_NORMAL);
        mVertexElemVec_.pushVertexElement(_VET_FLOAT2, _VES_TEXTURE_COORDINATES);
    }

    function createTerrainFromVoxelBlob(meshBase, mapData){
        if(mTimer_) mTimer_.start();

        local width = mapData.width;
        local height = mapData.height;
        local seaLevel = mapData.seaLevel;
        local buf = mapData.voxelBuffer;
        local bufSecond = mapData.secondaryVoxBuffer;

        local outMesh = _graphics.createManualMesh(meshBase);
        local subMesh = outMesh.createSubMesh();

        local WORLD_DEPTH = 20;
        local ABOVE_GROUND = 0xFF - mapData.seaLevel;
        //local MAP_VOXEL_MASK = 0x1F;

        local verts = [];
        local indices = [];

        local numVerts = 0;
        local index = 0;
        local NUM_VERTS = 6;

        buf.seek(0);
        bufSecond.seek(0);
        local voxVals = [
            2, 112, 0, 147, 6
        ];
        local waterVal = 192;
        local written = false;
        local maxAltitude = 1;
        for(local y = height; y != 0; y--){
            for(local x = 0; x < width; x++){
                local vox = buf.readn('i');
                local region = (bufSecond.readn('i') >> 8) & 0xFF;
                local voxFloat = (vox & 0xFF).tofloat();
                if(voxFloat <= seaLevel) continue;
                //if(region != regionIdx) continue;
                local altitude = (((voxFloat - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                local voxelMeta = (vox >> 8) & MAP_VOXEL_MASK;
                local v = voxVals[voxelMeta];
                local isRiver = (vox >> 8) & MapVoxelTypes.RIVER;
                if(isRiver){
                    //altitude-=8;
                    //if(altitude < 1) altitude = 1;
                    v = 192;
                }

                local texCoordX = ((v % COLS_WIDTH).tofloat() / COLS_WIDTH) + TILE_WIDTH;
                local texCoordY = ((v.tofloat() / COLS_WIDTH) / COLS_HEIGHT) + TILE_HEIGHT;

                if(altitude > maxAltitude) maxAltitude = altitude;

                {
                    local f = 0;
                    for(local i = 0; i < 4; i++){
                        local xx = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                        local zz = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + y).tointeger();
                        local yy = altitude;

                        local val = xx | yy << 10 | zz << 20 | 3 << 30;
                        verts.append(val);

                        //TODO Magic number for now to avoid it breaking the regular materials.
                        val = f << 29 | 0x15FBF7DB;
                        verts.append(val);
                        verts.append(0);
                        //TODO just to pad it out, long term I shouldn't need this.
                        verts.append(0);

                        verts.append(texCoordX);
                        verts.append(texCoordY);
                        numVerts++;
                    }
                    indices.append(index + 2);
                    indices.append(index + 1);
                    indices.append(index + 0);
                    indices.append(index + 0);
                    indices.append(index + 3);
                    indices.append(index + 2);
                    index += 4;
                    mNumTris_ += 2;
                }

                {
                    //Check one just to start
                    local start = buf.tell();
                    local targetX = x;
                    local targetY = y-1;
                    //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
                        buf.seek((targetX + (height-targetY) * width) * 4);
                        local voxSecond = buf.readn('i');
                        local voxFloatSecond = (voxSecond & 0xFF).tofloat();
                        buf.seek(start);
                        if(voxFloatSecond > seaLevel){
                            local testAltitude = (((voxFloatSecond - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                            if(testAltitude < altitude){
                                //The altidue is lower so need to draw some triangles.
                                local altitudeDelta = altitude - testAltitude;
                                for(local zAlt = 0; zAlt < altitudeDelta; zAlt++){
                                    //Loop down and draw the triangles.

                                    local f = 2;
                                    for(local i = 0; i < 4; i++){
                                        local xx = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                                        local zz = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + y).tointeger();
                                        local yy = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + (altitude-zAlt) -1).tointeger();
                                        //print("yy " + yy);

                                        local val = xx | yy << 10 | zz << 20 | 3 << 30;
                                        verts.append(val);

                                        //TODO Magic number for now to avoid it breaking the regular materials.
                                        val = f << 29 | 0x15FBF7DB;
                                        verts.append(val);
                                        verts.append(0);
                                        //TODO just to pad it out, long term I shouldn't need this.
                                        verts.append(0);

                                        verts.append(texCoordX);
                                        verts.append(texCoordY);
                                        numVerts++;
                                    }
                                    indices.append(index + 0);
                                    indices.append(index + 1);
                                    indices.append(index + 2);
                                    indices.append(index + 2);
                                    indices.append(index + 3);
                                    indices.append(index + 0);
                                    index += 4;
                                    mNumTris_ += 2;
                                }
                            }
                        }
                    //}else{
                    //    assert(false);
                    //}
                }
                {
                    //Check one just to start
                    local start = buf.tell();
                    local targetX = x;
                    local targetY = y+1;
                    //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
                        buf.seek((targetX + (height-targetY) * width) * 4);
                        local voxSecond = buf.readn('i');
                        local voxFloatSecond = (voxSecond & 0xFF).tofloat();
                        buf.seek(start);
                        if(voxFloatSecond > seaLevel){
                            local testAltitude = (((voxFloatSecond - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                            if(testAltitude < altitude){
                                //The altidue is lower so need to draw some triangles.
                                local altitudeDelta = altitude - testAltitude;
                                if(altitudeDelta > 1) assert(false);
                                for(local zAlt = 0; zAlt < altitudeDelta; zAlt++){
                                    //Loop down and draw the triangles.
                                    local f = 3;
                                    for(local i = 0; i < 4; i++){
                                        local xx = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                                        local zz = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + y).tointeger();
                                        local yy = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + (altitude-zAlt) -1).tointeger();
                                        //print("yy " + yy);

                                        local val = xx | yy << 10 | zz << 20 | 3 << 30;
                                        verts.append(val);

                                        //TODO Magic number for now to avoid it breaking the regular materials.
                                        val = f << 29 | 0x15FBF7DB;
                                        verts.append(val);
                                        verts.append(0);
                                        //TODO just to pad it out, long term I shouldn't need this.
                                        verts.append(0);

                                        verts.append(texCoordX);
                                        verts.append(texCoordY);
                                        numVerts++;
                                    }
                                    indices.append(index + 0);
                                    indices.append(index + 1);
                                    indices.append(index + 2);
                                    indices.append(index + 2);
                                    indices.append(index + 3);
                                    indices.append(index + 0);
                                    index += 4;
                                    mNumTris_ += 2;
                                }
                            }
                        }
                    //}else{
                    //    assert(false);
                    //}
                }
                {
                    //Check one just to start
                    local start = buf.tell();
                    local targetX = x+1;
                    local targetY = y;
                    //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
                        buf.seek((targetX + (height-targetY) * width) * 4);
                        local voxSecond = buf.readn('i');
                        local voxFloatSecond = (voxSecond & 0xFF).tofloat();
                        buf.seek(start);
                        if(voxFloatSecond > seaLevel){
                            local testAltitude = (((voxFloatSecond - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                            if(testAltitude < altitude){
                                //The altidue is lower so need to draw some triangles.
                                local altitudeDelta = altitude - testAltitude;
                                for(local zAlt = 0; zAlt < altitudeDelta; zAlt++){
                                    //Loop down and draw the triangles.
                                    local f = 4;
                                    for(local i = 0; i < 4; i++){
                                        local xx = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                                        local zz = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + y).tointeger();
                                        local yy = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + (altitude-zAlt) -1).tointeger();
                                        //print("yy " + yy);

                                        local val = xx | yy << 10 | zz << 20 | 3 << 30;
                                        verts.append(val);

                                        //TODO Magic number for now to avoid it breaking the regular materials.
                                        val = f << 29 | 0x15FBF7DB;
                                        verts.append(val);
                                        verts.append(0);
                                        //TODO just to pad it out, long term I shouldn't need this.
                                        verts.append(0);

                                        verts.append(texCoordX);
                                        verts.append(texCoordY);
                                        numVerts++;
                                    }
                                    indices.append(index + 0);
                                    indices.append(index + 1);
                                    indices.append(index + 2);
                                    indices.append(index + 2);
                                    indices.append(index + 3);
                                    indices.append(index + 0);
                                    index += 4;
                                    mNumTris_ += 2;
                                }
                            }
                        }
                    //}else{
                    //    assert(false);
                    //}
                }
                {
                    //Check one just to start
                    local start = buf.tell();
                    local targetX = x-1;
                    local targetY = y;
                    //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
                        buf.seek((targetX + (height-targetY) * width) * 4);
                        local voxSecond = buf.readn('i');
                        local voxFloatSecond = (voxSecond & 0xFF).tofloat();
                        buf.seek(start);
                        if(voxFloatSecond > seaLevel){
                            local testAltitude = (((voxFloatSecond - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                            if(testAltitude < altitude){
                                //The altidue is lower so need to draw some triangles.
                                local altitudeDelta = altitude - testAltitude;
                                for(local zAlt = 0; zAlt < altitudeDelta; zAlt++){
                                    //Loop down and draw the triangles.
                                    local f = 5;
                                    for(local i = 0; i < 4; i++){
                                        local xx = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                                        local zz = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + y).tointeger();
                                        local yy = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + (altitude-zAlt) -1).tointeger();
                                        //print("yy " + yy);

                                        local val = xx | yy << 10 | zz << 20 | 3 << 30;
                                        verts.append(val);

                                        //TODO Magic number for now to avoid it breaking the regular materials.
                                        val = f << 29 | 0x15FBF7DB;
                                        verts.append(val);
                                        verts.append(0);
                                        //TODO just to pad it out, long term I shouldn't need this.
                                        verts.append(0);

                                        verts.append(texCoordX);
                                        verts.append(texCoordY);
                                        numVerts++;
                                    }
                                    indices.append(index + 0);
                                    indices.append(index + 1);
                                    indices.append(index + 2);
                                    indices.append(index + 2);
                                    indices.append(index + 3);
                                    indices.append(index + 0);
                                    index += 4;
                                    mNumTris_ += 2;
                                }
                            }
                        }
                    //}else{
                    //    assert(false);
                    //}
                }
            }
        }

        assert(numVerts == verts.len() / NUM_VERTS);

        local b = blob(verts.len() * 4);
        b.seek(0);
        local intFloatCount = 0;
        foreach(c,i in verts){
            local valid = c % NUM_VERTS == 0;
            if(valid){
                intFloatCount = 3;
            }
            b.writen(i, intFloatCount > 0 ? 'i' : 'f');
            intFloatCount--;
        }
        local indiceStride = index + 4 >= 0xFFFF ? 4 : 2;
        local bb = blob(indices.len() * indiceStride);
        bb.seek(0);
        local strideVal = indiceStride == 2 ? 'w' : 'i';
        foreach(i in indices){
            bb.writen(i, strideVal);
        }

        local buffer = _graphics.createVertexBuffer(mVertexElemVec_, numVerts, numVerts, b);
        local indexBuffer = _graphics.createIndexBuffer(indiceStride == 2 ? _IT_16BIT : _IT_32BIT, bb, indices.len());

        local vao = _graphics.createVertexArrayObject(buffer, indexBuffer, _OT_TRIANGLE_LIST);

        subMesh.pushMeshVAO(vao, _VP_NORMAL);
        subMesh.pushMeshVAO(vao, _VP_SHADOW);

        //TODO remove this later at some point.
        local halfBounds = Vec3(width/2, maxAltitude/2, height/2);
        local bounds = AABB(halfBounds, halfBounds);
        outMesh.setBounds(bounds);
        outMesh.setBoundingSphereRadius(bounds.getRadius());

        subMesh.setMaterialName("baseVoxelMaterial");

        if(mTimer_) mTimer_.stop();

        local outData = [];
        for(local i = 0; i < mapData.regionData.len(); i++){
            outData.append(outMesh);
        }

        return outData;
    }


    /**
     * Generate a mesh object from the provided voxel data.
     * @param voxData A three dimensional blob containing voxel definitions from top to bottom, left to right. A single voxel is a byte and the size must match up with the provided dimensions.
     */
    function createMeshForVoxelData(meshName, voxData, width, height, depth){
        if(mTimer_) mTimer_.start();
        assert(voxData.len() == width * height * depth);
        local outMesh = _graphics.createManualMesh(meshName);
        local subMesh = outMesh.createSubMesh();

        local verts = [];
        local indices = [];

        local NUM_VERTS = 6;

        local index = 0;
        local numVerts = 0;
        for(local z = 0; z < depth; z++)
        for(local y = 0; y < height; y++)
        for(local x = 0; x < width; x++){
            local v = readVoxelFromData_(voxData, x, y, z, width, height);
            if(v == null) continue;
            local texCoordX = ((v % COLS_WIDTH).tofloat() / COLS_WIDTH) + TILE_WIDTH;
            local texCoordY = ((v.tofloat() / COLS_WIDTH) / COLS_HEIGHT) + TILE_HEIGHT;
            local neighbourMask = getNeighbourMask(voxData, x, y, z, width, height, depth);
            for(local f = 0; f < 6; f++){
                if(!blockIsFaceVisible(neighbourMask, f)) continue;
                if((1 << f) & mFaceExclusionMask_) continue;
                //Face is valid by this point, so do the ambient occlusion checks.
                local ambientMask = getVerticeBorder(voxData, f, x, y, z, width, height, depth);
                for(local i = 0; i < 4; i++){
                    //Pack everything into a single integer.
                    local x = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x).tointeger();
                    local y = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + y).tointeger();
                    local z = (VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + z).tointeger();
                    assert(x <= 0x2FF && x >= -0x2FF);
                    assert(y <= 0x2FF && y >= -0x2FF);
                    assert(z <= 0x2FF && z >= -0x2FF);

                    local ambient = (ambientMask >> 8 * i) & 0xFF;
                    assert(ambient >= 0 && ambient <= 3);

                    local val = x | y << 10 | z << 20 | ambient << 30;
                    verts.append(val);

                    //TODO Magic number for now to avoid it breaking the regular materials.
                    val = f << 29 | 0x15FBF7DB;
                    //val = f;
                    verts.append(val);
                    //verts.append(f);
                    verts.append(0);
                    //TODO just to pad it out, long term I shouldn't need this.
                    verts.append(0);

                    verts.append(texCoordX);
                    verts.append(texCoordY);
                    numVerts++;
                }
                indices.append(index + 0);
                indices.append(index + 1);
                indices.append(index + 2);
                indices.append(index + 2);
                indices.append(index + 3);
                indices.append(index + 0);
                index += 4;
                mNumTris_ += 2;
            }
        }
        assert(numVerts == verts.len() / NUM_VERTS);

        local b = blob(verts.len() * 4);
        b.seek(0);
        local intFloatCount = 0;
        foreach(c,i in verts){
            local valid = c % NUM_VERTS == 0;
            if(valid){
                intFloatCount = 3;
            }
            b.writen(i, intFloatCount > 0 ? 'i' : 'f');
            intFloatCount--;
        }
        local indiceStride = index + 4 >= 0xFFFF ? 4 : 2;
        local bb = blob(indices.len() * indiceStride);
        bb.seek(0);
        local strideVal = indiceStride == 2 ? 'w' : 'i';
        foreach(i in indices){
            bb.writen(i, strideVal);
        }

        local buffer = _graphics.createVertexBuffer(mVertexElemVec_, numVerts, numVerts, b);
        local indexBuffer = _graphics.createIndexBuffer(indiceStride == 2 ? _IT_16BIT : _IT_32BIT, bb, indices.len());

        local vao = _graphics.createVertexArrayObject(buffer, indexBuffer, _OT_TRIANGLE_LIST);

        subMesh.pushMeshVAO(vao, _VP_NORMAL);
        subMesh.pushMeshVAO(vao, _VP_SHADOW);

        local halfBounds = Vec3(width/2, height/2, depth/2);
        local bounds = AABB(halfBounds, halfBounds);
        outMesh.setBounds(bounds);
        outMesh.setBoundingSphereRadius(bounds.getRadius());

        subMesh.setMaterialName("baseVoxelMaterial");

        if(mTimer_) mTimer_.stop();

        return outMesh;
    }

    function readVoxelFromData_(data, x, y, z, width, height){
        return data[x + (y * width) + (z*width*height)];
    }

    VERTICE_BORDERS = [
        //F0
        -1, -1,  0, /**/ 0, -1, -1, /**/ -1, -1, -1,
         0, -1, -1, /**/ 1, -1,  0, /**/  1, -1, -1,
         1, -1,  0, /**/ 0, -1,  1, /**/  1, -1,  1,
         0, -1,  1, /**/-1, -1,  0, /**/ -1, -1,  1,
        //F1
         1,  1,  0, /**/  0,  1, -1, /**/ 1,  1, -1,
         0,  1, -1, /**/ -1,  1,  0, /**/-1,  1, -1,
        -1,  1,  0, /**/  0,  1,  1, /**/-1,  1,  1,
         0,  1,  1, /**/  1,  1,  0, /**/ 1,  1,  1,
        //F2
         0, -1, -1, /**/ -1,  0, -1, /**/-1, -1, -1,
        -1,  0, -1, /**/  0,  1, -1, /**/-1,  1, -1,
         0,  1, -1, /**/  1,  0, -1, /**/ 1,  1, -1,
         1,  0, -1, /**/  0, -1, -1, /**/ 1, -1, -1,
        //F3
         0, -1,  1, /**/  1,  0,  1, /**/ 1, -1,  1,
         1,  0,  1, /**/  0,  1,  1, /**/ 1,  1,  1,
         0,  1,  1, /**/ -1,  0,  1, /**/-1,  1,  1,
        -1,  0,  1, /**/  0, -1,  1, /**/-1, -1,  1,
        //F4
        1, -1,  0, /**/ 1,  0, -1, /**/ 1, -1, -1,
        1,  0, -1, /**/ 1,  1,  0, /**/ 1,  1, -1,
        1,  1,  0, /**/ 1,  0,  1, /**/ 1,  1,  1,
        1,  0,  1, /**/ 1, -1,  0, /**/ 1, -1,  1,
        //F5
        -1,  0, -1, /**/ -1, -1,  0, /**/ -1, -1, -1,
        -1, -1,  0, /**/ -1,  0,  1, /**/ -1, -1,  1,
        -1,  0,  1, /**/ -1,  1,  0, /**/ -1,  1,  1,
        -1,  1,  0, /**/ -1,  0, -1, /**/ -1,  1, -1,
    ];
    //Temporary array to store values deep in the list. Prevents destruction and re-creation of the array.
    foundValsTemp = array(3, 0)
    function getVerticeBorder(data, f, x, y, z, width, height, depth){
        local ret = 0;
        for(local v = 0; v < 4; v++){
            for(local i = 0; i < 3; i++){
                local faceVal = f * 9 * 4;
                local xx = VERTICE_BORDERS[faceVal + v * 9 + i * 3];
                local yy = VERTICE_BORDERS[faceVal + v * 9 + i * 3 + 1];
                local zz = VERTICE_BORDERS[faceVal + v * 9 + i * 3 + 2];

                local xPos = x + xx;
                if(xPos < 0 || xPos >= width) continue;
                local yPos = y + yy;
                if(yPos < 0 || yPos >= height) continue;
                local zPos = z + zz;
                if(zPos < 0 || zPos >= depth) continue;

                local vox = readVoxelFromData_(data, xPos, yPos, zPos, width, height);
                foundValsTemp[i] = vox != null ? 1 : 0;
            }
            //https://0fps.net/2013/07/03/ambient-occlusion-for-minecraft-like-worlds/
            local val = 0;
            if(foundValsTemp[0] && foundValsTemp[1]){
                val = 0;
            }else{
                val = 3 - (foundValsTemp[0] + foundValsTemp[1] + foundValsTemp[2]);
            }
            assert(val >= 0 && val <= 3);
            //print("From function " + val);
            //Batch the results for all 4 vertices into the single return value.
            ret = ret | val << (v * 8);
        }
        return ret;
    }

    function getNeighbourMask(data, x, y, z, width, height, depth){
        local ret = 0;
        for(local v = 0; v < 6; v++){
            local xx = MASKS[v * 3];
            local yy = MASKS[v * 3 + 1];
            local zz = MASKS[v * 3 + 2];

            local xPos = x + xx;
            if(xPos < 0 || xPos >= width) continue;
            local yPos = y + yy;
            if(yPos < 0 || yPos >= height) continue;
            local zPos = z + zz;
            if(zPos < 0 || zPos >= depth) continue;

            local vox = readVoxelFromData_(data, xPos, yPos, zPos, width, height);
            if(vox != null){
                ret = ret | (1 << v)
            }
        }
        return ret;
    }

    function blockIsFaceVisible(mask, f){
        return 0 == ((1 << f) & mask);
    }

    function getStats(){
        local results = {
            "numTris": mNumTris_
        }
        if(mTimer_){
            results.totalSeconds <- mTimer_.getSeconds()
        }

        return results
    }
    function printStats(){
        local stats = getStats();

        print("==Voxeliser Stats==");
        printf("Num tris: %i", stats.numTris);
        if("totalSeconds" in stats) printf("Seconds: %f", stats.totalSeconds);
        print("=============================");
    }

};