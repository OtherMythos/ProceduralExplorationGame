::RenderIconManager <- {

    RenderIcon = class{
        mParentNode_ = null;
        mMesh_ = null;
        mMeshItem_ = null;
        mNode_ = null;
        mMeshNode_ = null;

        mCurrentScreenPos_ = null;
        mCentreMesh_ = false;
        mDebugPanel_ = null;
        mDebugWindow_ = null;

        constructor(parentNode, centreMesh=false, debugWindow=null){
            mParentNode_ = parentNode;
            mCentreMesh_ = centreMesh;
            mDebugWindow_ = debugWindow;
            //this.mParentNode_.setVisible(false);
        }

        function setMesh(mesh){
            mMesh_ = mesh;
            if(mMesh_ == null){
                if(mNode_) mNode_.destroyNodeAndChildren();
                mNode_ = null;
                mMeshNode_ = null;
                return;
            }

            if(mNode_){
                //The node already exists, so re-create only the item.
                mNode_.recursiveDestroyAttachedObjects();
            }else{
                mNode_ = mParentNode_.createChildSceneNode();
            }

            local item = _gameCore.createVoxMeshItem(mesh);
            item.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);

            //Create a child node for the mesh if centring is enabled
            if(mCentreMesh_){
                mMeshNode_ = mNode_.createChildSceneNode();
                mMeshNode_.attachObject(item);

                //Calculate the centre offset from the AABB
                local aabb = item.getLocalAabb();
                local halfSize = aabb.getHalfSize();
                local centre = aabb.getCentre();
                mMeshNode_.setPosition(-centre.x, -centre.y, -centre.z);
            }else{
                mNode_.attachObject(item);
                mMeshNode_ = null;
            }

            mMeshItem_ = item;
        }

        function destroy(){
            if(mNode_) mNode_.destroyNodeAndChildren();

            mNode_ = null;
            mMesh_ = null;
            mMeshItem_ = null;

            if(mDebugPanel_){
                _gui.destroy(mDebugPanel_);
                mDebugPanel_ = null;
            }
        }

        function setPosition(pos){
            if(!mNode_) return;
            mCurrentScreenPos_ = pos.copy();
            local objectPos = ::EffectManager.getWorldPositionForWindowPos(mCurrentScreenPos_);
            print("objet post" + objectPos);
            mNode_.setPosition(objectPos.x, objectPos.y, 70);

            if(mDebugPanel_){
                mDebugPanel_.setCentre(mCurrentScreenPos_.x, mCurrentScreenPos_.y);
            }
        }

        function setVisible(visible){
            if(!mNode_) return;
            mNode_.setVisible(visible);
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

            newScale *= 0.5;
            mNode_.setScale(newScale, newScale, newScale);

            if(mDebugPanel_){
                mDebugPanel_.setSize(width, height);
                mDebugPanel_.setCentre(mCurrentScreenPos_.x, mCurrentScreenPos_.y);
            }
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
    mDebugPanelsEnabled_ = false
    mDebugWindow_ = null

    function setup(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        if(mDebugPanelsEnabled_){
            mDebugWindow_ = _gui.createWindow();
            mDebugWindow_.setZOrder(150);
            mDebugWindow_.setSize(_window.getSize().x, _window.getSize().y);
            mDebugWindow_.setClipBorders(0, 0, 0, 0);
            mDebugWindow_.setClickable(false);
            //mDebugWindow_.setVisualsEnabled(false);
        }
    }

    function update(){

    }

    function createIcon(mesh = null, centreMesh = false){
        local newIcon = RenderIcon(mParentNode_, centreMesh, mDebugWindow_);
        if(mesh != null){
            newIcon.setMesh(mesh);
        }

        if(mDebugPanelsEnabled_ && mDebugWindow_){
            local debugPanel = mDebugWindow_.createPanel();
            local r = (_random.rand() % 100) / 100.0;
            local g = (_random.rand() % 100) / 100.0;
            local b = (_random.rand() % 100) / 100.0;
            debugPanel.setColour(ColourValue(r, g, b, 0.3));
            debugPanel.setClickable(false);
            newIcon.mDebugPanel_ = debugPanel;
        }

        newIcon.setPosition(_window.getSize() / 2);
        newIcon.setSize(100, 100);

        mActiveIcons_.append(newIcon);
        return newIcon;
    }

}