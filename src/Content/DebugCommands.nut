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
::DebugConsole.registerCommand("give", "Give the player an item of id", 1, "i", function(command){
    local itemId = command[0].tointeger();
    if(itemId >= ItemId.MAX){
        throw format("Invalid item idx '%i'", itemId);
    }
    ::Base.mPlayerStats.addToInventory(::Item(itemId));

    return format("Giving player '%s'", ::Items[itemId].getName());
});

::DebugConsole.registerCommand("health", "Set the player's health to a value. Max health if no number provided.", 1, "i", function(command){
    local health = 1000000000;
    local healthDesc = "max";
    if(command.len() >= 1){
        health = command[0].tointeger();
        healthDesc = health.tostring();
    }

    ::Base.mPlayerStats.setPlayerHealth(health);

    return "Setting player health to " + healthDesc;
});