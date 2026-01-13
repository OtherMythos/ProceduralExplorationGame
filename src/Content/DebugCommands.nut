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

::DebugConsole.registerCommand("drop", "Drop an item of id near the player", 1, "i", function(command){
    local itemId = command[0].tointeger();
    if(itemId >= ItemId.MAX){
        throw format("Invalid item idx '%i'", itemId);
    }

    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    local playerPos = currentWorld.getPlayerPosition();
    currentWorld.spawnDroppedItem(playerPos + Vec3(5, 0, 0), ::Item(itemId));

    return format("Dropped '%s' near player", ::Items[itemId].getName());
});

::DebugConsole.registerCommand("artifact", "Give the player an artifact of id", 1, "i", function(command){
    local artifactId = command[0].tointeger();
    if(artifactId >= ArtifactId.MAX){
        throw format("Invalid artifact idx '%i'", artifactId);
    }
    ::Base.mArtifactCollection.addArtifact(artifactId);

    return format("Giving player '%s'", ::Artifacts[artifactId].getName());
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
        local zOrder = window.getZOrder();
        output += format("%s - x:%i,y:%i - width:%i,height:%i - Z:%i - %s\n", queryName, pos.x, pos.y, size.x, size.y, zOrder, window.getVisible() ? "visible" : "hidden");
    }

    return output;
});
::DebugConsole.registerCommand("discover", "Discover a region. Discovers all if no id is provided", 1, "i", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    if(currentWorld.getWorldType() != WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
        throw "Only call this command while in an exploration world";
    }

    local regionId = -1;
    if(command.len() >= 1){
        regionId = command[0].tointeger();
    }

    if(regionId == -1){
        currentWorld.findAllRegions();
        return "Discovered all regions."
    }

    local result = currentWorld.discoverRegion(regionId);
    if(!result){
        throw format("Unknown region with id %i", regionId);
    }
    return format("Discovered region %i", regionId);
});

::DebugConsole.registerCommand("money", "Change the value of the player's money by x amount", 1, "i", function(command){
    local moneyAmount = command[0].tointeger();
    ::Base.mPlayerStats.mInventory_.changeMoney(moneyAmount);

    return format("Giving player '%i' money", moneyAmount);
});
::DebugConsole.registerCommand("exterminate", "Destroy all enemies in the current world", 0, "", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;

    currentWorld.destroyAllEnemies();

    return "Exterminated all enemies";
});
::DebugConsole.registerCommand("spawn", "Spawn an enemy by name", 1, "s", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;

    local enemyName = "";
    foreach(c,i in command){
        enemyName += i;
        if(c != command.len()-1){
            enemyName += " ";
        }
    }

    local enemyId = ::nameToEnemyId(enemyName);
    if(enemyId == EnemyId.NONE){
        return format("No enemy found for name '%s'", enemyName);
    }

    currentWorld.createEnemyFromPlayer(enemyId);

    return format("Created enemy '%s'", enemyName);
});
::DebugConsole.registerCommand("popWorld", "Pop a world from the exploration logic", 0, "", function(command){
    local logic = ::Base.mExplorationLogic;
    local result = logic.popWorld();

    return result ? "Popped world" : "There must be at least one queued world.";
});
::DebugConsole.registerCommand("pos", "Get the current position of the player", 0, "", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;

    return format("Player position: %s", currentWorld.getPlayerPosition().tostring());
});
::DebugConsole.registerCommand("dumpToObj", "Dump the entire scene to an obj file", 0, "", function(command){
    local scenePath = _gameCore.dumpSceneToObj();

    return "Dumped to " + scenePath;
});
::DebugConsole.registerCommand("save", "Save the current game state", 0, "", function(command){
    local saveSlot = ::Base.mPlayerStats.getSaveSlot();
    ::SaveManager.writeSaveAtPath("user://" + saveSlot, ::Base.mPlayerStats.getSaveData());

    return "Saved to slot " + saveSlot;
});
::DebugConsole.registerCommand("pauseLogic", "Toggle the logic pause state in the current world", 0, "", function(command){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    local newPausedState = !currentWorld.mLogicPaused_;
    currentWorld.setLogicPaused(newPausedState);

    if(newPausedState){
        local component = ::DebugCameraSpinComponent(currentWorld);
        local componentId = currentWorld.registerWorldComponent(component);
        ::mDebugCameraSpinComponentId_ <- componentId;
        return "Logic paused - camera spinning enabled";
    }else{
        if(currentWorld.rawin("mDebugCameraSpinComponentId_")){
            currentWorld.unregisterWorldComponent(::mDebugCameraSpinComponentId_);
            delete ::mDebugCameraSpinComponentId_;
        }
        return "Logic resumed";
    }
});