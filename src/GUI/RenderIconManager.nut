::RenderIconManager <- {

    RenderIcon = class{
        mParentNode_ = null;
        mMesh_ = null;
        mMeshItem_ = null;
        mNode_ = null;

        mCurrentScreenPos_ = null;

        constructor(parentNode){
            mParentNode_ = parentNode;
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

            local item = _scene.createItem(mesh);
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
         * Set the size of the render icon, only width is allowed so the object will always be in proportion.
         */
        function setSize(width){
            if(!mNode_) return;
            local aabb = mMeshItem_.getLocalAabb();
            local sizeVec = aabb.getHalfSize();
            local intended = mCurrentScreenPos_ + Vec2(width, 0);
            local foundPos = ::EffectManager.getWorldPositionForWindowPos(intended);
            local posDiff = foundPos - mNode_.getPositionVec3().xy();
            local percentage = posDiff / sizeVec.xy();

            //local scaleVec = mNode_.getScale();
            //local scaleVec = Vec3(1, 1, 1);
            local newScale = percentage.x;

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