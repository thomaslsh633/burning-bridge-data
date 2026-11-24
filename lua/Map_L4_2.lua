require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

PLAYER_CHURCHILL_UNIT_ID = 11;

ENEMY_HQ_UNIT_ID = 1;
ENEMY_AIRFIELD_SOUTH_EAST_UNIT_ID = 2;
ENEMY_AIRFIELD_SOUTH_WEST_UNIT_ID = 5;
ENEMY_TANK_FACTORY_UNIT_ID = 0;
ENEMY_SUPPLY_CRATES_UNIT_ID = 15;
ENEMY_BRIDGE_NORTH_UNIT_ID = 3;
ENEMY_BRIDGE_SOUTH_UNIT_ID = 4;
ENEMY_BRIDGE_SOUTH_RAIL_UNIT_ID = 14;

BRIDGES_TO_CAPTURE = 3;
NUMBER_OF_ROUNDS_UNTIL_PLANE_WAVE_SPAWN = 2;
MAX_HP_OF_BRIDGE_UNITS = 1200;

-- mission stuff
missionIds = {
	ENTER_DROP_ZONE = 1,
	CAPTURE_TANK_FACTORY = 2,
	CAPTURE_DESTROY_ENEMY_HQ = 3,
	CAPTURE_BRIDGES = 4,
	PROTECT_CHURCHILL = 5,
	CAPTURE_DESTROY_WESTERN_AIRFIELD = 6
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.ENTER_DROP_ZONE, true, Text.T_CAMP_L_4_2_PRIMARY1, 25},
	{missionIds.CAPTURE_TANK_FACTORY, true, Text.T_CAMP_L_4_2_PRIMARY2, 100},
	{missionIds.CAPTURE_DESTROY_ENEMY_HQ, true, Text.T_CAMP_L_4_2_PRIMARY3, 100},
	{missionIds.CAPTURE_BRIDGES, false, Text.T_CAMP_L_4_2_SECONDARY1, 50},
	{missionIds.PROTECT_CHURCHILL, false, Text.T_CAMP_L_4_2_SECONDARY2, 50},
	{missionIds.CAPTURE_DESTROY_WESTERN_AIRFIELD, false, Text.T_CAMP_L_4_2_SECONDARY3, 50}
};

enemySquadIds = {
	SNOW_FOREST = 1,
	SNOW_VILLAGE_SOUTH = 2,
	SNOW_VILLAGE_EAST = 3,
	
	DEFENDER_AIRFIELD_SOUTH_WEST = 4,
	DEFENDER_TANK_FACTORY = 5,
	DEFENDER_RIVER_RUINS = 6,
	DEFENDER_BRIDGE_NORTH = 7,
	DEFENDER_BRIDGE_SOUTH_FRONT = 8,
	DEFENDER_BRIDGE_SOUTH_BACK = 9,
	DEFENDER_AIRFIELD_SOUTH_EAST = 10,
	DEFENDER_ENEMY_HQ = 11,
	DEFENDER_SUPPLY_CRATES = 12,
	
	ARTILLERY_AIRFIELD_SOUTH_WEST = 20,
	ARTILLERY_TANK_FACTORY = 21,
	ARTILLERY_BRIDGE_NORTH = 22,
	ARTILLERY_BRIDGE_SOUTH = 23,
	ARTILLERY_AIRFIELD_SOUTH_EAST = 24,
	ARTILLERY_ENEMY_HQ = 25,
	
	HOWITZER_RIVER_SOUTH = 26,
	HOWITZER_RIVER_NORTH = 27,
	
	BUNKER_AIRFIELD_SOUTH_WEST = 30,
	BUNKER_BRIDGE_SOUTH_FRONT = 31,
	BUNKER_TANK_FACTORY = 32,
	BUNKER_BRIDGE_SOUTH_BACK = 33,
	BUNKER_SUPPLY_CRATES = 34,

	PLANE_WAVE_AIRFIELD_SOUTH_WEST = 50,
	PLANE_WAVE_AIRFIELD_SOUTH_EAST = 51,
};

playerParaTrooperReinforcements = {
	{Units.N_BUILDING_CRATES, 	10, 20},
	{Units.L_INFANTRY_AT, 		9, 21},
	{Units.L_INFANTRY_MG, 		9, 19},
	{Units.L_INFANTRY_MORTAR, 	10, 21},
	{Units.L_INFANTRY_FLAME, 	9, 20}
};

playerParaTrooperReinforcementsReduced = {
	{Units.L_INFANTRY_AT, 		10, 20},
	{Units.L_INFANTRY_MG, 		9, 21}
};

enemySupplyTransporterTrucks = {
	{Units.X_TRUCK_SUPPLY,		19, 15, 17, 19, 17, 23},
	{Units.X_TRUCK_SUPPLY,		19, 15, 17, 19, 17, 23},
	{Units.X_TRUCK_TRANSPORT,	19, 15, 17, 19, 17, 23}
};

enemyWesternPlaneWave = {
	{Units.X_PLANE_LIGHT,		3, 4, enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_WEST},
};

enemyEasternPlaneWave = {
	{Units.X_PLANE_LIGHT,		18, 2, enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_EAST},
};

waypointTablePlaneWaveWest = {{7, 10}, {12, 16}, {18, 18}, {18, 8}, {9, 3}};
waypointTablePlaneWaveEast = {{18, 8}, {18, 18}, {12, 16}, {7, 10}, {9, 3}};

enemyAirfieldSouthWestIsCapturedDestroyed = 0;
enemyAirfieldSouthEastIsCapturedDestroyed = 0;
enemyTankFactoryIsCaptured = 0;
enemyHqIsCaptured = 0;
enemyBridgesCaptured = 0;
dropZoneCutsceneShown = 0;
tankFactoryCutsceneShown = 0;
truckDepartureCutsceneShown = 0;

northernBridgeIsCaptured = 0;
centerBridgeIsCaptured = 0;
southernBridgeIsCaptured = 0;

westernAirfieldPlaneWaveSpawnIsActive = 0;
westernAirfieldPlaneWaveIsAlive = 0;
westernAirfieldRoundOfPlaneWaveInitiation = 0;

easternAirfieldPlaneWaveSpawnIsActive = 0;
easternAirfieldPlaneWaveIsAlive = 0;
easternAirfieldRoundOfPlaneWaveInitiation = 0;

-- #######################################-START_GAME-#######################################

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	initWesternEnemyPlaneWaveSpawn();
	initEasternEnemyPlaneWaveSpawn();
		
	ScriptManager:gainGold(PLAYER_ID, 1000);
	ScriptManager:blockGlobalAbilityButton(GlobalAbility.BLIMB);

	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("enemyAirfieldSouthWestIsCapturedDestroyed", enemyAirfieldSouthWestIsCapturedDestroyed);
	ScriptManager:storeValue("enemyAirfieldSouthEastIsCapturedDestroyed", enemyAirfieldSouthEastIsCapturedDestroyed);
	ScriptManager:storeValue("enemyTankFactoryIsCaptured", enemyTankFactoryIsCaptured);
	ScriptManager:storeValue("enemyHqIsCaptured", enemyHqIsCaptured);
	ScriptManager:storeValue("enemyBridgesCaptured", enemyBridgesCaptured);
	ScriptManager:storeValue("dropZoneCutsceneShown", dropZoneCutsceneShown);
	ScriptManager:storeValue("tankFactoryCutsceneShown", tankFactoryCutsceneShown);
	ScriptManager:storeValue("truckDepartureCutsceneShown", truckDepartureCutsceneShown);
	
	ScriptManager:storeValue("westernAirfieldPlaneWaveSpawnIsActive", westernAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("westernAirfieldPlaneWaveIsAlive", westernAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("westernAirfieldRoundOfPlaneWaveInitiation", westernAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("easternAirfieldPlaneWaveSpawnIsActive", easternAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("easternAirfieldPlaneWaveIsAlive", easternAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("easternAirfieldRoundOfPlaneWaveInitiation", easternAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("northernBridgeIsCaptured", northernBridgeIsCaptured);
	ScriptManager:storeValue("centerBridgeIsCaptured", centerBridgeIsCaptured);
	ScriptManager:storeValue("southernBridgeIsCaptured", southernBridgeIsCaptured);
end

function loadValues()
	enemyAirfieldSouthWestIsCapturedDestroyed = ScriptManager:getValue("enemyAirfieldSouthWestIsCapturedDestroyed");
	enemyAirfieldSouthEastIsCapturedDestroyed = ScriptManager:getValue("enemyAirfieldSouthEastIsCapturedDestroyed");
	enemyTankFactoryIsCaptured = ScriptManager:getValue("enemyTankFactoryIsCaptured");
	enemyHqIsCaptured = ScriptManager:getValue("enemyHqIsCaptured");
	enemyBridgesCaptured = ScriptManager:getValue("enemyBridgesCaptured");
	dropZoneCutsceneShown = ScriptManager:getValue("dropZoneCutsceneShown");
	tankFactoryCutsceneShown = ScriptManager:getValue("tankFactoryCutsceneShown");
	truckDepartureCutsceneShown = ScriptManager:getValue("truckDepartureCutsceneShown");
	
	westernAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("westernAirfieldPlaneWaveSpawnIsActive");
	westernAirfieldPlaneWaveIsAlive = ScriptManager:getValue("westernAirfieldPlaneWaveIsAlive");
	westernAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("westernAirfieldRoundOfPlaneWaveInitiation");
	
	easternAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("easternAirfieldPlaneWaveSpawnIsActive");
	easternAirfieldPlaneWaveIsAlive = ScriptManager:getValue("easternAirfieldPlaneWaveIsAlive");
	easternAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("easternAirfieldRoundOfPlaneWaveInitiation");
	
	northernBridgeIsCaptured = ScriptManager:getValue("northernBridgeIsCaptured");
	centerBridgeIsCaptured = ScriptManager:getValue("centerBridgeIsCaptured");
	southernBridgeIsCaptured = ScriptManager:getValue("southernBridgeIsCaptured");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false);
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, -1, PLAYER_CHURCHILL_UNIT_ID, "showAttackedWarning", "showAttackedWarning");
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, -1, ENEMY_TANK_FACTORY_UNIT_ID, "stopAttackingHint", "stopAttackingHint");
	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, -1, ENEMY_TANK_FACTORY_UNIT_ID, "transitionToFail", "transitionToFail");
	
	-- triggers for player
	ScriptManager:addOnUnitSelectedTrigger(PLAYER_ID, -1, -1, "onPlayerUnitSelected", "onPlayerUnitSelected");
	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, -1, PLAYER_CHURCHILL_UNIT_ID, "onPlayerChurchillDestroyed", "onPlayerChurchillDestroyed");
	ScriptManager:addOnDropUnitTrigger(GlobalAbility.PARATROOPER, PLAYER_ID, -1, -1, -1, "onPlayerUnitDropped", "onPlayerUnitDropped");
	
	-- triggers for AI
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
		
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, -1, "onEnemyHqCaptured", "onEnemyHqCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_BUILDING_HQ, -1, "onEnemyHqDestroyed", "onEnemyHqDestroyed");
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankFactoryCaptured", "onEnemyTankFactoryCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankFactoryDestroyed", "onEnemyTankFactoryDestroyed");
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.X_BUILDING_AIRFIELD, -1, "onEnemyAirfieldCaptured", "onEnemyAirfieldCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_BUILDING_AIRFIELD, -1, "onEnemyAirfieldDestroyed", "onEnemyAirfieldDestroyed");
	
	ScriptManager:addOnAiCalculationTrigger(true, "checkWaypoints", "checkWaypoints");
end

function setUpAreaTriggers()
	local dropZoneX, dropZoneY = 10, 20;
	local dropZoneTriggerRadius = 2;
	local factoryX, factoryY = 7, 11;
	local factoryTriggerRadius = 4;
	local departureNorthX, departureNorthY = 18, 18;
	local departureNorthRadius = 3;
	local departureSouthX, departureSouthY = 9, 2;
	local departureSouthRadius = 4;
	local depotZoneX, depotZoneY = 18, 8;
	local depotRadius = 4;
	
	-- triggers for on enter tiles
	Utils:addOnEnterAreaTrigger(dropZoneX, dropZoneY, dropZoneTriggerRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterDropZone", "onPlayerEnterDropZone");
	Utils:addOnEnterAreaTrigger(factoryX, factoryY, factoryTriggerRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterTankFactoryZone", "onPlayerEnterTankFactoryZone");
	Utils:addOnEnterAreaTrigger(departureNorthX, departureNorthY, departureNorthRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterTruckDepartureZone", "onPlayerEnterTruckDepartureZone");
	Utils:addOnEnterAreaTrigger(departureSouthX, departureSouthY, departureSouthRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterTruckDepartureZone", "onPlayerEnterTruckDepartureZone");
	Utils:addOnEnterAreaTrigger(depotZoneX, depotZoneY, depotRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterDepotZone", "onPlayerEnterDepotZone");
end

function setUpTriggersForBridges()
	ScriptManager:addOnBridgeRepairTrigger(PLAYER_ID, Units.N_BRIDGE_M, -1, "onBridgeRepaired", "onBridgeRepaired");
	ScriptManager:addOnBridgeRepairTrigger(PLAYER_ID, Units.N_BRIDGE_RAIL, -1, "onBridgeRepaired", "onBridgeRepaired");
	--[[ScriptManager:addOnBridgeDetonateTrigger(-1, Units.N_BRIDGE_M, -1, "onBridgeDetonated", "onBridgeDetonated");
	ScriptManager:addOnBridgeDetonateTrigger(-1, Units.N_BRIDGE_RAIL, -1, "onBridgeDetonated", "onBridgeDetonated");--]]
	ScriptManager:addOnUnitCapturedTrigger(-1, Units.N_BRIDGE_M, -1, "onBridgeCaptured", "onBridgeCaptured");
	ScriptManager:addOnUnitCapturedTrigger(-1, Units.N_BRIDGE_RAIL, -1, "onBridgeCaptured", "onBridgeCaptured");
	--[[ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BRIDGE_M, -1, "onBridgeDestroyed", "onBridgeDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BRIDGE_RAIL, -1, "onBridgeDestroyed", "onBridgeDestroyed");--]]
end

function onEnemyTurnStart(playerId, turnId, roundId)
	reduceArtilleryAndAAaction();
	
	if(getWesternAirfieldPlaneWaveSpawnIsActive() == 1) then
		if(getWesternAirfieldPlaneWaveIsAlive() == 0) then
			if(ScriptManager:getCurrentRound() == getWesternAirfieldRoundOfPlaneWaveInitiation() + NUMBER_OF_ROUNDS_UNTIL_PLANE_WAVE_SPAWN) then
				spawnEnemyPlaneWave(enemyWesternPlaneWave);
				setWesternAirfieldPlaneWaveIsAlive(1);
				setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
			end
		end
	end
	
	if(getEasternAirfieldPlaneWaveSpawnIsActive() == 1) then
		if(getEasternAirfieldPlaneWaveIsAlive() == 0) then
			if(ScriptManager:getCurrentRound() == getEasternAirfieldRoundOfPlaneWaveInitiation() + NUMBER_OF_ROUNDS_UNTIL_PLANE_WAVE_SPAWN) then
				spawnEnemyPlaneWave(enemyEasternPlaneWave);
				setEasternAirfieldPlaneWaveIsAlive(1);
				setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
			end
		end
	end
end

function onEnemySquadDestroyed(squadId)
	if(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_EAST) then
		setEasternAirfieldPlaneWaveIsAlive(0);
		setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	elseif(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_WEST) then
		setWesternAirfieldPlaneWaveIsAlive(0);
		setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	end
end

function onEnemyHqCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	
	setEnemyHqIsCaptured(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ, MissionStatus.ACCOMPLISHED);
	
	checkForVictory();
end

function onEnemyHqDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	
	setEnemyHqIsCaptured(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ, MissionStatus.ACCOMPLISHED);
	
	checkForVictory();
end

function onEnemyTankFactoryCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyTankFactoryCaptured");
	ScriptManager:removeTrigger("onEnemyTankFactoryDestroyed");
	
	setEnemyTankFactoryIsCaptured(1);
	Utils:setMissionStatus(missionIds.CAPTURE_TANK_FACTORY, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PROTECT_CHURCHILL) == MissionStatus.IN_PROGRESS) then
		ScriptManager:removeTrigger("showAttackedWarning");
		ScriptManager:removeTrigger("onPlayerChurchillDestroyed");
		
		ScriptManager:setMissionStatus(missionIds.PROTECT_CHURCHILL, MissionStatus.ACCOMPLISHED);
	end
	
	capturedUnit:setIsAttackable(false);
	
	startEnemyTankFactoryIsCapturedCutscene();
end

function onEnemyTankFactoryDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyTankFactoryDestroyed");
	ScriptManager:removeTrigger("onEnemyTankFactoryCaptured");
	
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_TANK_FACTORY) ~= MissionStatus.ACCOMPLISHED) then
		ScriptManager:setMissionStatus(missionIds.CAPTURE_TANK_FACTORY, MissionStatus.FAILED);
		ScriptManager:runForPlayer(PLAYER_ID, "transitionToFail");
	end
end

function onEnemyAirfieldCaptured(capturingUnit, capturedUnit)
	if(capturedUnit:getId() == ENEMY_AIRFIELD_SOUTH_WEST_UNIT_ID) then
		setEnemyAirfieldSouthWestIsCapturedDestroyed(1);
		setWesternAirfieldPlaneWaveSpawnIsActive(0);
		ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_WESTERN_AIRFIELD, MissionStatus.ACCOMPLISHED);
	elseif(capturedUnit:getId() == ENEMY_AIRFIELD_SOUTH_EAST_UNIT_ID) then
		setEnemyAirfieldSouthEastIsCapturedDestroyed(1);
		setEasternAirfieldPlaneWaveSpawnIsActive(0);
	end
	
	if(getEnemyAirfieldSouthWestIsCapturedDestroyed() == 1) and (getEnemyAirfieldSouthEastIsCapturedDestroyed() == 1) then
		ScriptManager:removeTrigger("onEnemyAirfieldCaptured");
		ScriptManager:removeTrigger("onEnemyAirfieldDestroyed");
		ScriptManager:removeTrigger("onEnemySquadDestroyed");
	end
end

function onEnemyAirfieldDestroyed(unit)
	if(unit:getId() == ENEMY_AIRFIELD_SOUTH_WEST_UNIT_ID) then
		setEnemyAirfieldSouthWestIsCapturedDestroyed(1);
		setWesternAirfieldPlaneWaveSpawnIsActive(0);
		ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_WESTERN_AIRFIELD, MissionStatus.ACCOMPLISHED);
	elseif(unit:getId() == ENEMY_AIRFIELD_SOUTH_EAST_UNIT_ID) then
		setEnemyAirfieldSouthEastIsCapturedDestroyed(1);
		setEasternAirfieldPlaneWaveSpawnIsActive(0);
	end
	
	if(getEnemyAirfieldSouthWestIsCapturedDestroyed() == 1) and (getEnemyAirfieldSouthEastIsCapturedDestroyed() == 1) then
		ScriptManager:removeTrigger("onEnemyAirfieldDestroyed");
		ScriptManager:removeTrigger("onEnemyAirfieldCaptured");
		ScriptManager:removeTrigger("onEnemySquadDestroyed");
	end
end

function onPlayerUnitSelected(unit)
	ScriptManager:removeTrigger("onPlayerUnitSelected");
	
	startDropZoneCutscene();
	
	setUpAreaTriggers();
end

function onPlayerChurchillDestroyed()
	ScriptManager:removeTrigger("onPlayerChurchillDestroyed");
	ScriptManager:removeTrigger("showAttackedWarning");
	
	ScriptManager:setMissionStatus(missionIds.PROTECT_CHURCHILL, MissionStatus.FAILED);
end

function onPlayerEnterDropZone()
	ScriptManager:removeTrigger("onPlayerEnterDropZone");
	
	Utils:setMissionStatus(missionIds.ENTER_DROP_ZONE, MissionStatus.ACCOMPLISHED);
	setDropZoneCutsceneShown(1);
	startDropUnitCutscene();
	
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_TANK_FACTORY) == MissionStatus.NOT_STARTED) then
		ScriptManager:removeTrigger("onPlayerEnterTankFactoryZone");
	
		setTankFactoryCutsceneShown(1);
		table.insert(queueTable, startTankfactoryCutscene);
		Utils:cutsceneQueue();
	end
	
	checkForVictory();
end

function onPlayerEnterTankFactoryZone()
	ScriptManager:removeTrigger("onPlayerEnterTankFactoryZone");
	
	setTankFactoryCutsceneShown(1);
	startTankfactoryCutscene();
end

function onPlayerEnterTruckDepartureZone()
	ScriptManager:removeTrigger("onPlayerEnterTruckDepartureZone");
	ScriptManager:removeTrigger("onPlayerEnterDepotZone");
	
	setTruckDepartureCutsceneShown(1);
	startTrucksLeaveCutscene();
end

function onPlayerEnterDepotZone()
	onPlayerEnterTruckDepartureZone();
end

function onPlayerUnitDropped(targetTileX, targetTileY, spawnedTileX, spawnedTileY, dropedUnit)
	local dropZoneX, dropZoneY = 8, 18;
	local dropZoneHeight, dropZoneLength = 5, 5;
	local factoryX, factoryY = 5, 6;
	local factoryZoneHeight, factoryZoneLength = 9, 8;
	local departureNorthX, departureNorthY = 15, 15;
	local departureNorthHeight, departureNorthLength = 6, 4;
	local departureSouthX, departureSouthY = 7, 1;
	local departureSouthHeight, departureSouthLength = 4, 5;
	local depotZoneX, depotZoneY = 15, 5;
	local depotZoneHeight, depotZoneLength = 9, 5;
	
	if((spawnedTileX >= dropZoneX) and (spawnedTileX <= (dropZoneX + dropZoneLength))) and
		((spawnedTileY >= dropZoneY) and (spawnedTileY <= (dropZoneY + dropZoneHeight))) then
		if(getDropZoneCutsceneShown() == 0) then
			onPlayerEnterDropZone();
		end
	elseif((spawnedTileX >= factoryX) and (spawnedTileX <= (factoryX + factoryZoneLength))) and
		((spawnedTileY >= factoryY) and (spawnedTileY <= (factoryY + factoryZoneHeight))) then
		if(getTankFactoryCutsceneShown() == 0) then
			onPlayerEnterTankFactoryZone();
		end
	elseif((spawnedTileX >= departureNorthX) and (spawnedTileX <= (departureNorthX + departureNorthLength))) and
		((spawnedTileY >= departureNorthY) and (spawnedTileY <= (departureNorthY + departureNorthHeight))) then
		if(getTruckDepartureCutsceneShown() == 0) then
			onPlayerEnterTruckDepartureZone();
		end
	elseif((spawnedTileX >= departureSouthX) and (spawnedTileX <= (departureSouthX + departureSouthLength))) and
		((spawnedTileY >= departureSouthY) and (spawnedTileY <= (departureSouthY + departureSouthHeight))) then
		if(getTruckDepartureCutsceneShown() == 0) then
			onPlayerEnterTruckDepartureZone();
		end
	elseif((spawnedTileX >= depotZoneX) and (spawnedTileX <= (depotZoneX + depotZoneLength))) and
		((spawnedTileY >= depotZoneY) and (spawnedTileY <= (depotZoneY + depotZoneHeight))) then
		if(getTruckDepartureCutsceneShown() == 0) then
			onPlayerEnterTruckDepartureZone();
		end
	end
	
	if(getDropZoneCutsceneShown() == 1) and (getTankFactoryCutsceneShown() == 1) and (getTruckDepartureCutsceneShown() == 1) then
		ScriptManager:removeTrigger("onPlayerUnitDropped");
	end
end

function onBridgeCaptured(capturingUnit, capturedUnit)
	if(capturingUnit ~= nil) then
		if(capturingUnit:getPlayerId() == PLAYER_ID) then
			if(capturedUnit:getId() == ENEMY_BRIDGE_NORTH_UNIT_ID) then
				setNorthernBridgeIsCaptured(1);
			elseif(capturedUnit:getId() == ENEMY_BRIDGE_SOUTH_UNIT_ID) then
				setCenterBridgeIsCaptured(1);
			elseif(capturedUnit:getId() == ENEMY_BRIDGE_SOUTH_RAIL_UNIT_ID) then
				setSouthernBridgeIsCaptured(1);
			end
			
			incrementBridgeMissionProgress();
		else
			if(capturedUnit:getId() == ENEMY_BRIDGE_NORTH_UNIT_ID) then
				setNorthernBridgeIsCaptured(0);
			elseif(capturedUnit:getId() == ENEMY_BRIDGE_SOUTH_UNIT_ID) then
				setCenterBridgeIsCaptured(0);
			elseif(capturedUnit:getId() == ENEMY_BRIDGE_SOUTH_RAIL_UNIT_ID) then
				setSouthernBridgeIsCaptured(0);
			end
			
			decrementBridgeMissionProgress();
		end
	end
end

function onBridgeDestroyed(unit)
	--TODO Trigger is called two times!
	decrementBridgeMissionProgress();
end

function onBridgeRepaired(repairer, bridge)
	if(bridge ~= nil) then
		local currentHealth = bridge:getHealth();
		
		if(currentHealth >= MAX_HP_OF_BRIDGE_UNITS) then
			if(bridge:getId() == ENEMY_BRIDGE_NORTH_UNIT_ID) then
				if(getNorthernBridgeIsCaptured() == 0) then
					incrementBridgeMissionProgress();
				end
			elseif(bridge:getId() == ENEMY_BRIDGE_SOUTH_UNIT_ID) then
				if(getCenterBridgeIsCaptured() == 0) then
					incrementBridgeMissionProgress();
				end
			elseif(bridge:getId() == ENEMY_BRIDGE_SOUTH_RAIL_UNIT_ID) then
				if(getSouthernBridgeIsCaptured() == 0) then
					incrementBridgeMissionProgress();
				end
			end
			
		end
	end
end

function onBridgeDetonated(detonater, bridge)
	decrementBridgeMissionProgress();
end

function incrementBridgeMissionProgress()
	incrementEnemyBridgesCaptured();
	ScriptManager:setMissionProgress(missionIds.CAPTURE_BRIDGES, getEnemyBridgesCaptured());
	
	if(getEnemyBridgesCaptured() >= BRIDGES_TO_CAPTURE) then
		--Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_SECONDARY1_FLAVOR3, 4);
		ScriptManager:removeTrigger("onBridgeCaptured");
		ScriptManager:removeTrigger("onBridgeRepaired");
		
		ScriptManager:setMissionStatus(missionIds.CAPTURE_BRIDGES, MissionStatus.ACCOMPLISHED);
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
	end
end

function decrementBridgeMissionProgress()
	if(getEnemyBridgesCaptured() > 0) then
		decrementEnemyBridgesCaptured();
		ScriptManager:setMissionProgress(missionIds.CAPTURE_BRIDGES, getEnemyBridgesCaptured());
		
		ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
	end
end

function updateBridgeMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.CAPTURE_BRIDGES), BRIDGES_TO_CAPTURE, Text.T_CAMP_L_4_2_SECONDARY1_COUNTER);
end

-- #######################################-AI_ORDER-#######################################

function addAiOrders()
	local aiRadiusNormal = 2;
	local aiRadiusWide = 3;
	local aiRadiusArt = 4;
	local aiRadiusHowitzer = 6;
	
	--TODO add coordinates
	ScriptManager:addOrder(enemySquadIds.SNOW_FOREST, 6, 22, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNOW_VILLAGE_SOUTH, 2, 14, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNOW_VILLAGE_EAST, 8, 16, -1, aiRadiusNormal, AiOrder.DEFEND);

	ScriptManager:addOrder(enemySquadIds.DEFENDER_AIRFIELD_SOUTH_WEST, 3, 4, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_TANK_FACTORY, 8, 9, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_RIVER_RUINS, 13, 17, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_NORTH, 16, 21, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_SOUTH_FRONT, 8, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_SOUTH_BACK, 12, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_AIRFIELD_SOUTH_EAST, 18, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_ENEMY_HQ, 18, 8, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES, 19, 14, -1, aiRadiusNormal, AiOrder.DEFEND);

	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AIRFIELD_SOUTH_WEST, 2, 4, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_TANK_FACTORY, 10, 9, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_BRIDGE_NORTH, 18, 20, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_BRIDGE_SOUTH, 13, 5, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AIRFIELD_SOUTH_EAST, 18, 3, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_ENEMY_HQ, 17, 9, -1, aiRadiusArt, AiOrder.DEFEND);

	ScriptManager:addOrder(enemySquadIds.HOWITZER_RIVER_SOUTH, 16, 10, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.HOWITZER_RIVER_NORTH, 16, 14, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.BUNKER_AIRFIELD_SOUTH_WEST, 1, 4, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_BRIDGE_SOUTH_FRONT, 8, 4, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_TANK_FACTORY, 9, 9, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_BRIDGE_SOUTH_BACK, 12, 4, -1, aiRadiusArt, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_SUPPLY_CRATES, 18, 16, -1, aiRadiusArt, AiOrder.DEFEND);
end

function checkWaypoints(squadId, mainOrderData, allMainOrderData)
	if(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_WEST) then
		Utils:checkWaypoints(squadId, mainOrderData, allMainOrderData, waypointTablePlaneWaveWest);
	elseif(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_SOUTH_EAST) then
		Utils:checkWaypoints(squadId, mainOrderData, allMainOrderData, waypointTablePlaneWaveEast);
	end
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
	
	if(missionId == missionIds.CAPTURE_BRIDGES) then
		setUpTriggersForBridges();
	end
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );-- TODO: add templateDI @end
end

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.ENTER_DROP_ZONE) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_TANK_FACTORY) == MissionStatus.ACCOMPLISHED) then
		
		--[[if(getEnemyBridgesCaptured() >= BRIDGES_TO_CAPTURE) then
			Utils:missionCheckerAccomplish(missionIds.CAPTURE_BRIDGES);
		end--]]
		
		--[[if(ScriptManager:getMissionStatus(missionIds.CAPTURE_BRIDGES) ~= MissionStatus.ACCOMPLISHED) then
			ScriptManager:setMissionStatus(missionIds.CAPTURE_BRIDGES, MissionStatus.FAILED);
		end--]]
		
		--startVictoryCutscene();
		ScriptManager:runForPlayer(PLAYER_ID, "queueVictoryCutscene");
	end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	local currentCamX = ScriptManager:getCurrentCameraPositionX();
	local currentCamY = ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();

	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR2, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR3, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR4, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR5, 3);

	ScriptManager:moveCameraEx(18, 8, 0.7, 3, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR6, 3);
	
	if(Unit:getUnitById(PLAYER_CHURCHILL_UNIT_ID) ~= nil) then
		local churchillX = Unit:getUnitById(PLAYER_CHURCHILL_UNIT_ID):getX();
		local churchillY = Unit:getUnitById(PLAYER_CHURCHILL_UNIT_ID):getY();
		
		ScriptManager:moveCameraEx(churchillX, churchillY, 0.7, 3, true);
		ScriptManager:showMarkerAt(churchillX, churchillY);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR7, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR8, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_INTRO_FLAVOR9, 3);
		
		Utils:hideAllMarkers();
	else
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	end
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_DESTROY_ENEMY_HQ);
	if(Unit:getUnitById(PLAYER_CHURCHILL_UNIT_ID) ~= nil) then
		startMission(missionIds.PROTECT_CHURCHILL);
	end
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startDropZoneCutscene()
	local currentCamX = ScriptManager:getCurrentCameraPositionX();
	local currentCamY = ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR1, 3);
	
	ScriptManager:moveCameraEx(10, 20, 0.7, 2, true);
	
	ScriptManager:revealFogOfWar(10, 20, 1, true );
	ScriptManager:wait(1);
	ScriptManager:showScaledMarkerAt(10, 20, 2);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR2, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR3, 4);

	Utils:hideAllMarkers();
	ScriptManager:revealFogOfWar(10, 20, 1, false);
	ScriptManager:wait(1);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR4, 4);
	
	ScriptManager:moveCameraEx(18, 2, 0.7, 3, true);
	ScriptManager:wait(1);
	ScriptManager:moveCameraEx(2, 3, 0.7, 2, true);
	ScriptManager:revealFogOfWar(2, 3, 1, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR5, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR6, 6);
	
	ScriptManager:revealFogOfWar(2, 3, 1, false);
	ScriptManager:wait(1);
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.ENTER_DROP_ZONE);
	startMission(missionIds.CAPTURE_DESTROY_WESTERN_AIRFIELD);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startDropUnitCutscene()
	local currentCamX = ScriptManager:getCurrentCameraPositionX();
	local currentCamY = ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(10, 20, 0.7, 2, true);
	ScriptManager:revealFogOfWar(10, 20, 1, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR7, 4);
	
	ScriptManager:wait(1);
	
	if(getEnemyAirfieldSouthWestIsCapturedDestroyed() == 1) then
		spawnParaTrooperReinforcements(playerParaTrooperReinforcements);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR8, 5);
	else
		spawnParaTrooperReinforcements(playerParaTrooperReinforcementsReduced);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY1_FLAVOR9, 5);
	end
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	ScriptManager:revealFogOfWar(10, 20, 1, false);
	
	Utils:endCutscene();
end

function startTankfactoryCutscene()
	local currentCamX = ScriptManager:getCurrentCameraPositionX();
	local currentCamY = ScriptManager:getCurrentCameraPositionY();
	
	if(Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID) ~= nil) then
		local factoryPosX = Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getX();
		local factoryPosY = Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getY();
		
		Utils:startCutscene();

		ScriptManager:revealFogOfWar(factoryPosX, factoryPosY, 1, true);
		ScriptManager:moveCameraEx(factoryPosX, factoryPosY, 0.7, 2, true);
		ScriptManager:wait(0.5);
		
		ScriptManager:showMarkerAt(factoryPosX, factoryPosY);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY2_FLAVOR1, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY2_FLAVOR2, 6);
		
		ScriptManager:removeAllMarkers();
		ScriptManager:wait(0.5);
		
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
		ScriptManager:revealFogOfWar(factoryPosX, factoryPosY, 1, false);
		
		Utils:endCutscene();
		Utils:disablePlayerInteraction();
		
		startMission(missionIds.CAPTURE_TANK_FACTORY);
		ScriptManager:wait(2);
		
		Utils:enablePlayerInteraction();
	end
end

function startTrucksLeaveCutscene()
	local currentCamX = ScriptManager:getCurrentCameraPositionX();
	local currentCamY = ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(18, 18, 0.7, 3, true);
	
	ScriptManager:revealFogOfWar(18, 18, 2, true);
	
	spawnEnemySupplyTrucksForCutscene();
 
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_SECONDARY1_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_SECONDARY1_FLAVOR2, 6);

	ScriptManager:revealFogOfWar(18, 18, 2, false);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_BRIDGES);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startEnemyTankFactoryIsCapturedCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_PRIMARY2_FLAVOR3, 3);

	if(ScriptManager:getMissionStatus(missionIds.PROTECT_CHURCHILL) == MissionStatus.IN_PROGRESS) then
		local churchill = Unit:getUnitById(PLAYER_CHURCHILL_UNIT_ID);
		local churchillX = churchill:getX();
		local churchillY = churchill:getY();
	
		ScriptManager:moveCameraEx(churchillX, churchillY, 0.7, 2, true);
		ScriptManager:showMarkerAt(churchillX, churchillY);
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L_4_2_SECONDARY2_FLAVOR1, 4 );
		Utils:hideAllMarkers();
	end
	
	Utils:endCutscene();
	
	checkForVictory();
end

function queueVictoryCutscene()
	table.insert(queueTable, startVictoryCutscene);
	Utils:cutsceneQueue();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L4_2_VICTORY_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L4_2_VICTORY_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L4_2_VICTORY_FLAVOR3, 4 );

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

-- #######################################-END_GAME-#######################################

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
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

-- #######################################-UNITS_AND_HELPER-#######################################

function spawnParaTrooperReinforcements(reinforcements)
	local unitTable = reinforcements;
	local timeToWait = 3;
	
	if(unitTable ~= nil) then
		for i = 1, #unitTable do
			local currentAbility = GlobalAbility.PARATROOPER;
			local currentX, currentY = unitTable[i][2], unitTable[i][3];
			
			if(unitTable[i][1] == Units.N_BUILDING_CRATES) then
				currentAbility = GlobalAbility.SUPPLY_CRATE;
			end
			
			if(Unit:getUnitAt(currentX, currentY) == nil) then
				ScriptManager:runAbility(PLAYER_ID, unitTable[i][1], -1, currentAbility, currentX, currentY, -1);
				ScriptManager:wait(timeToWait);
			else
				currentX, currentY = Utils:getNextFreeNeighbouringHexTile(currentX, currentY);
				
				if(Unit:getUnitAt(currentX, currentY) == nil) then
					ScriptManager:runAbility(PLAYER_ID, unitTable[i][1], -1, currentAbility, currentX, currentY, -1);
					ScriptManager:wait(timeToWait);
				end
			end
		end
	end
end

function spawnEnemyPlaneWave(unitTable)
	local enemyPlaneWave = unitTable
	local aiRadiusNormal = 2;
	
	if(enemyPlaneWave ~= nil) then
		for i = 1, #enemyPlaneWave do
			if(Unit:getUnitAt(enemyPlaneWave[i][2], enemyPlaneWave[i][3]) == nil) then
				ScriptManager:spawnUnit(AI_ID, enemyPlaneWave[i][1], enemyPlaneWave[i][2], enemyPlaneWave[i][3], enemyPlaneWave[i][4]);
			end
		end
		
		local orderID = ScriptManager:addOrder(enemyPlaneWave[1][4], -1, -1, -1, aiRadiusNormal, AiOrder.ATTACK);
		ScriptManager:enableOrderFlag(orderID, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	end
end

function spawnEnemySupplyTrucksForCutscene()
	for i = 1, #enemySupplyTransporterTrucks do
		local currentUnitId = -1;
		
		if(enemySupplyTransporterTrucks[i][1] == Units.X_TRUCK_TRANSPORT) then
			currentUnitId = ScriptManager:spawnUnitWithTransporter(AI_ID, enemySupplyTransporterTrucks[i][1], Units.X_INFANTRY_MG, enemySupplyTransporterTrucks[i][2], enemySupplyTransporterTrucks[i][3], -1):getId();
		else
			currentUnitId = ScriptManager:spawnUnit(AI_ID, enemySupplyTransporterTrucks[i][1], enemySupplyTransporterTrucks[i][2], enemySupplyTransporterTrucks[i][3], -1):getId();
		end
		
		if(currentUnitId ~= -1) then
			--ScriptManager:moveUnitEx(currentUnitId, enemySupplyTransporterTrucks[i][4], enemySupplyTransporterTrucks[i][5], true);
			ScriptManager:moveUnitEx(currentUnitId, enemySupplyTransporterTrucks[i][6], enemySupplyTransporterTrucks[i][7], true);
			ScriptManager:removeUnitEx(currentUnitId, true);
		end
	end
end

function initWesternEnemyPlaneWaveSpawn()
	setWesternAirfieldPlaneWaveSpawnIsActive(1);
	setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
end

function initEasternEnemyPlaneWaveSpawn()
	setEasternAirfieldPlaneWaveSpawnIsActive(1);
	setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
end

function reduceArtilleryAndAAaction()
	local heuristicMaxNumberOfUnits = 150;

	for i = 0, heuristicMaxNumberOfUnits do
		if(Unit:getUnitById(i) ~= nil) then
			local currentTemplateId = Unit:getUnitById(i):getTemplateId();
			
			if(currentTemplateId >= Units.X_TRUCK_MG) and (currentTemplateId <= Units.X_ARTILLERY_MORTAR)then
				Unit:getUnitById(i):setActionPoints(0);
			end
		end
	end
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getEnemyAirfieldSouthWestIsCapturedDestroyed()
	return enemyAirfieldSouthWestIsCapturedDestroyed;
end

function setEnemyAirfieldSouthWestIsCapturedDestroyed(bool)
	enemyAirfieldSouthWestIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyAirfieldSouthWestIsCapturedDestroyed", enemyAirfieldSouthWestIsCapturedDestroyed);
end

function getEnemyAirfieldSouthEastIsCapturedDestroyed()
	return enemyAirfieldSouthEastIsCapturedDestroyed;
end

function setEnemyAirfieldSouthEastIsCapturedDestroyed(bool)
	enemyAirfieldSouthEastIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyAirfieldSouthEastIsCapturedDestroyed", enemyAirfieldSouthEastIsCapturedDestroyed);
end

function getEnemyTankFactoryIsCaptured()
	return enemyTankFactoryIsCaptured;
end

function setEnemyTankFactoryIsCaptured(bool)
	enemyTankFactoryIsCaptured = bool;
	
	ScriptManager:storeValue("enemyTankFactoryIsCaptured", enemyTankFactoryIsCaptured);
end

function getEnemyHqIsCaptured()
	return enemyHqIsCaptured;
end

function setEnemyHqIsCaptured(bool)
	enemyHqIsCaptured = bool;
	
	ScriptManager:storeValue("enemyHqIsCaptured", enemyHqIsCaptured);
end

function getEnemyBridgesCaptured()
	return enemyBridgesCaptured;
end

function setEnemyBridgesCaptured(value)
	enemyBridgesCaptured = value;
	
	if(enemyBridgesCaptured >= BRIDGES_TO_CAPTURE) then
		enemyBridgesCaptured = BRIDGES_TO_CAPTURE;
	elseif(enemyBridgesCaptured <= 0) then
		enemyBridgesCaptured = 0;
	end
	
	ScriptManager:storeValue("enemyBridgesCaptured", enemyBridgesCaptured);
end

function incrementEnemyBridgesCaptured()
	setEnemyBridgesCaptured(getEnemyBridgesCaptured() + 1);
end

function decrementEnemyBridgesCaptured()
	setEnemyBridgesCaptured(getEnemyBridgesCaptured() - 1);
end

function getDropZoneCutsceneShown()
	return dropZoneCutsceneShown;
end

function setDropZoneCutsceneShown(bool)
	dropZoneCutsceneShown = bool;
	
	ScriptManager:storeValue("dropZoneCutsceneShown", dropZoneCutsceneShown);
end

function getTankFactoryCutsceneShown()
	return tankFactoryCutsceneShown;
end

function setTankFactoryCutsceneShown(bool)
	tankFactoryCutsceneShown = bool;
	
	ScriptManager:storeValue("tankFactoryCutsceneShown", tankFactoryCutsceneShown);
end

function getTruckDepartureCutsceneShown()
	return truckDepartureCutsceneShown;
end

function setTruckDepartureCutsceneShown(bool)
	truckDepartureCutsceneShown = bool;
	
	ScriptManager:storeValue("truckDepartureCutsceneShown", truckDepartureCutsceneShown);
end

function getWesternAirfieldPlaneWaveSpawnIsActive()
	return westernAirfieldPlaneWaveSpawnIsActive;
end

function setWesternAirfieldPlaneWaveSpawnIsActive(bool)
	westernAirfieldPlaneWaveSpawnIsActive = bool;
	
	ScriptManager:storeValue("westernAirfieldPlaneWaveSpawnIsActive", westernAirfieldPlaneWaveSpawnIsActive);
end

function getWesternAirfieldPlaneWaveIsAlive()
	return westernAirfieldPlaneWaveIsAlive;
end

function setWesternAirfieldPlaneWaveIsAlive(bool)
	westernAirfieldPlaneWaveIsAlive = bool;
	
	ScriptManager:storeValue("westernAirfieldPlaneWaveIsAlive", westernAirfieldPlaneWaveIsAlive);
end

function getWesternAirfieldRoundOfPlaneWaveInitiation()
	return westernAirfieldRoundOfPlaneWaveInitiation;
end

function setWesternAirfieldRoundOfPlaneWaveInitiation(value)
	westernAirfieldRoundOfPlaneWaveInitiation = value;
	
	ScriptManager:storeValue("westernAirfieldRoundOfPlaneWaveInitiation", westernAirfieldRoundOfPlaneWaveInitiation);
end

function getEasternAirfieldPlaneWaveSpawnIsActive()
	return easternAirfieldPlaneWaveSpawnIsActive;
end

function setEasternAirfieldPlaneWaveSpawnIsActive(bool)
	easternAirfieldPlaneWaveSpawnIsActive = bool;
	
	ScriptManager:storeValue("easternAirfieldPlaneWaveSpawnIsActive", easternAirfieldPlaneWaveSpawnIsActive);
end

function getEasternAirfieldPlaneWaveIsAlive()
	return easternAirfieldPlaneWaveIsAlive;
end

function setEasternAirfieldPlaneWaveIsAlive(bool)
	easternAirfieldPlaneWaveIsAlive = bool;
	
	ScriptManager:storeValue("easternAirfieldPlaneWaveIsAlive", easternAirfieldPlaneWaveIsAlive);
end

function getEasternAirfieldRoundOfPlaneWaveInitiation()
	return easternAirfieldRoundOfPlaneWaveInitiation;
end

function setEasternAirfieldRoundOfPlaneWaveInitiation(value)
	easternAirfieldRoundOfPlaneWaveInitiation = value;
	
	ScriptManager:storeValue("easternAirfieldRoundOfPlaneWaveInitiation", easternAirfieldRoundOfPlaneWaveInitiation);
end

function getNorthernBridgeIsCaptured()
	return northernBridgeIsCaptured;
end

function setNorthernBridgeIsCaptured(bool)
	northernBridgeIsCaptured = bool;
	
	ScriptManager:storeValue("northernBridgeIsCaptured", northernBridgeIsCaptured);
end

function getCenterBridgeIsCaptured()
	return centerBridgeIsCaptured;
end

function setCenterBridgeIsCaptured(bool)
	centerBridgeIsCaptured = bool;
	
	ScriptManager:storeValue("centerBridgeIsCaptured", centerBridgeIsCaptured);
end

function getSouthernBridgeIsCaptured()
	return southernBridgeIsCaptured;
end

function setSouthernBridgeIsCaptured(bool)
	southernBridgeIsCaptured = bool;
	
	ScriptManager:storeValue("southernBridgeIsCaptured", southernBridgeIsCaptured);
end

-- #######################################-TESTING-#######################################

function testing()
	ScriptManager:spawnUnit(PLAYER_ID, Units.ALMIGHTY_GOD, 		1, 1, 42);
	ScriptManager:spawnUnit(PLAYER_ID, Units.NOTSOMIGHTY_POKEY,	2, 1, 42);
end

function removeSquads()
	--Utils:removeSquad();
end

function showParameters(selectedUnit)
	Utils:printUnitInfo(selectedUnit);
end
-- END