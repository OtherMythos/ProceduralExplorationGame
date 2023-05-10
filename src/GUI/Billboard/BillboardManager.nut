::BillboardManager <- class{

    mCamera_ = null;
    mSize_ = null;

    mTrackedNodes_ = null;

    BillboardEntry = class{
        mNode = null;
        mBillboard = null;
        constructor(node, billboard){
            mNode = node;
            mBillboard = billboard;
        }
    }

    constructor(camera, size){
        mCamera_ = camera;
        mSize_ = size;

        mTrackedNodes_ = [];
    }

    function shutdown(){

    }

    function update(){
        foreach(i in mTrackedNodes_){
            if(i == null) continue;
            local pos = mCamera_.getWorldPosInWindow(i.mNode.getPosition());
            pos = Vec2((pos.x + 1) / 2, (-pos.y + 1) / 2);
            local posVisible = i.mBillboard.posVisible(pos);
            if(posVisible){
                i.mBillboard.setPosition(pos * mSize_);
            }
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
        mTrackedNodes_[id].mBillboard.destroy();
        mTrackedNodes_[id] = null;
    }

    function updateHealth(id, healthPercent){
        mTrackedNodes_[id].mBillboard.setPercentage(healthPercent);
    }

}

_doFile("res://src/GUI/Billboard/Billboard.nut");
_doFile("res://src/GUI/Billboard/HealthBarBillboard.nut");