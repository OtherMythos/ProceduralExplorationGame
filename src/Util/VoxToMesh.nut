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

    mVertexElemVec_ = null;
    mFaceExclusionMask_ = 0;

    /**
     * @param exclusionMask Allows for certain faces to always be rejected, for instance not drawing the bottom face in a terrain.
     */
    constructor(exclusionMask = 0){
        mFaceExclusionMask_ = exclusionMask;

        TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0;
        TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0;

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
            1,  0,  0,
        ];


        mVertexElemVec_ = _graphics.createVertexElemVec();
        mVertexElemVec_.pushVertexElement(_VET_FLOAT3, _VES_POSITION);
        mVertexElemVec_.pushVertexElement(_VET_FLOAT3, _VES_NORMAL);
        mVertexElemVec_.pushVertexElement(_VET_FLOAT2, _VES_TEXTURE_COORDINATES);
    }


    /**
     * Generate a mesh object from the provided voxel data.
     * @param voxData A three dimensional blob containing voxel definitions from top to bottom, left to right. A single voxel is a byte and the size must match up with the provided dimensions.
     */
    function createMeshForVoxelData(meshName, voxData, width, height, depth){
        assert(voxData.len() == width * height * depth);
        local outMesh = _graphics.createManualMesh(meshName);
        local subMesh = outMesh.createSubMesh();

        local verts = [];
        local indices = [];

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
                for(local i = 0; i < 4; i++){
                    verts.append(VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3] + x);
                    verts.append(VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 1] + y);
                    verts.append(VERTICES_POSITIONS[FACES_VERTICES[f * 4 + i]*3 + 2] + z);
                    verts.append(FACES_NORMALS[f * 3]);
                    verts.append(FACES_NORMALS[f * 3 + 1]);
                    verts.append(FACES_NORMALS[f * 3 + 2]);
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
            }
        }
        assert(numVerts == verts.len() / 8);

        local b = blob(verts.len() * 4);
        b.seek(0);
        foreach(i in verts){
            b.writen(i, 'f');
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

        local halfBounds = Vec3(width/2, height/2, depth/2);
        local bounds = AABB(halfBounds, halfBounds);
        outMesh.setBounds(bounds);
        outMesh.setBoundingSphereRadius(bounds.getRadius());

        subMesh.setMaterialName("baseVoxelMaterial");

        return outMesh;
    }

    function readVoxelFromData_(data, x, y, z, width, height){
        return data[x + (y * width) + (z*width*height)];
    }

    function getNeighbourMask(data, x, y, z, width, height, depth){
        local ret = 0;
        local i = 0;
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
            i++;
        }
        return ret;
    }

    function blockIsFaceVisible(mask, f){
        return 0 == ((1 << f) & mask);
    }

};