::BillboardManager <- class{

    mCamera_ = null;
    mSize_ = null;
    mPos_ = null;

    mTrackedNodes_ = null;

    BillboardEntry = class{
        mNode = null;
        mBillboard = null;
        constructor(node, billboard){
            mNode = node;
            mBillboard = billboard;
        }
    }

    constructor(camera, size, pos){
        mCamera_ = camera;
        mSize_ = size;
        mPos_ = pos;

        mTrackedNodes_ = [];
    }

    function shutdown(){

    }

    function setNewValues(camera, size, pos){
        mCamera_ = camera;
        mSize_ = size;
        mPos_ = pos;
        update();
    }

    function update(){
        foreach(i in mTrackedNodes_){
            if(i == null) continue;
            local pos = mCamera_.getWorldPosInWindow(i.mNode.getPositionVec3());
            if(pos == null){
                i.mBillboard.setCullVisible(false);
                continue;
            }
            i.mBillboard.setCullVisible(true);
            pos = Vec2((pos.x + 1) / 2, (-pos.y + 1) / 2);
            i.mBillboard.setPosition(mPos_ + (pos * mSize_));
        }
    }

    function trackNode(sceneNode, billboard){
        local tracked = BillboardEntry(sceneNode, billboard);

        local idx = mTrackedNodes_.find(null);
        if(idx == null){
            idx = mTrackedNodes_.len();
            mTrackedNodes_.append(tracked);
            return idx;
        }
        mTrackedNodes_[idx] = tracked;
        return idx;
    }
    function untrackNode(id){
        if(mTrackedNodes_[id] == null) return;
        mTrackedNodes_[id].mBillboard.destroy();
        mTrackedNodes_[id] = null;
    }
    function untrackAllNodes(){
        foreach(c,i in mTrackedNodes_){
            untrackNode(c);
        }
    }

    function updateHealth(id, newHealth){
        mTrackedNodes_[id].mBillboard.setHealth(newHealth);
    }
    function setVisible(id, visible){
        mTrackedNodes_[id].mBillboard.setVisible(visible);
    }
    function setMaskVisible(mask){
        foreach(i in mTrackedNodes_){
            if(i == null) continue;
            i.mBillboard.setMaskVisible(mask);
        }
    }

}

_doFile("res://src/GUI/Billboard/Billboard.nut");
_doFile("res://src/GUI/Billboard/HealthBarBillboard.nut");
_doFile("res://src/GUI/Billboard/GatewayExplorationEndBillboard.nut");
_doFile("res://src/GUI/Billboard/PlaceExplorationVisitBillboard.nut");
_doFile("res://src/GUI/Billboard/PercentageEncounterBillboard.nut");