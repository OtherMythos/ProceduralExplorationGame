//Provides an interface to clone datablocks and manage their lifecycle using reference counting.
//For example, if an entity is damaged and needs to flash red, a datablock must be created per entity to manage the effect.
//These datablocks would be cloned from the original material and assigned per entity.
//The DatablockManager would simply provide an interface to clone datablocks and reference count their lifecycle.
::DatablockManager <- {

    mTrackedDatablocks_ = {}
    mCount_ = 0

    function setup(){

    }

    function quickCloneDatablock(blockName){
        local block = cloneDatablock(blockName, mCount_);
        mCount_++;
        return block;
    }

    function cloneDatablock(baseBlockName, uniqueId){
        local block = _hlms.getDatablock(baseBlockName);
        local targetName = format("%s-i%i", baseBlockName, uniqueId);
        local newBlock = block.cloneBlock(targetName);
        mTrackedDatablocks_.rawset(targetName, newBlock);
        return newBlock;
    }

    function removeDatablock(datablock){
        local name = datablock.getName();
        assert(mTrackedDatablocks_.rawin(name));
        assert(mTrackedDatablocks_.rawget(name).equals(datablock));
        mTrackedDatablocks_.rawdelete(name);
        _hlms.destroyDatablock(datablock);
        printf("Destroyed datablock '%s'", name);
    }

};