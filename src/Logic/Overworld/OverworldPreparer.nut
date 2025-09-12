::OverworldPreparer <- class extends ::WorldPreparer{

    mInputData_ = null;
    mOutData_ = null;

    constructor(data=null){
        mInputData_ = data;
    }

    #Override
    function processPreparation(){
        return true;
    }

    function getOutputData(){
        return mOutData_;
    }

}