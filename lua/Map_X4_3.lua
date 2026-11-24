require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

GUSTAV_UNIT_ID = 0;
ENEMY_LEADER_UNIT_ID = 7;
ENEMY_SUPPLY_DEPOT_UNIT_ID = 6;
ENEMY_AIRFIELD_UNIT_ID = 5;
ENEMY_ENGINEER_BRIDGE_NORTH_UNIT_ID = 35;
ENEMY_ENGINEER_BRIDGE_CENTER_UNIT_ID = 57;
ENEMY_ENGINEER_BRIDGE_SOUTH_UNIT_ID = 65;
PLAYER_SUPPLY_DEPOT_UNIT_ID = 12;

ENEMY_ARTILLERY_HOWITZER_BRIDGE_NORTH_UNIT_ID = 36;
ENEMY_ARTILLERY_AA_BRIDGE_NORTH_UNIT_ID = 59;
ENEMY_ARTILLERY_AA_VILLAGE_NORTH_UNIT_ID = 52;
ENEMY_ARTILLERY_AA_HQ_NORTH_UNIT_ID = 18;
ENEMY_ARTILLERY_AA_HQ_SOUTH_UNIT_ID = 25;
ENEMY_ARTILLERY_AA_SUPPLY_CRATES_SOUTH_UNIT_ID = 53;
ENEMY_ARTILLERY_AA_COAST_NORTH_UNIT_ID = 77;
ENEMY_ARTILLERY_AA_COAST_SOUTH_UNIT_ID = 78;
ENEMY_TRUCK_AA_BRIDGE_SOUTH_UNIT_ID = 54;

--BRIDGE_RAILROAD_UNIT_ID = 1;
BRIDGE_CENTER_UNIT_ID = 2;
BRIDGE_SOUTH_UNIT_ID = 3;
BRIDGE_NORTH_UNIT_ID = 4;

PLANE_WAVE_SPAWN_INTERVAL = 1; --1
BRIDGES_TO_REPAIR = 3;
MAX_HP_OF_BRIDGE_UNITS = 1200;
MAX_HP_OF_GUSTAV = 1200;

-- mission stuff
missionIds = {
	DESTROY_ENEMY_LEADER = 1,
	DESTROY_GUSTAV = 2,
	DESTROY_HQ = 3,
	CAPTURE_DESTROY_AIRFIELD = 4,
	--DESTROY_RAILROAD_BRIDGE = 5,
	REPAIR_ALL_BRIDGES = 6
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.DESTROY_ENEMY_LEADER, true, Text.T_CAMP_X4_3_PRIMARY1, 100},
	{missionIds.DESTROY_GUSTAV, true, Text.T_CAMP_X4_3_PRIMARY2, 100},
	{missionIds.DESTROY_HQ, true, Text.T_CAMP_X4_3_PRIMARY3, 100},
	{missionIds.CAPTURE_DESTROY_AIRFIELD, false, Text.T_CAMP_X4_3_SECONDARY1, 50},
	--{missionIds.DESTROY_RAILROAD_BRIDGE, false, Text.T_CAMP_X4_3_SECONDARY2, 50},
	{missionIds.REPAIR_ALL_BRIDGES, false, Text.T_CAMP_X4_3_SECONDARY3, 50}
};

enemySquadIds = {
	DEFENDER_AIRFIELD_SOUTH = 1,
	DEFENDER_AIRFIELD_NORTH = 2,
	
	DEFENDER_BRIDGE_NORTH = 3,
	DEFENDER_BRIDGE_CENTER = 4,
	DEFENDER_BRIDGE_SOUTH = 5,
	DEFENDER_VILLAGE_NORTH = 6,
	DEFENDER_HQ_SOUTH = 7,
	DEFENDER_HQ_NORTH = 8,
	
	DEFENDER_SUPPLY_CRATES_SOUTH = 9,
	DEFENDER_SUPPLY_CRATES_NORTH = 10,
	DEFENDER_RAILROAD_BRIDGE = 11,
	
	MG_NEST_AIRFIELD = 21,
	MG_NEST_BRIDGE_NORTH = 22,
	MG_NEST_BRIDGE_CENTER = 23,
	MG_NEST_BRIDGE_SOUTH = 24,
	MG_NEST_SUPPLY_CRATES_SOUTH = 25,
	
	BUNKER_HQ_EAST = 26,
	BUNKER_HQ_SOUTH = 26,
	BUNKER_HQ_NORTH = 26,
	
	ARTILLERY_HOWITZER_BRIDGE_NORTH = 31,
	ARTILLERY_AA_BRIDGE_NORTH = 32,
	ARTILLERY_AA_VILLAGE_NORTH = 33,
	ARTILLERY_AA_HQ_NORTH = 34,
	ARTILLERY_AA_HQ_SOUTH = 35,
	ARTILLERY_AA_SUPPLY_CRATES_SOUTH = 36,
	TRUCK_AA_BRIDGE_SOUTH = 37,
	SNIPER_HILLS_NORTH = 38,
	ARTILLERY_AA_COAST_NORTH = 39,
	ARTILLERY_AA_COAST_SOUTH = 40,
	
	
	PLANE_WAVE_AIRFIELD_WEST = 41,
	PLANE_WAVE_AIRFIELD_EAST = 42,
	
	MINES = 50,
	
	GENERAL_KNOX = 61,
	GUSTAV = 62,
	GUSTAV_CREW = 63
};

levelPhase = {
	CAPTURE_BRIDGES = 1;
	REPAIR_BRIDGES = 2;
	DESTROY_LEADER_AND_GUSTAV = 3;
}

enemyWesternPlaneWave = {
	{Units.L_PLANE_BOMBER, 1, 15, enemySquadIds.PLANE_WAVE_AIRFIELD_WEST},
};

enemyEasternPlaneWave = {
	{Units.L_PLANE_HEAVY, 2, 16, enemySquadIds.PLANE_WAVE_AIRFIELD_EAST},
};

enemyGustavCrew = {
	{Units.L_INFANTRY_MG, 		17, 11, enemySquadIds.GUSTAV_CREW},
	{Units.L_INFANTRY_AT,		17, 11, enemySquadIds.GUSTAV_CREW},
	{Units.L_INFANTRY_FLAME,	17, 11, enemySquadIds.GUSTAV_CREW},
	{Units.L_INFANTRY_MG,		17, 11, enemySquadIds.GUSTAV_CREW},
};

waypointTablePlaneWaveWest = {{4, 11}, {10, 5}, {15, 11}, {16, 19}, {9, 18}};
waypointTablePlaneWaveEast = {{4, 11}, {10, 5}, {15, 11}, {16, 19}, {9, 18}};	--{9, 18}, {16, 19}, {15, 11}, {10, 5}, {4, 11}

engineerRailRoadTriggerFields = {{19, 11}, {22, 11}};

enemyAirfieldIsCapturedDestroyed = 0;

westernAirfieldPlaneWaveSpawnIsActive = 0;
westernAirfieldPlaneWaveIsAlive = 0;
westernAirfieldRoundOfPlaneWaveInitiation = 0;

easternAirfieldPlaneWaveSpawnIsActive = 0;
easternAirfieldPlaneWaveIsAlive = 0;
easternAirfieldRoundOfPlaneWaveInitiation = 0;

currentLevelPhase = levelPhase.CAPTURE_BRIDGES;

enemyLeaderIsDestroyed = 0;
gustavIsDestroyed = 0;
gustavIsRevealed = 0;
bridgesRepaired = 0;
enemyHqIsCapturedDestroyed = 0;
railRoadBridgeIsCapturedDestroyed = 0;

cutsceneHighlightX = -1;
cutsceneHighlightY = -1;

-- #######################################-START_GAME-#######################################

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	initWesternEnemyPlaneWaveSpawn();
	initEasternEnemyPlaneWaveSpawn();
	Unit:getUnitById(GUSTAV_UNIT_ID):setCanBeCaptured(false);
	
	ScriptManager:gainGold(PLAYER_ID, 1500);
	ScriptManager:blockGlobalAbilityButton(GlobalAbility.BLIMB);
	
	--ScriptManager:spawnUnit(PLAYER_ID, Units.SHORTSIGHTED_GOD, 1, 1, -1);
	
	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("currentLevelPhase", currentLevelPhase);
	ScriptManager:storeValue("enemyLeaderIsDestroyed", enemyLeaderIsDestroyed);
	ScriptManager:storeValue("gustavIsDestroyed", gustavIsDestroyed);
	ScriptManager:storeValue("gustavIsRevealed", gustavIsRevealed);
	ScriptManager:storeValue("bridgesRepaired", bridgesRepaired);
	ScriptManager:storeValue("enemyHqIsCapturedDestroyed", enemyHqIsCapturedDestroyed);
	ScriptManager:storeValue("railRoadBridgeIsCapturedDestroyed", railRoadBridgeIsCapturedDestroyed);
	ScriptManager:storeValue("enemyAirfieldIsCapturedDestroyed", enemyAirfieldIsCapturedDestroyed);
	
	ScriptManager:storeValue("westernAirfieldPlaneWaveSpawnIsActive", westernAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("westernAirfieldPlaneWaveIsAlive", westernAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("westernAirfieldRoundOfPlaneWaveInitiation", westernAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("easternAirfieldPlaneWaveSpawnIsActive", easternAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("easternAirfieldPlaneWaveIsAlive", easternAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("easternAirfieldRoundOfPlaneWaveInitiation", easternAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("cutsceneHighlightX", cutsceneHighlightX);
	ScriptManager:storeValue("cutsceneHighlightY", cutsceneHighlightY);
end

function loadValues()
	--[[if(Unit:getUnitById(BRIDGE_RAILROAD_UNIT_ID) ~= nil) then
		Unit:getUnitById(BRIDGE_RAILROAD_UNIT_ID):setCanBeCaptured(false);
	end--]]
	
	if(Unit:getUnitById(GUSTAV_UNIT_ID) ~= nil) then
		Unit:getUnitById(GUSTAV_UNIT_ID):setCanBeCaptured(false);
	end
	
	currentLevelPhase = ScriptManager:getValue("currentLevelPhase");
	enemyLeaderIsDestroyed = ScriptManager:getValue("enemyLeaderIsDestroyed");
	gustavIsDestroyed = ScriptManager:getValue("gustavIsDestroyed");
	gustavIsRevealed = ScriptManager:getValue("gustavIsRevealed");
	bridgesRepaired = ScriptManager:getValue("bridgesRepaired");
	enemyHqIsCapturedDestroyed = ScriptManager:getValue("enemyHqIsCapturedDestroyed");
	railRoadBridgeIsCapturedDestroyed = ScriptManager:getValue("railRoadBridgeIsCapturedDestroyed");
	enemyAirfieldIsCapturedDestroyed = ScriptManager:getValue("enemyAirfieldIsCapturedDestroyed");

	westernAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("westernAirfieldPlaneWaveSpawnIsActive");
	westernAirfieldPlaneWaveIsAlive = ScriptManager:getValue("westernAirfieldPlaneWaveIsAlive");
	westernAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("westernAirfieldRoundOfPlaneWaveInitiation");
	
	easternAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("easternAirfieldPlaneWaveSpawnIsActive");
	easternAirfieldPlaneWaveIsAlive = ScriptManager:getValue("easternAirfieldPlaneWaveIsAlive");
	easternAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("easternAirfieldRoundOfPlaneWaveInitiation");
	
	cutsceneHighlightX = ScriptManager:getValue("cutsceneHighlightX");
	cutsceneHighlightY = ScriptManager:getValue("cutsceneHighlightY");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	local triggerX, triggerY = 15, 11;
	local triggerRadius = 5;
	local northBridgeX, northBridgeY = 5, 17;
	local centerBridgeX, centerBridgeY = 10, 6;
	local southBridgeX, southBridgeY = 10, 2;
	
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false)
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.L_BUILDING_AIRFIELD, -1, "onEnemyAirfieldCaptured", "onEnemyAirfieldCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_BUILDING_AIRFIELD, -1, "onEnemyAirfieldDestroyed", "onEnemyAirfieldDestroyed");
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.L_BUILDING_HQ, -1, "onEnemyHqCaptured", "onEnemyHqCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_BUILDING_HQ, -1, "onEnemyHqDestroyed", "onEnemyHqDestroyed");
	
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, -1, -1, "onPlayerHasAttacked", "onPlayerHasAttacked");
	ScriptManager:addOnUnitSelectedTrigger(PLAYER_ID, -1, -1, "onPlayerUnitSelected", "onPlayerUnitSelected");
	ScriptManager:addOnTurnStartTrigger(PLAYER_ID, -1, -1, "onPlayerTurnStart", "onPlayerTurnStart");
	ScriptManager:addOnUnitSelectedTrigger(PLAYER_ID, Units.X_INFANTRY_ENGINEER, -1, "onPlayerEngineerSelected", "onPlayerEngineerSelected");
	
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_ARTILLERY_GUSTAF, -1, "onGustavDestroyed", "onGustavDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_TRUCK_MINOR_LEADER, -1, "onEnemyLeaderDestroyed", "onEnemyLeaderDestroyed");
	
	ScriptManager:addOnUnitOccupiedTrigger(PLAYER_ID, -1, -1, "onRubberBoatOccupied", "onRubberBoatOccupied");
	
	Utils:addOnEnterAreaTrigger(triggerX, triggerY, triggerRadius, PLAYER_ID, -1,-1, true, "onPlayerEnterEnemyHqArea", "onPlayerEnterEnemyHqArea");
	Utils:addOnEnterAreaTrigger(northBridgeX, northBridgeY, 1, PLAYER_ID, -1, -1, true, "onPlayerEnterBridgeArea", "onPlayerEnterBridgeArea");
	Utils:addOnEnterAreaTrigger(centerBridgeX, centerBridgeY, 1, PLAYER_ID, -1, -1, true, "onPlayerEnterBridgeArea", "onPlayerEnterBridgeArea");
	Utils:addOnEnterAreaTrigger(southBridgeX, southBridgeY, 1, PLAYER_ID, -1, -1, true, "onPlayerEnterBridgeArea", "onPlayerEnterBridgeArea");
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, Units.X_BUILDING_HQ, -1, "showAttackedWarning", "showAttackedWarning");
	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, -1,	"transitionToFail",	"transitionToFail");

	--ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BRIDGE_RAIL, -1, "onRailBridgeDestroyed", "onRailBridgeDestroyed");
	--ScriptManager:addOnUnitSightedTrigger(AI_ID, Units.N_BRIDGE_RAIL, -1, true, "onRailBridgeSighted", "onRailBridgeSighted");

	--ScriptManager:addOnAiCalculationTrigger(true, "checkWaypoints", "checkWaypoints");
end

function onRubberBoatOccupied(transporterUnit, transportedUnit)
	if(transporterUnit:getTemplateId() == Units.X_SHIP_RUBBERBOAT) then
		ScriptManager:removeTrigger("onRubberBoatOccupied");
		
		startDetonateBridgesCutscene();
	end
end

function onPlayerTurnStart(playerId, turnId, roundId)
	updateBridgeIsAttackable(BRIDGE_CENTER_UNIT_ID);
	updateBridgeIsAttackable(BRIDGE_NORTH_UNIT_ID);
	updateBridgeIsAttackable(BRIDGE_SOUTH_UNIT_ID);
end

function onPlayerUnitSelected(unit)
	ScriptManager:removeTrigger("onPlayerUnitSelected");
	
	startAirfieldMissionCutscene();
end

function onPlayerEngineerSelected(unit)
	local currentX, currentY = unit:getX(), unit:getY();
	
	if(currentX >= 15) and (currentY >= 5) then
		ScriptManager:disableInteractionButton(InteractionButton.REPAIR_BRIDGE);
	else
		ScriptManager:enableInteractionButton(InteractionButton.REPAIR_BRIDGE);
	end
end

function onPlayerHasAttacked(attackerUnit, isAoe, defenderUnit, defenderUnits, unitsHit)
	if(defenderUnit ~= nil) then
		if(defenderUnit:getId() == GUSTAV_UNIT_ID) then
			if(defenderUnit:getHealth() <= (MAX_HP_OF_GUSTAV * 0.3)) then
				ScriptManager:removeTrigger("onPlayerHasAttacked");
				ScriptManager:removeTrigger("onRailBridgeSighted");
				
				startGustavCrewEjectionCutscene();
			end
		end
	end
end

function onPlayerEnterEnemyHqArea(tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke)
	ScriptManager:removeTrigger("onPlayerEnterEnemyHqArea");
	
	setCutsceneHighlightX(tileX);
	setCutsceneHighlightY(tileY);
	
	startRevealCutscene();
end

function onPlayerEnterBridgeArea(tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke)
	ScriptManager:removeTrigger("onPlayerEnterBridgeArea");
	
	startDetonateBridgesCutscene();
end

function onEnemyTurnStart(playerId, turnId, roundId)
	reduceActionsOfEnemyUnits(GUSTAV_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_LEADER_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_HOWITZER_BRIDGE_NORTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_BRIDGE_NORTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_VILLAGE_NORTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_HQ_NORTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_HQ_SOUTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_SUPPLY_CRATES_SOUTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_COAST_NORTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_ARTILLERY_AA_COAST_SOUTH_UNIT_ID);
	reduceActionsOfEnemyUnits(ENEMY_TRUCK_AA_BRIDGE_SOUTH_UNIT_ID);
	
	updateBridgeIsAttackable(BRIDGE_CENTER_UNIT_ID);
	updateBridgeIsAttackable(BRIDGE_NORTH_UNIT_ID);
	updateBridgeIsAttackable(BRIDGE_SOUTH_UNIT_ID);
	
	if(getWesternAirfieldPlaneWaveSpawnIsActive() == 1) then
		if(getWesternAirfieldPlaneWaveIsAlive() == 0) then
			if(ScriptManager:getCurrentRound() == getWesternAirfieldRoundOfPlaneWaveInitiation() + PLANE_WAVE_SPAWN_INTERVAL) then
				spawnEnemyPlaneWave(enemyWesternPlaneWave);
				setWesternAirfieldPlaneWaveIsAlive(1);
				setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
			end
		end
	end
	
	if(getEasternAirfieldPlaneWaveSpawnIsActive() == 1) then
		if(getEasternAirfieldPlaneWaveIsAlive() == 0) then
			if(ScriptManager:getCurrentRound() == getEasternAirfieldRoundOfPlaneWaveInitiation() + PLANE_WAVE_SPAWN_INTERVAL) then
				spawnEnemyPlaneWave(enemyEasternPlaneWave);
				setEasternAirfieldPlaneWaveIsAlive(1);
				setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
			end
		end
	end
	
	if(ScriptManager:getSquadOrderCount(enemySquadIds.GUSTAV) <= 0) then
		local orderId = ScriptManager:addOrder(enemySquadIds.GUSTAV, 18, 11, -1, 15, AiOrder.DEFEND);
		ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_ATTACK_ALL_IN_RANGE);
	end
end

function onEnemySquadDestroyed(squadId)
	if(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_EAST) then
		setEasternAirfieldPlaneWaveIsAlive(0);
		setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	elseif(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_WEST) then
		setWesternAirfieldPlaneWaveIsAlive(0);
		setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	elseif(squadId == enemySquadIds.GUSTAV_CREW) then
		ScriptManager:removeTrigger("onGustavDestroyed");
		
		if(ScriptManager:getMissionStatus(missionIds.DESTROY_GUSTAV) == MissionStatus.IN_PROGRESS) then
			ScriptManager:setMissionStatus(missionIds.DESTROY_GUSTAV, MissionStatus.ACCOMPLISHED);
		
			checkForVictory();
		end
	end
end

function onGustavDestroyed(unit)
	ScriptManager:removeTrigger("onGustavDestroyed");
	
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_GUSTAV) == MissionStatus.IN_PROGRESS) then
		ScriptManager:setMissionStatus(missionIds.DESTROY_GUSTAV, MissionStatus.ACCOMPLISHED);
	
		checkForVictory();
	end
end

function onEnemyLeaderDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyLeaderDestroyed");
	
	ScriptManager:setMissionStatus(missionIds.DESTROY_ENEMY_LEADER, MissionStatus.ACCOMPLISHED);
	
	checkForVictory();
end

function onEnemyHqCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	
	ScriptManager:setMissionStatus(missionIds.DESTROY_HQ, MissionStatus.ACCOMPLISHED);
	
	checkForVictory();
end

function onEnemyHqDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	
	ScriptManager:setMissionStatus(missionIds.DESTROY_HQ, MissionStatus.ACCOMPLISHED);
	
	checkForVictory();
end

function onEnemyAirfieldCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyAirfieldCaptured");
	ScriptManager:removeTrigger("onEnemyAirfieldDestroyed");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_AIRFIELD, MissionStatus.ACCOMPLISHED);
	setEnemyAirfieldIsCapturedDestroyed(1);
	setWesternAirfieldPlaneWaveSpawnIsActive(0);
	setEasternAirfieldPlaneWaveSpawnIsActive(0);
	
	ScriptManager:runForPlayer(PLAYER_ID, "prepareAirfieldCapturedDestroyedCutscene");
end

function onEnemyAirfieldDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyAirfieldDestroyed");
	ScriptManager:removeTrigger("onEnemyAirfieldCaptured");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_AIRFIELD, MissionStatus.ACCOMPLISHED);
	setEnemyAirfieldIsCapturedDestroyed(1);
	setWesternAirfieldPlaneWaveSpawnIsActive(0);
	setEasternAirfieldPlaneWaveSpawnIsActive(0);
	
	ScriptManager:runForPlayer(PLAYER_ID, "prepareAirfieldCapturedDestroyedCutscene");
end

function onRailBridgeSighted(discoveringUnit, discoveredUnit)
	ScriptManager:removeTrigger("onRailBridgeSighted");
	ScriptManager:removeTrigger("onPlayerHasAttacked");
	
	if(discoveringUnit ~= nil) then
		setCutsceneHighlightX(discoveringUnit:getX());
		setCutsceneHighlightY(discoveringUnit:getY());
	end
	
	startRailRoadMissionCutscene();
end

function onRailBridgeDestroyed(unit)
	ScriptManager:removeTrigger("onRailBridgeDestroyed");
	
	ScriptManager:setMissionStatus(missionIds.DESTROY_RAILROAD_BRIDGE, MissionStatus.ACCOMPLISHED);
end

function onBridgeRepaired(repairer, bridge)	
	if(repairer ~= nil) and (bridge ~= nil) then
		if(repairer:getPlayerId() == PLAYER_ID) then
			onPlayerRepairedBridge(repairer, bridge);
		end
	end
end

function onPlayerRepairedBridge(repairer, bridge)
	local currentHealth = bridge:getHealth();
	
	if(currentHealth >= MAX_HP_OF_BRIDGE_UNITS) then
		incrementBridgeMissionProgress();
		
		ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
	end
end

function onBridgeDetonated(detonater, bridge)
	if(detonater ~= nil) then
		if(detonater:getPlayerId() == PLAYER_ID) then
			decrementBridgeMissionProgress();
		end
	end
end

function incrementBridgeMissionProgress()
	incrementBridgesRepaired();
	ScriptManager:setMissionProgress(missionIds.REPAIR_ALL_BRIDGES, getBridgesRepaired());
	
	if(getBridgesRepaired() >= BRIDGES_TO_REPAIR) then
		if(ScriptManager:getMissionStatus(missionIds.REPAIR_ALL_BRIDGES) == MissionStatus.IN_PROGRESS) then
			ScriptManager:removeTrigger("onBridgeRepaired");
			ScriptManager:removeTrigger("onBridgeDetonated");
		
			ScriptManager:setMissionStatus(missionIds.REPAIR_ALL_BRIDGES, MissionStatus.ACCOMPLISHED);
		end
	else
		if(ScriptManager:getMissionStatus(missionIds.REPAIR_ALL_BRIDGES) == MissionStatus.IN_PROGRESS) then
			ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
		end
	end
end

function decrementBridgeMissionProgress()
	decrementBridgesRepaired();
	ScriptManager:setMissionProgress(missionIds.REPAIR_ALL_BRIDGES, getBridgesRepaired());
	updateBridgeMissionProgress();
end

function updateBridgeMissionProgress()
	if(ScriptManager:getMissionStatus(missionIds.REPAIR_ALL_BRIDGES) == MissionStatus.IN_PROGRESS) then
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.REPAIR_ALL_BRIDGES), BRIDGES_TO_REPAIR, Text.T_CAMP_X4_3_SECONDARY2_COUNTER);
	end
end

function checkWaypoints(squadId, mainOrderData, allMainOrderData)
	if(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_WEST) then
		Utils:checkWaypoints(squadId, mainOrderData, allMainOrderData, waypointTablePlaneWaveWest);
	elseif(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_EAST) then
		Utils:checkWaypoints(squadId, mainOrderData, allMainOrderData, waypointTablePlaneWaveEast);
	end
end

-- #######################################-AI_ORDER-#######################################

function addAiOrders()
	local aiRadiusNormal = 2;
	local aiRadiusWide = 3;
	local aiRadiusArti = 4;
	local aiRadiusHowitzer = 6;
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_AIRFIELD_SOUTH, 2, 11, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_AIRFIELD_NORTH, 2, 18, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_NORTH, 8, 17, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_CENTER, 12, 9, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_SOUTH, 12, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_VILLAGE_NORTH, 10, 19, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_HQ_SOUTH, 15, 11, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_HQ_NORTH, 16, 13, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES_SOUTH, 18, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES_NORTH, 18, 19, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_RAILROAD_BRIDGE, 22, 11, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.MG_NEST_AIRFIELD, 1, 17, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_SUPPLY_CRATES_SOUTH, 18, 1, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.BUNKER_HQ_EAST, 13, 9, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_HQ_SOUTH, 13, 13, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_HQ_NORTH, 18, 16, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_HOWITZER_BRIDGE_NORTH, 8, 16, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_BRIDGE_NORTH, 7, 19, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_VILLAGE_NORTH, 11, 17, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_HQ_NORTH, 16, 13, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_HQ_SOUTH, 16, 9, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_SUPPLY_CRATES_SOUTH, 18, 3, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.TRUCK_AA_BRIDGE_SOUTH, 12, 7, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_HILLS_NORTH, 12, 19, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_COAST_NORTH, 8, 14, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_COAST_SOUTH, 10, 12, -1, aiRadiusArti, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.GENERAL_KNOX, 15, 13, -1, aiRadiusNormal, AiOrder.DEFEND);
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
end

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_HQ) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_LEADER) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_GUSTAV) == MissionStatus.ACCOMPLISHED) then
		
		ScriptManager:runForPlayer(PLAYER_ID, "prepareVictoryCutscene");
	end
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ);-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );-- TODO: add templateDI @end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_INTRO_FLAVOR1, 5);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(14, 11, 0.7, 2, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_INTRO_FLAVOR2, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_INTRO_FLAVOR3, 5);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_INTRO_FLAVOR4, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_INTRO_FLAVOR5, 2);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_HQ);
	startMission(missionIds.DESTROY_ENEMY_LEADER);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function prepareVictoryCutscene()
	table.insert(queueTable, startVictoryCutscene);
	Utils:cutsceneQueue();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_VICTORY_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_VICTORY_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_VICTORY_FLAVOR3, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_VICTORY_FLAVOR4, 4);

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function startAirfieldMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(2, 16, 0.7, 2, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY1_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY1_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY1_FLAVOR3, 4);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_DESTROY_AIRFIELD);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function prepareAirfieldCapturedDestroyedCutscene()
	table.insert(queueTable, playAirfieldCapturedDestroyedCutscene);
	Utils:cutsceneQueue();
end

function playAirfieldCapturedDestroyedCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(getCurrentLevelPhase() < levelPhase.REPAIR_BRIDGES) then
		local engiNorthX, engiNorthY = 7, 18;
		local engiCenterX, engiCenterY = 11, 7;
		local engiSouthX, engiSouthY = 11, 1;
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_AIRFIELD_DESTROYED_FLAVOR1, 4);
		
		ScriptManager:moveCameraEx(engiNorthX, engiNorthY, 0.7, 2, true);
		ScriptManager:revealFogOfWar(engiNorthX, engiNorthY, 1, true);
		ScriptManager:revealFogOfWar(engiCenterX, engiCenterY, 1, true);
		ScriptManager:revealFogOfWar(engiSouthX, engiSouthY, 1, true);
		ScriptManager:wait(0.75);
		enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_NORTH_UNIT_ID, BRIDGE_NORTH_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_NORTH);
		ScriptManager:moveCameraEx(engiCenterX, engiCenterY, 0.7, 2, true);
		
		ScriptManager:wait(0.75);
		enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_CENTER_UNIT_ID, BRIDGE_CENTER_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_CENTER);
		ScriptManager:moveCameraEx(engiSouthX, engiSouthY, 0.7, 2, true);
		
		ScriptManager:wait(0.75);
		enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_SOUTH_UNIT_ID, BRIDGE_SOUTH_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_SOUTH);
		
		ScriptManager:wait(0.5);
		ScriptManager:revealFogOfWar(engiNorthX, engiNorthY, 1, false);
		ScriptManager:revealFogOfWar(engiCenterX, engiCenterY, 1, false);
		ScriptManager:revealFogOfWar(engiSouthX, engiSouthY, 1, false);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR1, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR2, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR3, 4);
		
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
		
		ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_NORTH, 7, 18, -1, 3, AiOrder.DEFEND);
		ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_CENTER, 11, 7, -1, 3, AiOrder.DEFEND);
		ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_SOUTH, 11, 1, -1, 3, AiOrder.DEFEND);
	else
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_AIRFIELD_DESTROYED_FLAVOR1, 4);
	end
	
	Utils:endCutscene();
	
	if(getCurrentLevelPhase() < levelPhase.REPAIR_BRIDGES) then
		Utils:disablePlayerInteraction();
		
		ScriptManager:wait(2);
		startMission(missionIds.REPAIR_ALL_BRIDGES);
		
		Utils:enablePlayerInteraction();
		
		setUpLevelPhase(levelPhase.REPAIR_BRIDGES);
	end
end

function startRevealCutscene()
	if(getGustavIsRevealed() == 0) then
		startRevealGustavCutscene();
	else
		startRevealLeaderCutscene();
	end
end

function startRevealLeaderCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(Unit:getUnitById(ENEMY_LEADER_UNIT_ID) ~= nil) then
		local leaderX, leaderY = Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getX(), Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getY();
		
		ScriptManager:moveCameraEx(leaderX, leaderY, 0.7, 2, true);
		ScriptManager:revealFogOfWar(leaderX, leaderY, 1, true);
		ScriptManager:showMarkerAt(leaderX, leaderY);
	end
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR1, 3);
	ScriptManager:wait(0.5);
	Utils:hideAllMarkers();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR3, 3);
	
	if(Unit:getUnitById(ENEMY_LEADER_UNIT_ID) ~= nil) then
		local leaderX, leaderY = Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getX(), Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getY();
		
		ScriptManager:revealFogOfWar(leaderX, leaderY, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	end

	Utils:endCutscene();
end

function startRevealGustavCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(Unit:getUnitById(ENEMY_LEADER_UNIT_ID) ~= nil) then
		local leaderX, leaderY = Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getX(), Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getY();
		
		ScriptManager:moveCameraEx(leaderX, leaderY, 0.7, 2, true);
		ScriptManager:revealFogOfWar(leaderX, leaderY, 1, true);
		ScriptManager:showMarkerAt(leaderX, leaderY);
	end
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR1, 3);
	ScriptManager:wait(0.5);
	Utils:hideAllMarkers();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR4, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_LEADER_FLAVOR5, 3);
	
	if(Unit:getUnitById(ENEMY_LEADER_UNIT_ID) ~= nil) then
		local leaderX, leaderY = Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getX(), Unit:getUnitById(ENEMY_LEADER_UNIT_ID):getY();
		
		ScriptManager:revealFogOfWar(leaderX, leaderY, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	end
	
	if(Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()) ~= nil) then
		local currentTemplateId = Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()):getTemplateId();
		local currentId = Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()):getId();
		
		if((currentTemplateId >= Units.X_INFANTRY_MG) and
			(currentTemplateId <= Units.X_ARTILLERY_MORTAR)) or
			(currentTemplateId == Units.X_SHIP_RUBBERBOAT) then
			if(Unit:getUnitById(GUSTAV_UNIT_ID) ~= nil) then
				ScriptManager:attackUnitAOE(GUSTAV_UNIT_ID, getCutsceneHighlightX(),getCutsceneHighlightY());
				ScriptManager:wait(2.5);
				
				Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR1, 2);
				Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR2, 3);
			end
		else
			Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR9, 2);
		end
	end
	
	ScriptManager:moveCameraEx(18, 11, 0.7, 1, true);
	ScriptManager:revealFogOfWar(18, 11, 2, true);
	ScriptManager:showScaledMarkerAt(18, 11, 2);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR3, 3);
	Utils:hideAllMarkers();
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR4, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR5, 3);

	ScriptManager:revealFogOfWar(18, 11, 2, false);
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR6, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR7, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR8, 2);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_GUSTAV);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
	
	setUpLevelPhase(levelPhase.DESTROY_LEADER_AND_GUSTAV);
	setGustavIsRevealed(1);
end

function startGustavCrewEjectionCutscene()
	if(Unit:getUnitById(GUSTAV_UNIT_ID) ~= nil) then
		local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
		local currentHealthGustav = Unit:getUnitById(GUSTAV_UNIT_ID):getHealth();
	
		Utils:startCutscene();
		
		ScriptManager:moveCameraEx(18, 11, 0.7, 1.5, true);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_GUSTAV_CREW_EJECTION_FLAVOR1, 3);
		spawnEnemyGustavCrew(enemyGustavCrew);
		ScriptManager:removeTrigger("onGustavDestroyed");
		ScriptManager:removeUnitEx(GUSTAV_UNIT_ID, true);
		local currentId = ScriptManager:spawnUnit(-1, Units.X_ARTILLERY_GUSTAF, 18, 11, -1):getId();
		Unit:getUnitById(currentId):setHealth(currentHealthGustav);
		Unit:getUnitById(currentId):setCanBeCaptured(false);
		ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_ARTILLERY_GUSTAF, -1, "onGustavDestroyed", "onGustavDestroyed");
		
		ScriptManager:wait(0.5);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_GUSTAV_CREW_EJECTION_FLAVOR2, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_GUSTAV_CREW_EJECTION_FLAVOR3, 4);
		
		Utils:endCutscene();
	end
end

function startRailRoadMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(getGustavIsRevealed() == 0) then
		ScriptManager:moveCameraEx(21, 11, 0.7, 2, true);
		ScriptManager:revealFogOfWar(21, 11, 1, true);
		ScriptManager:showMarkerAt(21, 11);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY3_FLAVOR1, 3);
		Utils:hideAllMarkers();
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY3_FLAVOR2, 3);
		
		ScriptManager:wait(0.5);
		ScriptManager:revealFogOfWar(21, 11, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
		if(Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()) ~= nil) then
			local currentTemplateId = Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()):getTemplateId();
			local currentId = Unit:getUnitAt(getCutsceneHighlightX(),getCutsceneHighlightY()):getId();
		
			--[[if(currentTemplateId >= Units.X_INFANTRY_MG) and
				(currentTemplateId <= Units.X_ARTILLERY_MORTAR) then--]]
				if(Unit:getUnitById(GUSTAV_UNIT_ID) ~= nil) then
					ScriptManager:attackUnitAOE(GUSTAV_UNIT_ID, getCutsceneHighlightX(),getCutsceneHighlightY());
					ScriptManager:wait(2.5);
				end
			--end
		end
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR1, 2);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR2, 3);
		
		ScriptManager:moveCameraEx(18, 11, 0.7, 1, true);
		ScriptManager:revealFogOfWar(18, 11, 2, true);
		ScriptManager:showScaledMarkerAt(18, 11, 2);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR3, 3);
		Utils:hideAllMarkers();
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR4, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR5, 3);
		
		ScriptManager:revealFogOfWar(18, 11, 2, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);

		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR6, 6);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR7, 5);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_REVEAL_GUSTAV_FLAVOR8, 2);
	else
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_PREVENT_ESCAPE_FLAVOR1, 3);
		ScriptManager:moveCameraEx(21, 11, 0.7, 2, true);
		ScriptManager:revealFogOfWar(21, 11, 1, true);
		ScriptManager:showMarkerAt(21, 11);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_PREVENT_ESCAPE_FLAVOR2, 3);
		Utils:hideAllMarkers();

		ScriptManager:wait(0.5);
		ScriptManager:revealFogOfWar(21, 11, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	end
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	if(getGustavIsRevealed() == 0) then
		startMission(missionIds.DESTROY_GUSTAV);
		setUpLevelPhase(levelPhase.DESTROY_LEADER_AND_GUSTAV);
		setGustavIsRevealed(1);
	end
	
	startMission(missionIds.DESTROY_RAILROAD_BRIDGE);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startDetonateBridgesCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	local engiNorthX, engiNorthY = 7, 18;
	local engiCenterX, engiCenterY = 11, 7;
	local engiSouthX, engiSouthY = 11, 1;
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(engiNorthX, engiNorthY, 0.7, 2, true);
	ScriptManager:revealFogOfWar(engiNorthX, engiNorthY, 1, true);
	ScriptManager:revealFogOfWar(engiCenterX, engiCenterY, 1, true);
	ScriptManager:revealFogOfWar(engiSouthX, engiSouthY, 1, true);
	ScriptManager:wait(0.5);
	enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_NORTH_UNIT_ID, BRIDGE_NORTH_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_NORTH);
	
	ScriptManager:moveCameraEx(engiCenterX, engiCenterY, 0.7, 2, true);
	ScriptManager:wait(0.5);
	enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_CENTER_UNIT_ID, BRIDGE_CENTER_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_CENTER);
	
	ScriptManager:moveCameraEx(engiSouthX, engiSouthY, 0.7, 2, true);
	ScriptManager:wait(0.5);
	enemyEngineerDetonateBridge(ENEMY_ENGINEER_BRIDGE_SOUTH_UNIT_ID, BRIDGE_SOUTH_UNIT_ID, enemySquadIds.MG_NEST_BRIDGE_SOUTH);
	
	ScriptManager:wait(0.5);
	ScriptManager:revealFogOfWar(engiNorthX, engiNorthY, 1, false);
	ScriptManager:revealFogOfWar(engiCenterX, engiCenterY, 1, false);
	ScriptManager:revealFogOfWar(engiSouthX, engiSouthY, 1, false);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR2, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_3_SECONDARY2_FLAVOR3, 4);
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:endCutscene();
	
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.REPAIR_ALL_BRIDGES);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
	
	setUpLevelPhase(levelPhase.REPAIR_BRIDGES);
	
	ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_NORTH, 7, 18, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_CENTER, 11, 7, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_BRIDGE_SOUTH, 11, 1, -1, 3, AiOrder.DEFEND);
end

function enemyEngineerDetonateBridge(engineerId, bridgeId, mgSquadId)
	if(Unit:getUnitById(engineerId) ~= nil) then
		local engiX, engiY = Unit:getUnitById(engineerId):getX(), Unit:getUnitById(engineerId):getY();
		
		ScriptManager:detonateBridge(engineerId, bridgeId, true);
		ScriptManager:removeUnitEx(engineerId, true);
		ScriptManager:spawnUnitWithTransporter(AI_ID, Units.N_EMPLACEMENT_MG_NEST_NOTCAMOUFLAGED, Units.L_INFANTRY_MG, engiX, engiY, mgSquadId);
	end
end

-- #######################################-END_GAME-#######################################

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle(Text.T_MISSION_VICTORY);
	ScriptManager:wait( 4 );
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
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end

-- #######################################-UNITS_AND_HELPER-#######################################

function spawnEnemyPlaneWave(unitTable)
	local enemyPlaneWave = unitTable
	local aiRadiusNormal = 2;
	
	if(enemyPlaneWave ~= nil) then
		for i = 1, #enemyPlaneWave do
			if(Unit:getUnitAt(enemyPlaneWave[i][2], enemyPlaneWave[i][3]) == nil) then
				ScriptManager:spawnUnit(AI_ID, enemyPlaneWave[i][1], enemyPlaneWave[i][2], enemyPlaneWave[i][3], enemyPlaneWave[i][4]);
			end
		end
		
		local orderID = ScriptManager:addOrder(enemyPlaneWave[1][4], -1, -1, PLAYER_SUPPLY_DEPOT_UNIT_ID, aiRadiusNormal, AiOrder.ATTACK);
		ScriptManager:enableOrderFlag(orderID, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	end
end

function spawnEnemyGustavCrew(unitTable)
	local enemyGustavCrew = unitTable
	local aiRadiusNormal = 2;
	
	if(enemyGustavCrew ~= nil) then
		for i = 1, #enemyGustavCrew do
			ScriptManager:spawnUnit(AI_ID, enemyGustavCrew[i][1], enemyGustavCrew[i][2], enemyGustavCrew[i][3], enemyGustavCrew[i][4]);
		end
		
		local orderID = ScriptManager:addOrder(enemyGustavCrew[1][4], 18, 11, -1, aiRadiusNormal, AiOrder.DEFEND);
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

function reduceActionsOfEnemyUnits(unitId)
	if(Unit:getUnitById(unitId) ~= nil) then
		Unit:getUnitById(unitId):setActionPoints(0);
	end
end

function initGustav()
	local orderId = ScriptManager:addOrder(enemySquadIds.GUSTAV, 18, 11, -1, 15, AiOrder.DEFEND);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_ATTACK_ALL_IN_RANGE);
end

function deinitGustav()
	ScriptManager:removeAllOrders(enemySquadIds.GUSTAV);
end

function setUpLevelPhase(phase)
	setCurrentLevelPhase(phase)
	
	if(getCurrentLevelPhase() == levelPhase.CAPTURE_BRIDGES) then
	
	elseif(getCurrentLevelPhase() == levelPhase.REPAIR_BRIDGES) then
		ScriptManager:removeTrigger("onPlayerEnterBridgeArea");
		ScriptManager:removeTrigger("onRubberBoatOccupied");
		
		ScriptManager:addOnBridgeRepairTrigger(-1, Units.N_BRIDGE_M, -1, "onBridgeRepaired", "onBridgeRepaired");
		ScriptManager:addOnBridgeDetonateTrigger(-1, Units.N_BRIDGE_M, -1, "onBridgeDetonated", "onBridgeDetonated");
	elseif(getCurrentLevelPhase() == levelPhase.DESTROY_LEADER_AND_GUSTAV) then
		initGustav();
	end
end

function updateBridgeIsAttackable(bridgeId)
	if(Unit:getUnitById(bridgeId) ~= nil) then
		if(Unit:getUnitById(bridgeId):getPlayerId() == PLAYER_ID) then
			Unit:getUnitById(bridgeId):setIsAttackable(false);
		elseif(Unit:getUnitById(bridgeId):getPlayerId() == AI) then
			Unit:getUnitById(bridgeId):setIsAttackable(true);
		else
			Unit:getUnitById(bridgeId):setIsAttackable(false);
		end
	end
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getEnemyAirfieldIsCapturedDestroyed()
	return enemyAirfieldIsCapturedDestroyed;
end

function setEnemyAirfieldIsCapturedDestroyed(bool)
	enemyAirfieldIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyAirfieldIsCapturedDestroyed", enemyAirfieldIsCapturedDestroyed);
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

function getCurrentLevelPhase()
	return currentLevelPhase;
end

function setCurrentLevelPhase(value)
	currentLevelPhase = value;
	
	ScriptManager:storeValue("currentLevelPhase", currentLevelPhase);
end

function getEnemyLeaderIsDestroyed()
	return enemyLeaderIsDestroyed;
end

function setEnemyLeaderIsDestroyed(bool)
	enemyLeaderIsDestroyed = bool;
	
	ScriptManager:storeValue("enemyLeaderIsDestroyed", enemyLeaderIsDestroyed);
end

function getGustavIsDestroyed()
	return gustavIsDestroyed;
end

function setGustavIsDestroyed(bool)
	gustavIsDestroyed = bool;
	
	ScriptManager:storeValue("gustavIsDestroyed", gustavIsDestroyed);
end

function getGustavIsRevealed()
	return gustavIsRevealed;
end

function setGustavIsRevealed(bool)
	gustavIsRevealed = bool;
	
	ScriptManager:storeValue("gustavIsRevealed", gustavIsRevealed);
end

function getBridgesRepaired()
	return bridgesRepaired;
end

function setBridgesRepaired(bool)
	bridgesRepaired = bool;
	
	if(bridgesRepaired >= BRIDGES_TO_REPAIR) then
		bridgesRepaired = BRIDGES_TO_REPAIR;
	end
	
	ScriptManager:storeValue("bridgesRepaired", bridgesRepaired);
end

function incrementBridgesRepaired()
	setBridgesRepaired(getBridgesRepaired() + 1);
end

function decrementBridgesRepaired()
	setBridgesRepaired(getBridgesRepaired() - 1);
end

function getEnemyHqIsCapturedDestroyed()
	return enemyHqIsCapturedDestroyed;
end

function setEnemyHqIsCapturedDestroyed(bool)
	enemyHqIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyHqIsCapturedDestroyed", enemyHqIsCapturedDestroyed);
end

function getRailRoadBridgeIsCapturedDestroyed()
	return railRoadBridgeIsCapturedDestroyed;
end

function setRailRoadBridgeIsCapturedDestroyed(bool)
	railRoadBridgeIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("railRoadBridgeIsCapturedDestroyed", railRoadBridgeIsCapturedDestroyed);
end

function getCutsceneHighlightX()
	return cutsceneHighlightX;
end

function setCutsceneHighlightX(value)
	cutsceneHighlightX = value;
	
	ScriptManager:storeValue("cutsceneHighlightX", cutsceneHighlightX);
end

function getCutsceneHighlightY()
	return cutsceneHighlightY;
end

function setCutsceneHighlightY(value)
	cutsceneHighlightY = value;
	
	ScriptManager:storeValue("cutsceneHighlightY", cutsceneHighlightY);
end

-- #######################################-TESTING-#######################################

function testing()
	ScriptManager:spawnUnit(PLAYER_ID, Units.SHORTSIGHTED_GOD, 		18, 18, 42);
end

function removeSquads()
	--Utils:removeSquad( );
end

function showParameters(selectedUnit)
	Utils:printUnitInfo(selectedUnit);
end

-- END