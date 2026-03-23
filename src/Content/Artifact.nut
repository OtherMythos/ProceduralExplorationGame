
/**
 * Artifact objects.
 * This represents a single artifact instance found by the player.
 * Artifacts have an id, name, type, and path.
 */
::Artifact <- class{
    mArtifactName_ = null;
    mArtifactType_ = ArtifactType.NONE;
    mArtifactScript_ = null;
    mArtifactMesh_ = null;

    constructor(artifactName, artifactType = ArtifactType.NONE, script = null, mesh = null){
        mArtifactName_ = artifactName;
        mArtifactType_ = artifactType;
        mArtifactScript_ = script;
        mArtifactMesh_ = mesh;
    }

    function getName(){ return mArtifactName_; }
    function getType(){ return mArtifactType_; }
    function getScript(){ return mArtifactScript_; }
    function getMesh(){ return mArtifactMesh_; }

    function _tostring(){
        return ::wrapToString(::Artifact, "Artifact", getName());
    }
};
