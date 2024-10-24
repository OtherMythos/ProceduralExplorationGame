::count <- 0;
::stepCount <- 0;
::createAnimation <- function(lottieAnim){
    local datablock = ::lottieMan.getDatablockForAnim(lottieAnim);

    local win = _gui.createWindow();
    win.setSize(100, 100);
    win.setZOrder(180);
    win.setPosition(100 * count, 0);
    win.setSkinPack("WindowSkinNoBorder");
    local panel = win.createPanel();
    panel.setSize(100, 100);
    panel.setDatablock(datablock);

    ::count++;
}

_tIntegration("LottieAnimationManager", "Check that the lottie animation manager works as expected", {

    "steps": [
        function(){
            ::_testHelper.waitFrames(20);

            ::lottieMan <- ::LottieAnimationManager();

            local anim = ::lottieMan.createAnimation(LottieAnimationType.SINGLE_BUFFER, "res://test/integration/System/LottieAnimationManager/bell.json", 50, 50, true);
            ::createAnimation(anim);
            local animSecond = ::lottieMan.createAnimation(LottieAnimationType.SINGLE_BUFFER, "res://test/integration/System/LottieAnimationManager/bell.json", 200, 200, false);
            ::createAnimation(animSecond);
            local animThird = ::lottieMan.createAnimation(LottieAnimationType.SINGLE_BUFFER, "res://test/integration/System/LottieAnimationManager/like.json", 200, 200, true);
            ::createAnimation(animThird);
        },
        function(){
            ::lottieMan.update();

            ::_testHelper.repeatStep();
            ::stepCount++;
            if(stepCount >= 100){
                _test.endTest();
            }
        }
    ]
});