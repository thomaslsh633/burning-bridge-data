require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

ENEMY_HQ_UNIT_ID = 0;
ENEMY_SUPPLY_DEPOT_UNIT_ID = 4;
ENEMY_HOWITZER_UNIT_ID = 27;
ENEMY_NEBELWERFER_UNIT_ID = 5;

WAVE_RESPAWN_INTERVAL = 2; -- defines how often waves will spawn
ENEMY_DEFENDERS_TO_DESTROY_NORTH = 5;
ENEMY_DEFENDERS_TO_DESTROY_SOUTH = 5;
ENEMY_BUNKERS_TO_CLEAR_DESTROY = 5;
MAX_PLAYER_UNITS_TO_LOSE = 6;

-- mission stuff
missionIds = {
	CAPTURE_VILLAGE_DEPOT = 1,
	DESTROY_DEFENDERS_NORTH	= 2,
	DESTROY_DEFENDERS_SOUTH	= 3,
	CLEAR_ALL_BUNKERS = 4,
	DO_NOT_LOSE_SIX_UNITS = 5,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.CAPTURE_VILLAGE_DEPOT, true, Text.T_CAMP_L_4_1_PRIMARY1, 100},
	{missionIds.DESTROY_DEFENDERS_NORTH, true, Text.T_CAMP_L_4_1_PRIMARY2, 75},
	{missionIds.DESTROY_DEFENDERS_SOUTH, true, Text.T_CAMP_L_4_1_PRIMARY3, 75},
	{missionIds.CLEAR_ALL_BUNKERS, false, Text.T_CAMP_L_4_1_SECONDARY1, 50},
	{missionIds.DO_NOT_LOSE_SIX_UNITS, false, Text.T_CAMP_L_4_1_SECONDARY2, 50},
};

enemySquadIds = {
	DEFENDERS_NORTH = 1,
	DEFENDERS_SOUTH = 2,
	DEFENDERS_DEPOT_CENTER = 3,
	DEFENDERS_DEPOT_VILLAGE = 4,
	DEFENDERS_SUPPLIES = 5,
	  
	SQUAD_NORTH = 6,
	SQUAD_CENTER = 7,
	
	ARTILLERY_MORTAR_SOUTH = 10,
	ARTILLERY_NEBELWERFER = 11,
	ARTILLERY_HOWITZER = 12,
	
	MG_NEST_NORTH = 13,
	MG_NEST_SOUTH = 14,
	MG_NEST_DEPOT = 15,
	  
	REINFORCEMENTS_NORTH = 20,
	REINFORCEMENTS_SOUTH = 21,
	  
	SNIPER_NORTH = 30,
	SNIPER_CENTER = 31,
	SNIPER_SOUTH = 32,
	
	REINFORCEMENTS_WAVE = 40,
	  
	MINES = 50,
};

enemyReinforcement1 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.X_INFANTRY_MG, 25, 7, enemySquadIds.REINFORCEMENTS_WAVE}
};

enemyReinforcement2 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.X_INFANTRY_AT, 25, 7, enemySquadIds.REINFORCEMENTS_WAVE}
};

enemyReinforcement3 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.X_TRUCK_MG, 25, 7, enemySquadIds.REINFORCEMENTS_WAVE}
};

enemyReinforcement4 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.X_TANK_MEDIUM, 25, 7, enemySquadIds.REINFORCEMENTS_WAVE}
};

reinforcementWaveSpawnIsActive = 0;
reinforcementWaveIsAlive = 0;
enemySupplyDepotIsCapturedDestroyed = 0;

roundOfReinforcementInit = 0;
northernDefendersDestroyed = 0;
southernDefendersDestroyed = 0;
bunkersClearedDestroyed = 0;
playerUnitsLost = 0;

-- #######################################-START_GAME-#######################################

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold(PLAYER_ID, 1500);
	--ScriptManager:fortifyUnit(51, true);
	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("northernDefendersDestroyed", northernDefendersDestroyed);
	ScriptManager:storeValue("southernDefendersDestroyed", southernDefendersDestroyed);
	ScriptManager:storeValue("bunkersClearedDestroyed", bunkersClearedDestroyed);
	ScriptManager:storeValue("playerUnitsLost", playerUnitsLost);
	ScriptManager:storeValue("reinforcementWaveIsAlive", reinforcementWaveIsAlive);
	ScriptManager:storeValue("reinforcementWaveSpawnIsActive", reinforcementWaveSpawnIsActive);
	ScriptManager:storeValue("roundOfReinforcementInit", roundOfReinforcementInit);
	ScriptManager:storeValue("enemySupplyDepotIsCapturedDestroyed", enemySupplyDepotIsCapturedDestroyed);
end

function loadValues()
	northernDefendersDestroyed = ScriptManager:getValue("northernDefendersDestroyed");
	southernDefendersDestroyed = ScriptManager:getValue("southernDefendersDestroyed");
	bunkersClearedDestroyed = ScriptManager:getValue("bunkersClearedDestroyed");
	playerUnitsLost = ScriptManager:getValue("playerUnitsLost");
	reinforcementWaveIsAlive = ScriptManager:getValue("reinforcementWaveIsAlive");
	reinforcementWaveSpawnIsActive = ScriptManager:getValue("reinforcementWaveSpawnIsActive");
	roundOfReinforcementInit = ScriptManager:getValue("roundOfReinforcementInit");
	enemySupplyDepotIsCapturedDestroyed = ScriptManager:getValue("enemySupplyDepotIsCapturedDestroyed");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	local triggerLineX = 8;
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false);
	
	-- when the player drops a paratrooper near the bunkerline
	ScriptManager:addOnDropUnitTrigger(GlobalAbility.PARATROOPER, PLAYER_ID, -1, -1, -1, "onPlayerParaTrooperDropped", "onPlayerParaTrooperDropped");
	
	-- The NEBELWERFER covers 1. Bunker 2. Depot 3. Howitzer
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnSquadDestroyedTrigger(enemySquadIds.REINFORCEMENTS_WAVE, "onEnemyReinforcementsDestroyed", "onEnemyReinforcementsDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, -1, -1, "onEnemyUnitDestroyed", "onEnemyUnitDestroyed");
	ScriptManager:addOnBunkerClearedTrigger(AI_ID, Units.N_EMPLACEMENT_BUNKER, -1, "onEnemyBunkerCleared", "onEnemyBunkerCleared");
	ScriptManager:addOnBunkerClearedTrigger(AI_ID, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "onEnemyBunkerCleared", "onEnemyBunkerCleared");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.N_EMPLACEMENT_BUNKER, -1, "onEnemyBunkerDestroyed", "onEnemyBunkerDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "onEnemyBunkerDestroyed", "onEnemyBunkerDestroyed");
	
	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, -1, -1, "onPlayerUnitDestroyed", "onPlayerUnitDestroyed");

	for y = 1, 22 do
		ScriptManager:addOnEnterTileTrigger(triggerLineX, y, PLAYER_ID, -1, -1, true, "onPlayerEnterTile", "onPlayerEnterTile", false);
	end
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, ENEMY_HQ_UNIT_ID, "onEnemyHqCaptured", "onEnemyHqCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_BUILDING_HQ, ENEMY_HQ_UNIT_ID, "transitionToFail", "transitionToFail");
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, ENEMY_SUPPLY_DEPOT_UNIT_ID, "onEnemySupplyDepotCaptured", "onEnemySupplyDepotCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_BUILDING_HQ, ENEMY_SUPPLY_DEPOT_UNIT_ID, "onEnemySupplyDepotDestroyed", "onEnemySupplyDepotDestroyed");
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, Units.X_BUILDING_HQ, -1, "showAttackedWarning", "showAttackedWarning");
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, -1, "stopAttackingHint", "stopAttackingHint");
	--ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, , -1, "transitionToFail", "transitionToFail");
end

function onEnemyHqCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_VILLAGE_DEPOT, MissionStatus.ACCOMPLISHED);
	checkForVictory();
end

function onEnemySupplyDepotDestroyed(unit)
	ScriptManager:removeTrigger("onEnemySupplyDepotDestroyed");
	ScriptManager:removeTrigger("onEnemySupplyDepotCaptured");
	
	setEnemySupplyDepotIsCapturedDestroyed(1);
	initiateEnemyReinforcements();
	
	ScriptManager:runForPlayer(PLAYER_ID, "prepareReinforcementCutscene");
end

function onEnemySupplyDepotCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemySupplyDepotCaptured");
	ScriptManager:removeTrigger("onEnemySupplyDepotDestroyed");
	
	setEnemySupplyDepotIsCapturedDestroyed(1);
	initiateEnemyReinforcements();
	
	ScriptManager:runForPlayer(PLAYER_ID, "prepareReinforcementCutscene");
end

function initiateEnemyReinforcements()
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_VILLAGE_DEPOT) ~= MissionStatus.ACCOMPLISHED) then
		setReinforcementWaveSpawnIsActive(1);
		setReinforcementWaveIsAlive(1);
		setRoundOfReinforcementInit(ScriptManager:getCurrentRound());
		ScriptManager:runForPlayer(AI_ID, "spawnEnemyReinforcementWave");
	end
end

function onEnemyUnitDestroyed(unit)
	if(unit:getSquadId() == enemySquadIds.DEFENDERS_NORTH) then
		onNorthernDefenderUnitDestroyed();
	elseif(unit:getSquadId() == enemySquadIds.DEFENDERS_SOUTH) then
		onSouthernDefenderUnitDestroyed();
	end
	
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_NORTH) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_SOUTH) == MissionStatus.ACCOMPLISHED) then
		ScriptManager:removeTrigger("onEnemyUnitDestroyed");
	end
end

function onNorthernDefenderUnitDestroyed()
	incrementNorthernDefendersDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_DEFENDERS_NORTH, getNorthernDefendersDestroyed());
	
	if(getNorthernDefendersDestroyed() >= ENEMY_DEFENDERS_TO_DESTROY_NORTH) then
		ScriptManager:setMissionStatus(missionIds.DESTROY_DEFENDERS_NORTH, MissionStatus.ACCOMPLISHED);
		
		if(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_SOUTH) ~= MissionStatus.ACCOMPLISHED) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR6, 6);	
		end
		
		checkForVictory();
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateNorthernDefenderMissionProgress");		
	end
end

function updateNorthernDefenderMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_DEFENDERS_NORTH), ENEMY_DEFENDERS_TO_DESTROY_NORTH, Text.T_CAMP_L_4_1_PRIMARY2_COUNTER);
end

function onSouthernDefenderUnitDestroyed()
	incrementSouthernDefendersDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_DEFENDERS_SOUTH, getSouthernDefendersDestroyed());
	
	if(getSouthernDefendersDestroyed() >= ENEMY_DEFENDERS_TO_DESTROY_SOUTH) then
		ScriptManager:setMissionStatus(missionIds.DESTROY_DEFENDERS_SOUTH, MissionStatus.ACCOMPLISHED);
		
		if(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_NORTH) ~= MissionStatus.ACCOMPLISHED) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR7, 6);
		end
	
		checkForVictory();
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateSouthernDefenderMissionProgress");		
	end
end

function updateSouthernDefenderMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_DEFENDERS_SOUTH), ENEMY_DEFENDERS_TO_DESTROY_SOUTH, Text.T_CAMP_L_4_1_PRIMARY3_COUNTER);
end

function onEnemyBunkerDestroyed(unit)
	incrementBunkerMissionProgress();
end

function onEnemyBunkerCleared(flamethrower, bunker)
	incrementBunkerMissionProgress();
end

function incrementBunkerMissionProgress()
	incrementBunkersCleared();
	ScriptManager:setMissionProgress(missionIds.CLEAR_ALL_BUNKERS, getBunkersClearedDestroyed());
	
	if(getBunkersClearedDestroyed() >= ENEMY_BUNKERS_TO_CLEAR_DESTROY) then
		ScriptManager:removeTrigger("onEnemyBunkerDestroyed");
		ScriptManager:removeTrigger("onEnemyBunkerCleared");
			
		Utils:setMissionStatus(missionIds.CLEAR_ALL_BUNKERS, MissionStatus.ACCOMPLISHED);
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateBunkerMissionProgress");
	end
end

function updateBunkerMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.CLEAR_ALL_BUNKERS), ENEMY_BUNKERS_TO_CLEAR_DESTROY, Text.T_CAMP_L_4_1_SECONDARY1_COUNTER);
end

function reduceArtilleryActionPoints()
	local heuristicMaxNumberOfUnits = 100;
	
	for i = 0, heuristicMaxNumberOfUnits do
		if(Unit:getUnitById(i) ~= nil) then
			if(Unit:getUnitById(i):getTemplateId() == Units.X_ARTILLERY_HOWITZER) or
				(Unit:getUnitById(i):getTemplateId() == Units.X_ARTILLERY_MORTAR) then
				Unit:getUnitById(i):setActionPoints(0);
			end
		end
	end
end

function onEnemyTurnStart(playerId, turnId, roundId)
	reduceArtilleryActionPoints();

	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_VILLAGE_DEPOT) ~= MissionStatus.ACCOMPLISHED) and
		(getEnemySupplyDepotIsCapturedDestroyed() == 1) then
		if(getReinforcementWaveSpawnIsActive() == 1) then
			if(getReinforcementWaveIsAlive() == 0) then
				if(ScriptManager:getCurrentRound() == getRoundOfReinforcementInit() + WAVE_RESPAWN_INTERVAL) then
					spawnEnemyReinforcementWave();
					setReinforcementWaveIsAlive(1);
					setRoundOfReinforcementInit(ScriptManager:getCurrentRound());
				end
			end
		end
	end
end

function onEnemyReinforcementsDestroyed()
	setReinforcementWaveIsAlive(0);
	setRoundOfReinforcementInit(ScriptManager:getCurrentRound());
end

function spawnEnemyReinforcementWave()
	-- find a wave to spawn by random number
	local rnd = math.random (0, 3);
  	local spawnTable = 0;
	
	if(rnd == 0) then
		spawnTable = enemyReinforcement1;
	elseif(rnd == 1) then
		spawnTable = enemyReinforcement2;
	elseif(rnd == 2) then
		spawnTable = enemyReinforcement3;
	else
		spawnTable = enemyReinforcement4;
	end
  
	for i = 1, #spawnTable do
		Utils:spawnUnitFromTable(spawnTable[i]);
	end
	
	local orderId = ScriptManager:addOrder(enemySquadIds.REINFORCEMENTS_WAVE, 17, 13, -1, 3, AiOrder.ATTACK);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK);
end

function onPlayerUnitDestroyed(unit)
	if(unit:getTemplateId() >= Units.L_INFANTRY_MG) and (unit:getTemplateId() < Units.L_BUILDING_HQ) then
		if(unit:getTemplateId() ~= Units.L_PLANE_SCOUT) then
			local incrementCounter = 1;
			if(unit:getTemplateId() == Units.L_TRUCK_TRANSPORT) then
				local maxUnitsInTransporter = 3;
				
				for i = 0, maxUnitsInTransporter - 1 do
					if(unit:getLoadedUnitAt(i) ~= nil) then
						incrementCounter = incrementCounter + 1;
					end
				end
			end
			
			for i = 1, incrementCounter do
				incrementPlayerUnitsLost();
			end
			
			ScriptManager:setMissionProgress(missionIds.DO_NOT_LOSE_SIX_UNITS, getPlayerUnitsLost());
			
			if(getPlayerUnitsLost() >= MAX_PLAYER_UNITS_TO_LOSE) then
				ScriptManager:removeTrigger("onPlayerUnitDestroyed");
				
				ScriptManager:setMissionStatus(missionIds.DO_NOT_LOSE_SIX_UNITS, MissionStatus.FAILED);
			elseif(getPlayerUnitsLost() == (MAX_PLAYER_UNITS_TO_LOSE * 0.5)) then
				ScriptManager:runForPlayer(PLAYER_ID, "threePlayerunitsDestroyed");
			else
				ScriptManager:runForPlayer(PLAYER_ID, "updatePlayerUnitsMissionProgress");
			end
		end
	end
end

function updatePlayerUnitsMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DO_NOT_LOSE_SIX_UNITS), MAX_PLAYER_UNITS_TO_LOSE, Text.T_CAMP_L_4_1_SECONDARY2_COUNTER);
end

function onPlayerParaTrooperDropped(targetTileX, targetTileY, spawnedTileX, spawnedTileY, dropedUnit)
	if(spawnedTileX >= 8) then
		ScriptManager:removeTrigger("onPlayerParaTrooperDropped");
		ScriptManager:removeTrigger("onPlayerEnterTile");
		
		ScriptManager:storeValue("cutsceneCamX", spawnedTileX);
		ScriptManager:storeValue("cutsceneCamY", spawnedTileY);
		startBunkerCutscene();
	end
end

function onPlayerEnterTile(tileX, tileY, playerId, unitTemplateId, unitId)
	ScriptManager:removeTrigger("onPlayerEnterTile");
	ScriptManager:removeTrigger("onPlayerParaTrooperDropped");
	
	ScriptManager:storeValue("cutsceneCamX", tileX);
	ScriptManager:storeValue("cutsceneCamY", tileY);
	startBunkerCutscene();
end

-- #######################################-AI_ORDER-#######################################

function addAiOrders()
	local aiRadiusShort = 1;
	local aiRadiusNormal = 2;
	local aiRadiusWide = 3;
	local aiRadiusArt = 4;
	local aiRadiusHowitzer = 6;

	ScriptManager:addOrder(enemySquadIds.DEFENDERS_NORTH, 17, 18, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDERS_SOUTH, 14, 5, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDERS_DEPOT_CENTER, 17, 13, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDERS_DEPOT_VILLAGE, 26, 7, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDERS_SUPPLIES, 6, 4, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.SQUAD_NORTH, 11, 18, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SQUAD_CENTER, 10, 13, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.SNIPER_NORTH, 13, 20, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_CENTER, 13, 14, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_SOUTH, 9, 7, -1, aiRadiusArt, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.MG_NEST_NORTH, 18, 17, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_SOUTH, 20, 4, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_DEPOT, 27, 7, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_MORTAR_SOUTH, 8, 5, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_NEBELWERFER, 20, 14, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_HOWITZER, 26, 10, -1, aiRadiusHowitzer, AiOrder.DEFEND);
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ);-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_HQ);-- TODO: add templateDI @end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR2, 4);
	
	ScriptManager:moveCameraEx(10, 18, 0.7, 3, true);
	ScriptManager:wait(1);
	
	ScriptManager:moveCameraEx(11, 6, 0.7, 3, true);
	ScriptManager:wait(1);
	
	ScriptManager:moveCameraEx(3, 16, 0.7, 3, true);
	ScriptManager:wait(1);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR3, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR4, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR5, 5);
	
	ScriptManager:moveCameraEx(26, 7, 0.7, 3, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR6, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR7, 6);
	
	ScriptManager:moveCameraEx(3, 16, 0.7, 4, true);
	ScriptManager:wait(1);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR8, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_INTRO_FLAVOR9, 5);

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_VILLAGE_DEPOT);
	startMission(missionIds.DO_NOT_LOSE_SIX_UNITS);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startBunkerCutscene()
	local unitX = ScriptManager:getValue("cutsceneCamX");
	local unitY = ScriptManager:getValue("cutsceneCamY");
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_SECONDARY1_FLAVOR1, 4);
	
	ScriptManager:moveCameraEx(15, 21, 0.7, 3, true);
	ScriptManager:wait(0.5);
	
	ScriptManager:displaySubtitle(Text.T_CAMP_L4_1_SECONDARY1_FLAVOR2);
	
	ScriptManager:moveCameraEx(15, 13, 0.7, 2, true);
	ScriptManager:wait(1);
	
	ScriptManager:moveCameraEx(14, 7, 0.7, 2, true);
	ScriptManager:wait(1);
	ScriptManager:dismissSubtitle();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_SECONDARY1_FLAVOR3, 5);
	ScriptManager:wait(1);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR2, 4);
	
	ScriptManager:moveCameraEx(16, 17, 0.7, 3, true);
	ScriptManager:wait(1);
	
	ScriptManager:displaySubtitle(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR3);
		
	ScriptManager:revealFogOfWar(16, 17, 1, true);
	ScriptManager:wait(2);
	
	ScriptManager:moveCameraEx(13, 5, 0.7, 2, true);
	
	ScriptManager:revealFogOfWar(13, 5, 1, true);
	ScriptManager:wait(2);
	
	ScriptManager:revealFogOfWar(16, 17, 1, false);
	ScriptManager:revealFogOfWar(13, 5, 1, false);
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:moveCameraEx(unitX, unitY, 0.7, 2, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR4, 4);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_DEFENDERS_NORTH);
	startMission(missionIds.DESTROY_DEFENDERS_SOUTH);
	startMission(missionIds.CLEAR_ALL_BUNKERS);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function prepareReinforcementCutscene()
	table.insert(queueTable, playReinforcementCutscene);
	Utils:cutsceneQueue();
end

function playReinforcementCutscene()
	ScriptManager:spawnUnit(AI_ID, Units.X_INFANTRY_MG, 17, 22, enemySquadIds.REINFORCEMENTS_NORTH);
	ScriptManager:spawnUnit(AI_ID, Units.X_INFANTRY_AT, 18, 22, enemySquadIds.REINFORCEMENTS_NORTH);
	
	ScriptManager:spawnUnit(AI_ID, Units.X_INFANTRY_MG, 15, 2, enemySquadIds.REINFORCEMENTS_SOUTH);
	ScriptManager:spawnUnit(AI_ID, Units.X_TANK_MEDIUM, 14, 1, enemySquadIds.REINFORCEMENTS_SOUTH);
	
	local orderId = ScriptManager:addOrder(enemySquadIds.REINFORCEMENTS_NORTH, 17, 13, -1, 3, AiOrder.ATTACK);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK);
	
	local orderId = ScriptManager:addOrder(enemySquadIds.REINFORCEMENTS_SOUTH, 17, 13, -1, 3, AiOrder.ATTACK);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK);

	Utils:startCutscene();

	ScriptManager:displaySubtitle(Text.T_CAMP_L_4_1_PRIMARY2_FLAVOR5);
	
	ScriptManager:moveCameraEx(17, 22, 0.7, 2, true);
	ScriptManager:wait(0.5);
	ScriptManager:revealFogOfWar(17, 22, 1, true);
	ScriptManager:wait(1);
	ScriptManager:revealFogOfWar(17, 22, 1, false);

	ScriptManager:moveCameraEx(15, 2, 0.7, 3, true);
	ScriptManager:wait(0.5);
	ScriptManager:revealFogOfWar(15, 2, 1, true);
	ScriptManager:wait(1);
	ScriptManager:revealFogOfWar(15, 2, 1, false);

	ScriptManager:dismissSubtitle();

	Utils:endCutscene();
end

function threePlayerunitsDestroyed()
	table.insert(queueTable, playPlayerWarning);
	Utils:cutsceneQueue();
end

function playPlayerWarning()
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_SECONDARY2_FLAVOR1, 5);
end

-- #######################################-END_GAME-#######################################

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_VILLAGE_DEPOT) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_NORTH)	== MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_DEFENDERS_SOUTH) == MissionStatus.ACCOMPLISHED) then
			
		if(ScriptManager:getMissionStatus(missionIds.DO_NOT_LOSE_SIX_UNITS) == MissionStatus.IN_PROGRESS) then
			Utils:missionCheckerAccomplish(missionIds.DO_NOT_LOSE_SIX_UNITS);	
		end
		
		startVictoryCutscene();
	end	 
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_VICTORY_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_VICTORY_FLAVOR2, 4); 
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L4_1_VICTORY_FLAVOR3, 4);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	--remove possible texts on the screens
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle(Text.T_MISSION_VICTORY);
	ScriptManager:wait(4);
	Utils:hideDialogue();
	Utils:endGame();
end

function transitionToFail()
	ScriptManager:runForPlayer(PLAYER_ID, "missionFailed");
end

function missionFailed()
	Utils:disablePlayerInteraction();
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle(Text.T_MISSION_FAILED);
	ScriptManager:wait(4);
	Utils:hideDialogue();
	Utils:endGame();
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getNorthernDefendersDestroyed()
	return northernDefendersDestroyed;
end

function setNorthernDefendersDestroyed(value)
	northernDefendersDestroyed = value;
	
	if(northernDefendersDestroyed >= ENEMY_DEFENDERS_TO_DESTROY_NORTH) then
		northernDefendersDestroyed = ENEMY_DEFENDERS_TO_DESTROY_NORTH;
	end
	
	ScriptManager:storeValue("northernDefendersDestroyed", northernDefendersDestroyed);
end

function incrementNorthernDefendersDestroyed()
	setNorthernDefendersDestroyed(getNorthernDefendersDestroyed() + 1);
end

function getSouthernDefendersDestroyed()
	return southernDefendersDestroyed;
end

function setSouthernDefendersDestroyed(value)
	southernDefendersDestroyed = value;
	
	if(southernDefendersDestroyed >= ENEMY_DEFENDERS_TO_DESTROY_SOUTH) then
		southernDefendersDestroyed = ENEMY_DEFENDERS_TO_DESTROY_SOUTH;
	end
	
	ScriptManager:storeValue("southernDefendersDestroyed", southernDefendersDestroyed);
end

function incrementSouthernDefendersDestroyed()
	setSouthernDefendersDestroyed(getSouthernDefendersDestroyed() + 1);
end

function getBunkersClearedDestroyed()
	return bunkersClearedDestroyed;
end

function setBunkersClearedDestroyed(value)
	bunkersClearedDestroyed = value;
	
	if(bunkersClearedDestroyed >= ENEMY_BUNKERS_TO_CLEAR_DESTROY) then
		bunkersClearedDestroyed = ENEMY_BUNKERS_TO_CLEAR_DESTROY;
	end
	
	ScriptManager:storeValue("bunkersClearedDestroyed", bunkersClearedDestroyed);
end

function incrementBunkersCleared()
	setBunkersClearedDestroyed(getBunkersClearedDestroyed() + 1);
end

function getPlayerUnitsLost()
	return playerUnitsLost;
end

function setPlayerUnitsLost(value)
	playerUnitsLost = value;
	
	if(playerUnitsLost >= MAX_PLAYER_UNITS_TO_LOSE) then
		playerUnitsLost = MAX_PLAYER_UNITS_TO_LOSE;
	end
	
	ScriptManager:storeValue("playerUnitsLost", playerUnitsLost);
end

function incrementPlayerUnitsLost()
	setPlayerUnitsLost(getPlayerUnitsLost() + 1);
end

function getReinforcementWaveIsAlive()
	return reinforcementWaveIsAlive;
end

function setReinforcementWaveIsAlive(bool)
	reinforcementWaveIsAlive = bool;
	
	ScriptManager:storeValue("reinforcementWaveIsAlive", reinforcementWaveIsAlive);
end

function getReinforcementWaveSpawnIsActive()
	return reinforcementWaveSpawnIsActive;
end

function setReinforcementWaveSpawnIsActive(bool)
	reinforcementWaveSpawnIsActive = bool;
	
	ScriptManager:storeValue("reinforcementWaveSpawnIsActive", reinforcementWaveSpawnIsActive);
end

function getRoundOfReinforcementInit()
	return roundOfReinforcementInit;
end

function setRoundOfReinforcementInit(value)
	roundOfReinforcementInit = value;
	
	ScriptManager:storeValue("roundOfReinforcementInit", roundOfReinforcementInit);
end

function getEnemySupplyDepotIsCapturedDestroyed()
	return enemySupplyDepotIsCapturedDestroyed;
end

function setEnemySupplyDepotIsCapturedDestroyed(bool)
	enemySupplyDepotIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemySupplyDepotIsCapturedDestroyed", enemySupplyDepotIsCapturedDestroyed);
end

-- #######################################-TESTING-#######################################

function testing()
	ScriptManager:spawnUnit(PLAYER_ID, Units.ALMIGHTY_GOD, 		1, 1, 42);
	ScriptManager:spawnUnit(PLAYER_ID, Units.NOTSOMIGHTY_POKEY,	2, 1, 42);
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters(selectedUnit)
	Utils:printUnitInfo(selectedUnit);
end

--END