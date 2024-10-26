
enum LottieAnimationType{
    //All frames are rendered into a single buffer when they are ready to be displayed.
    //This is best for animations which do not repeat, so the animation will need
    SINGLE_BUFFER,
    //Frames are rendered to a sprite sheet.
    //Best for animations which repeat.
    SPRITE_SHEET
};

const LOTTIE_MANAGER_SPRITES_WIDTH = 10;

//A class to manage Lottie animations and lifecycles.
::LottieAnimationManager <- class{

    LottieAnimation = class{
        mId_ = 0;
        mWidth_ = 0;
        mHeight_ = 0;
        mAnimType_ = null;
        mAnim_ = null;
        mSurface_ = null;
        mTexture_ = null;
        mStagingTexture_ = null;
        mFrame_ = 0;
        mTotalFrame_ = 0;
        mRepeat_ = false;
        mTotalWidth_ = 1;
        mTotalHeight_ = 1;
        mDatablock_ = null;
        constructor(id, width, height, animType, anim, surface, texture, stagingTexture, repeat, totalWidth=1, totalHeight=1){
            mId_ = id;
            mWidth_ = width;
            mHeight_ = height;
            mAnimType_ = animType;
            mAnim_ = anim;
            mSurface_ = surface;
            mTexture_ = texture;
            mStagingTexture_ = stagingTexture;
            mRepeat_ = repeat;
            mTotalFrame_ = mAnim_.totalFrame();
            mTotalWidth_ = totalWidth;
            mTotalHeight_ = totalHeight;

            createDatablock_();
            if(mAnimType_ == LottieAnimationType.SPRITE_SHEET){
                generateSpriteSheet_();
                setFrameForSpriteSheet_(0);
            }
        }

        function update(){
            if(mFrame_ == mTotalFrame_){
                if(mRepeat_){
                    mFrame_ = 0;
                }else{
                    return;
                }
            }

            if(mAnimType_ == LottieAnimationType.SINGLE_BUFFER){
                singleBufferTransfer_();
            }else{
                //TODO update the datablock positions.
                setFrameForSpriteSheet_(mFrame_);
            }

            mFrame_++;
        }

        function setFrameForSpriteSheet_(frame){
            //mDatablock.
        }

        function generateSpriteSheet_(){
            mStagingTexture_.startMapRegion();

            local textureBox = mStagingTexture_.mapRegion(mTotalWidth_, mTotalHeight_, 1, 1, _PFG_RGBA8_UNORM);

            for(local i = 0; i < mTotalFrame_; i++){
                local x = (i.tofloat() % LOTTIE_MANAGER_SPRITES_WIDTH).tointeger() * mWidth_;
                local y = (i.tofloat() / LOTTIE_MANAGER_SPRITES_WIDTH).tointeger() * mHeight_;
                mAnim_.renderSync(mSurface_, i);
                mSurface_.uploadToTextureBox(textureBox, x, y);
            }

            mStagingTexture_.stopMapRegion();
            mStagingTexture_.upload(textureBox, mTexture_, 0);
        }

        function singleBufferTransfer_(){
            mStagingTexture_.startMapRegion();

            local textureBox = mStagingTexture_.mapRegion(mWidth_, mHeight_, 1, 1, _PFG_RGBA8_UNORM);

            mAnim_.renderSync(mSurface_, mFrame_);

            mSurface_.uploadToTextureBox(textureBox);

            mStagingTexture_.stopMapRegion();
            mStagingTexture_.upload(textureBox, mTexture_, 0);
        }

        function createDatablock_(){
            local blendBlock = _hlms.getBlendblock({
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA
            });
            local datablock = _hlms.unlit.createDatablock("lottieManagerDatablock" + mId_, blendBlock);
            datablock.setTexture(0, mTexture_);

            mDatablock_ = datablock;
        }

        function getDatablock(){
            return mDatablock_;
        }

        function destroy(){
            _graphics.destroyTexture(mTexture_);
        }
    };

    mVersionPool_ = null;
    mTotalAnims_ = 0;

    constructor(){
        mVersionPool_ = ::VersionPool();
    }

    function createAnimation(animationType, animPath, width, height, repeat=true){
        local lottieAnim = _lottie.createAnimation(animPath);

        local surfaceWidth = width;
        local surfaceHeight = height;
        if(animationType == LottieAnimationType.SPRITE_SHEET){
            local total = lottieAnim.totalFrame();
            surfaceWidth = (total >= LOTTIE_MANAGER_SPRITES_WIDTH ? LOTTIE_MANAGER_SPRITES_WIDTH : total) * width;
            surfaceHeight = (total / LOTTIE_MANAGER_SPRITES_WIDTH).tointeger() + 1;
            surfaceHeight *= height;
        }

        local surface = _lottie.createSurface(width, height);
        local texture = _graphics.createTexture("lottieManagerTexture-" + mTotalAnims_);
        texture.setResolution(surfaceWidth, surfaceHeight);
        texture.setPixelFormat(_PFG_RGBA8_UNORM);
        texture.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        local stagingTexture = _graphics.getStagingTexture(surfaceWidth, surfaceHeight, 1, 1, _PFG_RGBA8_UNORM);

        local a = LottieAnimation(mTotalAnims_, width, height, animationType, lottieAnim, surface, texture, stagingTexture, repeat, surfaceWidth, surfaceHeight);

        local id = mVersionPool_.store(a);
        mTotalAnims_++;

        return id;
    }

    function update(){
        local data = mVersionPool_.mObject_;
        foreach(c,i in data){
            if(i == null) continue;
            i.update();
        }
    }

    function getDatablockForAnim(id){
        local anim = mVersionPool_.get(id);
        return anim.getDatablock();
    }

    function destroyForId(id){
        local val = mVersionPool_.get(id);
        val.destroy();
        mVersionPool_.unstore(id);
    }

}