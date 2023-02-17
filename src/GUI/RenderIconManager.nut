::RenderIconManager <- {

    RenderIcon = class{
        mMesh_ = null;
        mMeshItem_ = null;
        mNode_ = null;

        mCurrentScreenPos_ = null;

        constructor(parentNode, mesh){
            mMesh_ = mesh;
            mCurrentScreenPos_ = Vec2();

            mNode_ = parentNode.createChildSceneNode();
            local item = _scene.createItem(mesh);
            item.setRenderQueueGroup(66);
            mNode_.attachObject(item);
            mMeshItem_ = item;
        }

        function setPosition(pos){
            mCurrentScreenPos_ = pos;
            local objectPos = ::EffectManager.getWorldPositionForWindowPos(mCurrentScreenPos_);
            mNode_.setPosition(objectPos.x, objectPos.y, 70);
        }

        /**
         * Set the size of the render icon, only width is allowed so the object will always be in proportion.
         */
        function setSize(width){
            local aabb = mMeshItem_.getLocalAabb();
            local sizeVec = aabb.getHalfSize();
            local intended = mCurrentScreenPos_ + Vec2(width, 0);
            local foundPos = ::EffectManager.getWorldPositionForWindowPos(intended);
            local posDiff = foundPos - mNode_.getPositionVec3().xy();
            local percentage = posDiff / sizeVec.xy();

            local scaleVec = mNode_.getScale();
            local newScale = scaleVec * percentage.x;

            mNode_.setScale(newScale);
        }

        function _tostring(){
            return ::wrapToString(RenderIcon, "RenderIcon", mMesh_);
        }
    }

    mActiveIcons_ = []
    mParentNode_ = null

    function setup(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
    }

    function update(){

    }

    function createIcon(mesh){
        local newIcon = RenderIcon(mParentNode_, mesh);
        mActiveIcons_.append(newIcon);
        return newIcon;
    }

}