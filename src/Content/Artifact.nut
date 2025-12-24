
/**
 * Artifact objects.
 * This represents a single artifact instance found by the player.
 * Artifacts have an id, name, type, and path.
 */
::Artifact <- class{
    mArtifactName_ = null;
    mArtifactType_ = ArtifactType.NONE;
    mArtifactScript_ = null;

    constructor(artifactName, artifactType = ArtifactType.NONE, script = null){
        mArtifactName_ = artifactName;
        mArtifactType_ = artifactType;
        mArtifactScript_ = script;
    }

    function getName(){ return mArtifactName_; }
    function getType(){ return mArtifactType_; }
    function getScript(){ return mArtifactScript_; }

    function _tostring(){
        return ::wrapToString(::Artifact, "Artifact", getName());
    }
};
