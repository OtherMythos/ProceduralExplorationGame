::DebugConsole.registerCommand("invincible", "Alter player invincibility", 0, "", function(command){
    return "Making the player invincible";
});
::DebugConsole.registerCommand("seed", "Print current world seed information", 0, "", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    local mapData = currentWorld.getMapData();
    local out = "";

    local worldType = currentWorld.getWorldType();
    if(worldType == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
    local text = @"Seed: %i
moistureSeed: %i
variationSeed: %i";
        out = format(text, mapData.seed, mapData.moistureSeed, mapData.variationSeed);
    }
    else if(worldType == WorldTypes.PROCEDURAL_DUNGEON_WORLD){
        out = "Dungeons do not use seeds yet.";
    }else{
        out = "Current world does not use seeds.";
    }

    return out;
});