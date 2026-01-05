//Simple class to render planes with textures to force these textures to be loaded.
::TextureForceLoader <- class {
    mWindow_ = null
    mPanels_ = null
    mDatablocks_ = null

    mTextureForceLoadCounter_ = 0

    constructor(texturePaths){
        mPanels_ = []
        mDatablocks_ = []

        //Create a window to force load textures.
        mWindow_ = _gui.createWindow("TextureForceLoaderWindow");
        mWindow_.setVisible(false);

        foreach(idx, texturePath in texturePaths){
            //Create an unlit datablock for each texture to ensure it is loaded.
            local datablockName = "TextureForceLoaderDatablock_" + mTextureForceLoadCounter_;
            mTextureForceLoadCounter_++;

            local datablock = _hlms.unlit.createDatablock(datablockName);
            datablock.setTexture(0, texturePath);

            local panel = mWindow_.createPanel();
            panel.setDatablock(datablock);

            mDatablocks_.append(datablock);
            mPanels_.append(panel);
        }
    }

    function shutdown(){
        //Clean up the window and associated resources.
        if( mWindow_ != null ){
            _gui.destroy(mWindow_);
            mWindow_ = null;
        }
    }
}
