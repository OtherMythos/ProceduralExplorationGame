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

::DebugConsole.registerCommand("tp", "Teleport the player to the provided coordinates", 2, "ii", function(command){
    local x = 0.0;
    local y = 0.0;

    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;

    local first = command[0];
    if(first == "gateway"){
        local worldType = currentWorld.getWorldType();
        if(worldType == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
            local gatewayPos = currentWorld.getMapData().gatewayPosition;
            x = (gatewayPos >> 16) & 0xFFFF;
            y = -(gatewayPos & 0xFFFF);
        }
    }else{
        x = command[0].tofloat();
        y = command[1].tofloat();
    }

    currentWorld.setPlayerPosition(x, y);

    return format("Teleporting player to '%f,%f'", x, y);
});
::DebugConsole.registerCommand("listWin", "List all the windows that currently exist.", 0, "", function(command){
    local output = "";
    local numWindows = _gui.getNumWindows();
    for(local i = 0; i < numWindows; i++){
        local window = _gui.getWindowForIdx(i);
        local queryName = window.getQueryName();
        print(queryName);
        local pos = window.getPosition();
        local size = window.getSize();
        output += format("%s - x:%i,y:%i - width:%i,height:%i - %s\n", queryName, pos.x, pos.y, size.x, size.y, window.getVisible() ? "visible" : "hidden");
    }

    return output;
});