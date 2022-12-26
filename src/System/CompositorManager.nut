::CompositorManager <- {
    mRenderWindowWorkspace_ = null

    mActiveCompositors_ = []
    mTotalCompositors_ = 0

    CompositorDef = class{
        mWorkspace = null;
        mTexture = null;
        mDatablock = null;

        constructor(workspace, texture, datablock){
            mWorkspace = workspace;
            mTexture = texture;
            mDatablock = datablock;
        }

        function destroy(){
            _compositor.removeWorkspace(mWorkspace);
            _hlms.destroyDatablock(mDatablock);
            _graphics.destroyTexture(mTexture);
        }
    }

    function setup(){
        mRenderWindowWorkspace_ = _compositor.addWorkspace([_window.getRenderTexture()], _camera.getCamera(), "renderWindowWorkspace", true);
    }

    function createCompositorWorkspace(workspaceName, rqFirst, rqLast, size){
        local newTex = _graphics.createTexture("compositor/renderTexture" + mTotalCompositors_);
        newTex.setResolution(size.x.tointeger(), size.y.tointeger());
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        local newWorkspace = _compositor.addWorkspace([newTex], _camera.getCamera(), workspaceName, true);

        local datablock = _hlms.unlit.createDatablock("renderTextureDatablock" + mTotalCompositors_);
        datablock.setTexture(0, newTex);

        local compDef = CompositorDef(newWorkspace, newTex, datablock);
        local id = registerNewCompositor_(compDef);

        //Add some uniqueness to the names.
        mTotalCompositors_++;

        print("Added compositor with id " + id)

        return id;
    }

    function destroyCompositorWorkspace(workspaceId){
        local data = mActiveCompositors_[workspaceId];
        data.destroy();
        mActiveCompositors_[workspaceId] = null;
    }

    function getDatablockForCompositor(id){
        return mActiveCompositors_[id].mDatablock;
    }

    function registerNewCompositor_(newWorkspace){
        local idx = mActiveCompositors_.find(null);
        if(idx == null){
            local id = mActiveCompositors_.len();
            mActiveCompositors_.append(newWorkspace);
            return id;
        }

        mActiveCompositors_[idx] = newWorkspace;
        return idx;
    }
};
