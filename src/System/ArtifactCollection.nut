
/**
 * Artifact Collection system.
 * Manages the player's collection of found artifacts.
 */
::ArtifactCollection <- class{
    mArtifacts_ = null;

    constructor(){
        mArtifacts_ = [
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_1,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_2,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.MESSAGE_IN_A_BOTTLE_SCRAP_3,
            ArtifactId.ROCK_FRAGMENT_1
        ];
    }

    /**
     * Add an artifact to the collection.
     */
    function addArtifact(artifactId){
        mArtifacts_.append(artifactId);
        _event.transmit(Event.ARTIFACT_COLLECTED, artifactId);
    }

    /**
     * Get all artifact IDs in the collection.
     */
    function getArtifacts(){
        return mArtifacts_;
    }

    /**
     * Get artifact IDs filtered by type.
     */
    function getArtifactsByType(artifactType){
        local filtered = [];
        foreach(artifactId in mArtifacts_){
            local artifactDef = ::Artifacts[artifactId];
            if(artifactDef.getType() == artifactType){
                filtered.append(artifactId);
            }
        }
        return filtered;
    }

    /**
     * Check if an artifact is in the collection.
     */
    function hasArtifact(artifactId){
        foreach(artifact in mArtifacts_){
            if(artifact == artifactId){
                return true;
            }
        }
        return false;
    }

    /**
     * Get the count of artifacts in the collection.
     */
    function getArtifactCount(){
        return mArtifacts_.len();
    }

    function _tostring(){
        return ::wrapToString(::ArtifactCollection, "ArtifactCollection", format("count=%d", getArtifactCount()));
    }
};
