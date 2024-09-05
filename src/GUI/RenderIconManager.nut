::RenderIconManager <- {

    RenderIcon = class{
        mParentNode_ = null;
        mMesh_ = null;
        mMeshItem_ = null;
        mNode_ = null;

        mCurrentScreenPos_ = null;

        constructor(parentNode){
            mParentNode_ = parentNode;
            //this.mParentNode_.setVisible(false);
        }

        function setMesh(mesh){
            mMesh_ = mesh;
            mCurrentScreenPos_ = Vec2();
            if(mMesh_ == null){
                if(mNode_) mNode_.destroyNodeAndChildren();
                return;
            }

            if(mNode_){
                //The node already exists, so re-create only the item.
                mNode_.recursiveDestroyAttachedObjects();
            }else{
                mNode_ = mParentNode_.createChildSceneNode();
            }

            local item = _gameCore.createVoxMeshItem(mesh);
            item.setRenderQueueGroup(66);
            mNode_.attachObject(item);
            mMeshItem_ = item;
        }

        function destroy(){
            if(mNode_) mNode_.destroyNodeAndChildren();

            mNode_ = null;
            mMesh_ = null;
            mMeshItem_ = null;
        }

        function setPosition(pos){
            if(!mNode_) return;
            mCurrentScreenPos_ = pos;
            local objectPos = ::EffectManager.getWorldPositionForWindowPos(mCurrentScreenPos_);
            mNode_.setPosition(objectPos.x, objectPos.y, 70);
        }

        /**
         * Set the size of the render icon.
         * The icon will be scaled in its aspect ratio according to fit within the bounds.
         */
        function setSize(width, height){
            if(!mNode_) return;
            local aabb = mMeshItem_.getLocalAabb();
            local sizeVec = aabb.getHalfSize();
            local y = sizeVec.y > sizeVec.x;
            local intended = mCurrentScreenPos_ + Vec2(width, height);
            local foundPos = ::EffectManager.getWorldPositionForWindowPos(intended);
            local posDiff = foundPos - mNode_.getPositionVec3().xy();
            local percentage = posDiff / sizeVec.xy();

            local newScale = y ? -percentage.y : percentage.x;

            mNode_.setScale(newScale, newScale, newScale);
        }

        function setOrientation(orientation){
            if(!mNode_) return;
            mNode_.setOrientation(orientation);
        }

        function _tostring(){
            return ::wrapToString(::RenderIconManager.RenderIcon, "RenderIcon", mMesh_);
        }
    }

    mActiveIcons_ = []
    mParentNode_ = null

    function setup(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
    }

    function update(){

    }

    function createIcon(mesh = null){
        local newIcon = RenderIcon(mParentNode_);
        if(mesh != null){
            newIcon.setMesh(mesh);
        }
        mActiveIcons_.append(newIcon);
        return newIcon;
    }

}