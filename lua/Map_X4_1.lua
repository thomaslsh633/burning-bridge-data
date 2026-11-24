require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

ENEMY_SUPPLY_DEPOT_UNIT_ID = 2;
ENEMY_AIRFIELD_UNIT_ID = 3;

ENEMY_DEFENDERS_TO_DESTROY = 10;
NUMBER_OF_ENEMY_SPY_UNITS = 8;
PLANE_WAVE_SPAWN_INTERVAL = 2; --2

-- mission stuff
missionIds = {
	CAPTURE_SUPPLY_DEPOT = 1,
	CAPTURE_AIRFIELD = 2,
	DESTROY_ENEMY_DEPOT_DEFENDERS = 3,
	PREVENT_ENEMY_REPORT = 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.CAPTURE_SUPPLY_DEPOT, true, Text.T_CAMP_X4_1_PRIMARY1, 100},
	{missionIds.CAPTURE_AIRFIELD, true, Text.T_CAMP_X4_1_PRIMARY2, 100},
	{missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS, true, Text.T_CAMP_X4_1_PRIMARY3, 100},
	{missionIds.PREVENT_ENEMY_REPORT, false, Text.T_CAMP_X4_1_SECONDARY1, 50},
};

enemySquadIds = {
	-- Do NOT change these IDs! 
	DEFENDER_BRIDGE_NORTH = 1,
	DEFENDER_BRIDGE_SOUTH = 2,
	DEFENDER_ROAD_WEST = 3,
	DEFENDER_SUPPLY_CRATES_SOUTH = 4,
	DEFENDER_VILLAGE_SOUTH = 5,
	DEFENDER_AIRFIELD = 6,
	DEFENDER_ROAD_EAST = 7,
	DEFENDER_VILLAGE_NORTH = 8,
	DEFENDER_HQ = 9,
	DEFENDER_HQ_EAST = 10;
	
	
	MESSENGER_BRIDGE_NORTH = 11,
	MESSENGER_BRIDGE_SOUTH = 12,
	MESSENGER_ROAD_WEST = 13,
	MESSENGER_SUPPLY_CRATES_SOUTH = 14,
	MESSENGER_VILLAGE_SOUTH = 15,
	MESSENGER_AIRFIELD = 16,
	MESSENGER_ROAD_EAST = 17,
	MESSENGER_VILLAGE_NORTH = 18,
	
	BUNKER_TOWER_SOUTH = 20,
	MG_NEST_ROAD_SOUTH = 21,
	ARTILLERY_HOWITZER_AIRFIELD = 22,
	ARTILLERY_AA_HQ = 23,
	SNIPER_HQ = 24,
	
	PLANE_WAVE_AIRFIELD_WEST = 31;
	PLANE_WAVE_AIRFIELD_EAST = 32;
	
	ENEMY_REINFORCEMENTS_AIRFIELD = 42;
	
	MINES = 50,
};

enemyWesternPlaneWave = {
	{Units.L_PLANE_LIGHT,		20, 3, enemySquadIds.PLANE_WAVE_AIRFIELD_WEST},
};

enemyEasternPlaneWave = {
	{Units.L_PLANE_LIGHT,		21, 4, enemySquadIds.PLANE_WAVE_AIRFIELD_EAST},
};

enemyAirfieldReinforcements = {
	{Units.L_INFANTRY_AT,		25, 4, enemySquadIds.ENEMY_REINFORCEMENTS_AIRFIELD},
	{Units.L_INFANTRY_MG,		25, 4, enemySquadIds.ENEMY_REINFORCEMENTS_AIRFIELD},
	{Units.L_TRUCK_MG,			25, 4, enemySquadIds.ENEMY_REINFORCEMENTS_AIRFIELD},
	{Units.L_TANK_DESTROYER,	25, 4, enemySquadIds.ENEMY_REINFORCEMENTS_AIRFIELD}
};

waypointTablePlaneWaveWest = {{15, 7}, {9, 6}, {4, 17}, {14, 22}, {22, 12}};
waypointTablePlaneWaveEast = {{15, 7}, {9, 6}, {4, 17}, {14, 22}, {22, 12}};	--{22, 12}, {14, 22}, {4, 17}, {9, 6}, {15, 7}

enemyOnEnterTriggerFields = {
{12, 23}, 
{11, 23}, {13, 23}, {12, 24}, {13, 24}, {12, 22}, {13, 22},
--[[{10, 23}, {11, 24}, {11, 25}, {12, 25}, {13, 25}, {14, 24},
{14, 23}, {14, 22}, {13, 21}, {12, 21}, {11, 21}, {11, 22}--]]
};

enemyMessengerUnitIds = {37, 58, 64, 60, 59, 63, 61, 62};
-- 0 = not revealed, 1 = revealed, -1 = dead
enemyMessengersRevealed = {0, 0, 0, 0, 0, 0, 0, 0};

numberOfEnemyWarningCutscenesShown = 0;
enemyWarningCutsceneIsInQueue = 0;
enemyMessengerIdForWarningCutscene = -1;
enemyAirfieldIsCapturedDestroyed = 0;

westernAirfieldPlaneWaveSpawnIsActive = 0;
westernAirfieldPlaneWaveIsAlive = 0;
westernAirfieldRoundOfPlaneWaveInitiation = 0;

easternAirfieldPlaneWaveSpawnIsActive = 0;
easternAirfieldPlaneWaveIsAlive = 0;
easternAirfieldRoundOfPlaneWaveInitiation = 0;

enemyHqDefendersDestroyed = 0;
enemySpyUnitsDestroyed = 0;

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
	Utils:saveValuesIntoSavefileForExistingTable("enemyMessengersRevealed", enemyMessengersRevealed);
	
	ScriptManager:storeValue("numberOfEnemyWarningCutscenesShown", numberOfEnemyWarningCutscenesShown);
	ScriptManager:storeValue("enemyWarningCutsceneIsInQueue", enemyWarningCutsceneIsInQueue);
	ScriptManager:storeValue("enemyMessengerIdForWarningCutscene", enemyMessengerIdForWarningCutscene);
	ScriptManager:storeValue("enemyAirfieldIsCapturedDestroyed", enemyAirfieldIsCapturedDestroyed);
	
	ScriptManager:storeValue("westernAirfieldPlaneWaveSpawnIsActive", westernAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("westernAirfieldPlaneWaveIsAlive", westernAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("westernAirfieldRoundOfPlaneWaveInitiation", westernAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("easternAirfieldPlaneWaveSpawnIsActive", easternAirfieldPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("easternAirfieldPlaneWaveIsAlive", easternAirfieldPlaneWaveIsAlive);
	ScriptManager:storeValue("easternAirfieldRoundOfPlaneWaveInitiation", easternAirfieldRoundOfPlaneWaveInitiation);
	
	ScriptManager:storeValue("enemyHqDefendersDestroyed", enemyHqDefendersDestroyed);
	ScriptManager:storeValue("enemySpyUnitsDestroyed", enemySpyUnitsDestroyed);
end

function loadValues()
	enemyMessengersRevealed = Utils:loadValuesFromSavefileIntoExistingTable("enemyMessengersRevealed", enemyMessengersRevealed);

	numberOfEnemyWarningCutscenesShown = ScriptManager:getValue("numberOfEnemyWarningCutscenesShown");
	enemyWarningCutsceneIsInQueue = ScriptManager:getValue("enemyWarningCutsceneIsInQueue");
	enemyMessengerIdForWarningCutscene = ScriptManager:getValue("enemyMessengerIdForWarningCutscene");
	enemyAirfieldIsCapturedDestroyed = ScriptManager:getValue("enemyAirfieldIsCapturedDestroyed");
	
	westernAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("westernAirfieldPlaneWaveSpawnIsActive");
	westernAirfieldPlaneWaveIsAlive = ScriptManager:getValue("westernAirfieldPlaneWaveIsAlive");
	westernAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("westernAirfieldRoundOfPlaneWaveInitiation");
	
	easternAirfieldPlaneWaveSpawnIsActive = ScriptManager:getValue("easternAirfieldPlaneWaveSpawnIsActive");
	easternAirfieldPlaneWaveIsAlive = ScriptManager:getValue("easternAirfieldPlaneWaveIsAlive");
	easternAirfieldRoundOfPlaneWaveInitiation = ScriptManager:getValue("easternAirfieldRoundOfPlaneWaveInitiation");
	
	enemyHqDefendersDestroyed = ScriptManager:getValue("enemyHqDefendersDestroyed");
	enemySpyUnitsDestroyed = ScriptManager:getValue("enemySpyUnitsDestroyed");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	local triggerX, triggerY = 12, 23;
	local triggerRadius = 5;
	
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false)
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.L_BUILDING_HQ, -1, "onEnemyHqCaptured", "onEnemyHqCaptured");
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.L_BUILDING_AIRFIELD, -1, "onEnemyAirfieldCaptured", "onEnemyAirfieldCaptured");
	ScriptManager:addOnUnitSelectedTrigger(PLAYER_ID, -1, -1, "onPlayerUnitSelected", "onPlayerUnitSelected");
	
	ScriptManager:addOnUnitMovedTrigger(AI_ID, Units.L_INFANTRY_SPY, -1, "onEnemySpyUnitMoved", "onEnemySpyUnitMoved");
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, -1, -1, "onEnemyUnitDestroyed", "onEnemyUnitDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_INFANTRY_SPY, -1, "onEnemySpyUnitDestroyed", "onEnemySpyUnitDestroyed");
	ScriptManager:addOnUnitSightedTrigger(AI_ID, Units.L_INFANTRY_SPY, -1, true, "onEnemySpyUnitSighted", "onEnemySpyUnitSighted");
	
	ScriptManager:addOnUnitHasAttackedTrigger(-1, -1, -1, "onUnitAttacked", "onUnitAttacked");
	ScriptManager:addOnTurnStartTrigger(-1, -1, -1, "onTurnStart", "onTurnStart");
	
	Utils:addOnEnterAreaTrigger(triggerX, triggerY, triggerRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterArea", "onPlayerEnterArea");

	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, Units.X_BUILDING_HQ, -1, "showAttackedWarning", "showAttackedWarning");
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, Units.L_BUILDING_HQ, -1, "stopAttackingHint", "stopAttackingHint");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_BUILDING_HQ, -1,	"transitionToFail",	"transitionToFail");
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, Units.L_BUILDING_AIRFIELD, -1, "stopAttackingAirfieldHint", "stopAttackingAirfieldHint");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_BUILDING_AIRFIELD, -1,	"transitionToFail",	"transitionToFail");
	
	ScriptManager:addOnAiCalculationTrigger(true, "checkWaypoints", "checkWaypoints");
end

function onTurnStart(playerId, turnId, roundId)
	setEnemyWarningCutsceneIsInQueue(0);
end

function onPlayerEnterArea()
	ScriptManager:removeTrigger("onPlayerEnterArea");
	
	startEnemySupplyDepotDiscovoredCutscene();
	
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_AIRFIELD) ~= MissionStatus.ACCOMPLISHED) then
		spawnEnemyReinforcements();
	end
end

function onPlayerUnitSelected(unit)
	ScriptManager:removeTrigger("onPlayerUnitSelected");
	
	startAirfieldMissionCutscene();
end

function onEnemySquadDestroyed(squadId)
	if(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_EAST) then
		setEasternAirfieldPlaneWaveIsAlive(0);
		setEasternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	elseif(squadId == enemySquadIds.PLANE_WAVE_AIRFIELD_WEST) then
		setWesternAirfieldPlaneWaveIsAlive(0);
		setWesternAirfieldRoundOfPlaneWaveInitiation(ScriptManager:getCurrentRound());
	end
end

function onUnitAttacked(attackerUnit, isAoe, defenderUnit, defenderUnits, unitsHit)
	local aiTargetRadius = 1;
	
	if(attackerUnit ~= nil) then
		if(attackerUnit:getSquadId() >= enemySquadIds.DEFENDER_BRIDGE_NORTH) and
			(attackerUnit:getSquadId() <= enemySquadIds.DEFENDER_VILLAGE_NORTH) then
			if (ScriptManager:getSquadOrderCount(attackerUnit:getSquadId() + 10) > 0) then
				ScriptManager:removeAllOrders(attackerUnit:getSquadId() + 10);
			end
			
			local currentOrder = ScriptManager:addOrder(attackerUnit:getSquadId() + 10, 12, 23, -1, aiTargetRadius, AiOrder.MOVE);
			ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
			
			if(Unit:getUnitById(enemyMessengerUnitIds[attackerUnit:getSquadId()]) ~= nil) then
				addEnemyMessengerCutsceneToQueue(enemyMessengerUnitIds[attackerUnit:getSquadId()], Unit:getUnitById(enemyMessengerUnitIds[attackerUnit:getSquadId()]):getSquadId());
			end
		end
	end
	
	if(defenderUnit ~= nil) then
		if(defenderUnit:getSquadId() >= enemySquadIds.DEFENDER_BRIDGE_NORTH) and
			(defenderUnit:getSquadId() <= enemySquadIds.DEFENDER_VILLAGE_NORTH) then
			if (ScriptManager:getSquadOrderCount(defenderUnit:getSquadId() + 10) > 0) then
				ScriptManager:removeAllOrders(defenderUnit:getSquadId() + 10);
			end
			
			local currentOrder = ScriptManager:addOrder(defenderUnit:getSquadId() + 10, 12, 23, -1, aiTargetRadius, AiOrder.MOVE);
			ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
			
			if(Unit:getUnitById(enemyMessengerUnitIds[defenderUnit:getSquadId()]) ~= nil) then
				addEnemyMessengerCutsceneToQueue(enemyMessengerUnitIds[defenderUnit:getSquadId()], Unit:getUnitById(enemyMessengerUnitIds[defenderUnit:getSquadId()]):getSquadId());
			end
		elseif(defenderUnit:getSquadId() >= enemySquadIds.MESSENGER_BRIDGE_NORTH) and
			(defenderUnit:getSquadId() <= enemySquadIds.MESSENGER_VILLAGE_NORTH) then
			if (ScriptManager:getSquadOrderCount(defenderUnit:getSquadId()) == 0) then
				ScriptManager:removeAllOrders(defenderUnit:getSquadId());
			end
			
			local currentOrder = ScriptManager:addOrder(defenderUnit:getSquadId(), 12, 23, -1, aiTargetRadius, AiOrder.MOVE);
			ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
			
			addEnemyMessengerCutsceneToQueue(defenderUnit:getId(), defenderUnit:getSquadId());
		end
	end
end

function addEnemyMessengerCutsceneToQueue(messengerUnitId, messengerSquadId)
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.NOT_STARTED) or
		(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.IN_PROGRESS) then
		if(checkForEnemyMessengerStatus(messengerSquadId - 10) == 0) then
			setEnemyWarningCutsceneIsInQueue(1);
			setEnemyMessengerIdForWarningCutscene(messengerUnitId);
			enemyMessengersRevealed[messengerSquadId - 10] = 1;
			Utils:saveValuesIntoSavefileForExistingTable("enemyMessengersRevealed", enemyMessengersRevealed);
			
			ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemyMessengerWarningCutscene");
			incrementNumberOfEnemyWarningCutscenesShown();
		end
	end
end

function checkForEnemyMessengerStatus(messenger)
	return enemyMessengersRevealed[messenger];
end

function onEnemySpyUnitMoved(unit)
	local currentX, currentY = unit:getX(), unit:getY();
	for i = 1, #enemyOnEnterTriggerFields do
		if(enemyOnEnterTriggerFields[i][1] == currentX) and (enemyOnEnterTriggerFields[i][2] == currentY) then
			if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.IN_PROGRESS) then
				ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_REPORT, MissionStatus.FAILED);
				
				ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemyReportingCutscene");
			else
				despawnEnemySpyUnitAroundSupplyDepot();
				despawnEnemySpyUnits();
			end
		end
	end
end

function onEnemyHqCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	ScriptManager:removeTrigger("onUnitAttacked");
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	ScriptManager:removeTrigger("onEnemySpyUnitDestroyed");
	
	removeEnemySpyUnitOrders();
	despawnEnemySpyUnits();
	ScriptManager:setMissionStatus(missionIds.CAPTURE_SUPPLY_DEPOT, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.IN_PROGRESS) or
		(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.NOT_STARTED)then
		ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_REPORT, MissionStatus.ACCOMPLISHED);
	end
	
	checkForVictory();
end

function onEnemyAirfieldCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyAirfieldCaptured");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_AIRFIELD, MissionStatus.ACCOMPLISHED);
	setEnemyAirfieldIsCapturedDestroyed(1);
	setWesternAirfieldPlaneWaveSpawnIsActive(0);
	setEasternAirfieldPlaneWaveSpawnIsActive(0);
	
	checkForVictory();
end

function onEnemyUnitDestroyed(unit)
	if(unit:getSquadId() == enemySquadIds.DEFENDER_HQ) or
		(unit:getSquadId() == enemySquadIds.DEFENDER_HQ_EAST) or
		(unit:getSquadId() == enemySquadIds.ARTILLERY_AA_HQ) or
		(unit:getSquadId() == enemySquadIds.SNIPER_HQ) then
		incrementEnemyHqDefendersDestroyed();
		ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS, getEnemyHqDefendersDestroyed());
		
		if(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS) == MissionStatus.IN_PROGRESS) then
			if(getEnemyHqDefendersDestroyed() >= ENEMY_DEFENDERS_TO_DESTROY) then
				ScriptManager:removeTrigger("onEnemyUnitDestroyed");
				
				ScriptManager:setMissionStatus(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS, MissionStatus.ACCOMPLISHED);
				checkForVictory();
			else
				ScriptManager:runForPlayer(PLAYER_ID, "updateDestroyHqDefendersMissionProgress");
			end
		end
	end
end

function updateDestroyHqDefendersMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS), ENEMY_DEFENDERS_TO_DESTROY, Text.T_CAMP_X4_1_PRIMARY3_COUNTER);
end

function onEnemySpyUnitDestroyed(unit)
	incrementEnemySpyUnitsDestroyed();
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.IN_PROGRESS) then
		if(getEnemySpyUnitsDestroyed() >= NUMBER_OF_ENEMY_SPY_UNITS) then
			ScriptManager:removeTrigger("onEnemySpyUnitDestroyed");
		
			ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_REPORT, MissionStatus.ACCOMPLISHED);
		end
		
		startEnemySpyDestroyedCutscene();
	end
end

function onEnemySpyUnitSighted(discoveringUnit, discoveredUnit)
	local aiTargetRadius = 1;
	
	if(discoveredUnit ~= nil) then
		if (ScriptManager:getSquadOrderCount(discoveredUnit:getSquadId()) > 0) then
			ScriptManager:removeAllOrders(discoveredUnit:getSquadId());
		end
		
		local currentOrder = ScriptManager:addOrder(discoveredUnit:getSquadId(), 12, 23, -1, aiTargetRadius, AiOrder.MOVE);
		ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
		
		addEnemyMessengerCutsceneToQueue(discoveredUnit:getId(), discoveredUnit:getSquadId());
	end
end

function onEnemyTurnStart(playerId, turnId, roundId)
	reduceActionPointsOfEnemySpyUnits();
	
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
end

function reduceActionPointsOfEnemySpyUnits()
	local speedFactor = 0.5; --0.75
	
	for i = 1, #enemyMessengerUnitIds do
		if(Unit:getUnitById(enemyMessengerUnitIds[i]) ~= nil) then
			Unit:getUnitById(enemyMessengerUnitIds[i]):setActionPoints(Unit:getUnitById(enemyMessengerUnitIds[i]):getActionPoints() * speedFactor);
		end
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
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_NORTH, 4, 12, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_SOUTH, 8, 5, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_ROAD_WEST, 7, 18, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES_SOUTH, 14, 12, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_VILLAGE_SOUTH, 14, 7, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_AIRFIELD, 21, 4, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_ROAD_EAST, 18, 16, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_VILLAGE_NORTH, 24, 16, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_HQ, 11, 22, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_HQ_EAST, 14, 22, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.BUNKER_TOWER_SOUTH, 2, 12, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_ROAD_SOUTH, 14, 5, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_HOWITZER_AIRFIELD, 21, 3, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AA_HQ, 13, 23, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_HQ, 13, 20, -1, aiRadiusArti, AiOrder.DEFEND);
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
	
	if(missionId == missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS) then
		ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS, getEnemyHqDefendersDestroyed());
	end
end

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_SUPPLY_DEPOT) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_AIRFIELD) == MissionStatus.ACCOMPLISHED) then
		startVictoryCutscene();
	end
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ);-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.L_BUILDING_HQ);-- TODO: add templateDI @end
end

function stopAttackingAirfieldHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.L_BUILDING_AIRFIELD);-- TODO: add templateDI @end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_INTRO_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_INTRO_FLAVOR2, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_INTRO_FLAVOR3, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_INTRO_FLAVOR4, 5);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(12, 23, 0.7, 3, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY1_FLAVOR1, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY1_FLAVOR2, 5);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_SUPPLY_DEPOT);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_VICTORY_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_VICTORY_FLAVOR2, 3);

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function startAirfieldMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(21, 2, 0.7, 3, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY2_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY2_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY2_FLAVOR3, 6);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	
	Utils:endCutscene();
	
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_AIRFIELD);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startEnemySupplyDepotDiscovoredCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(12, 23, 0.7, 2, true);
	ScriptManager:revealFogOfWar(12, 23, 1, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY3_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY3_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_PRIMARY3_FLAVOR3, 3);
	
	ScriptManager:revealFogOfWar(12, 23, 1, false);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_ENEMY_DEPOT_DEFENDERS);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startEnemySpyDestroyedCutscene()
	if(getEnemySpyUnitsDestroyed() >= NUMBER_OF_ENEMY_SPY_UNITS) then
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_DESTROYED_FLAVOR1, 3);
		
		Utils:endCutscene();
	elseif(getEnemySpyUnitsDestroyed() <= 1) then
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_DESTROYED_FLAVOR2, 3);
		
		Utils:endCutscene();
	end
end

function prepareEnemyMessengerWarningCutscene()
	table.insert(queueTable, playEnemyMessengerWarningCutscene);
	Utils:cutsceneQueue();
end

function playEnemyMessengerWarningCutscene()
	local currentX = ScriptManager:getCurrentCameraPositionX();
	local currentY = ScriptManager:getCurrentCameraPositionY();
	
	if(Unit:getUnitById(getEnemyMessengerIdForWarningCutscene()) ~= nil) then
		local messengerX = Unit:getUnitById(getEnemyMessengerIdForWarningCutscene()):getX();
		local messengerY = Unit:getUnitById(getEnemyMessengerIdForWarningCutscene()):getY();
		
		Utils:startCutscene();
		
		ScriptManager:revealFogOfWar(messengerX, messengerY, 1, true);
		ScriptManager:moveCameraEx(messengerX, messengerY, 0.7, 1, true);
		ScriptManager:showMarkerAt(messengerX, messengerY);
		
		if(getNumberOfEnemyWarningCutscenesShown() <= 1) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_WARNING_FLAVOR1, 4);
			Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_WARNING_FLAVOR2, 2);
		else
			Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_WARNING_FLAVOR3, 2);
		end
		
		ScriptManager:removeAllMarkers();
		ScriptManager:revealFogOfWar(messengerX, messengerY, 1, false);
		ScriptManager:wait(0.5);
		
		ScriptManager:moveCameraEx(currentX, currentY, 0.7, 1, true);
		
		Utils:endCutscene();
		
		if(getNumberOfEnemyWarningCutscenesShown() <= 1) then
			if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_REPORT) == MissionStatus.NOT_STARTED) then
				Utils:disablePlayerInteraction();
		
				startMission(missionIds.PREVENT_ENEMY_REPORT);
				
				ScriptManager:wait(2);
				
				Utils:enablePlayerInteraction();
			end
		end
	end
end

function prepareEnemyReportingCutscene()
	table.insert(queueTable, playEnemyReportingCutscene);
	Utils:cutsceneQueue();
end

function playEnemyReportingCutscene()
	local currentX, currentY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:revealFogOfWar(12, 23, 1, true);
	ScriptManager:moveCameraEx(12, 23, 0.7, 2, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_REPORTING_FLAVOR1, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_1_ENEMY_MESSENGER_REPORTING_FLAVOR2, 5);
	
	ScriptManager:revealFogOfWar(12, 23, 1, false);
	ScriptManager:moveCameraEx(currentX, currentY, 0.7, 2, true);
	
	despawnEnemySpyUnitAroundSupplyDepot();
	
	Utils:endCutscene();
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
		
		local orderID = ScriptManager:addOrder(enemyPlaneWave[1][4], -1, -1, -1, aiRadiusNormal, AiOrder.ATTACK);
		ScriptManager:enableOrderFlag(orderID, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
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

function despawnEnemySpyUnitAroundSupplyDepot()
	local thresholdFactor = 1;
	local originTileX, originTileY = Unit:getUnitById(ENEMY_SUPPLY_DEPOT_UNIT_ID):getX(), Unit:getUnitById(ENEMY_SUPPLY_DEPOT_UNIT_ID):getY();
	
	if(originTileY % 2 == 0) then
		thresholdFactor = thresholdFactor * (-1);
	end
	
	for i = -1, 1 do --y
		for j = -1, 1 do --x
			if((j == -1 * thresholdFactor) and (i == 1 * thresholdFactor)) or
				((j == -1 * thresholdFactor) and (i == -1 * thresholdFactor)) or
				((j == 0) and (i == 0)) then
				--placeholder for a continue statement (which does not exist in lua...)
			else
				if(Unit:getUnitAt(originTileX + j, originTileY + i) ~= nil) then
					if(Unit:getUnitAt(originTileX + j, originTileY + i):getTemplateId() == Units.L_INFANTRY_SPY) then
						ScriptManager:removeUnitEx(Unit:getUnitAt(originTileX + j, originTileY + i):getId(), true);
					end
				end
			end
		end
	end
end

function despawnEnemySpyUnits()
	for i = 1, #enemyMessengerUnitIds do
		if(Unit:getUnitById(enemyMessengerUnitIds[i]) ~= nil) then
			ScriptManager:removeUnitEx(enemyMessengerUnitIds[i], true);
		end
	end
end

function removeEnemySpyUnitOrders()
	for i = enemySquadIds.MESSENGER_BRIDGE_NORTH, enemySquadIds.MESSENGER_VILLAGE_NORTH do
		ScriptManager:removeAllOrders(i);
	end
end

function spawnEnemyReinforcements()
	for i = 1, #enemyAirfieldReinforcements do
		ScriptManager:spawnUnit(AI_ID, enemyAirfieldReinforcements[i][1], enemyAirfieldReinforcements[i][2], enemyAirfieldReinforcements[i][3], enemyAirfieldReinforcements[i][4]);
	end
	
	ScriptManager:addOrder(enemySquadIds.ENEMY_REINFORCEMENTS_AIRFIELD, 12, 2, -1, 2, AiOrder.DEFEND);
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getEnemyWarningCutsceneIsInQueue()
	return enemyWarningCutsceneIsInQueue;
end

function setEnemyWarningCutsceneIsInQueue(bool)
	enemyWarningCutsceneIsInQueue = bool;
	
	ScriptManager:storeValue("enemyWarningCutsceneIsInQueue", enemyWarningCutsceneIsInQueue);
end

function getEnemyMessengerIdForWarningCutscene()
	return enemyMessengerIdForWarningCutscene;
end

function setEnemyMessengerIdForWarningCutscene(value)
	enemyMessengerIdForWarningCutscene = value;
	
	ScriptManager:storeValue("enemyMessengerIdForWarningCutscene", enemyMessengerIdForWarningCutscene);
end

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

function getNumberOfEnemyWarningCutscenesShown()
	return numberOfEnemyWarningCutscenesShown;
end

function setNumberOfEnemyWarningCutscenesShown(value)
	numberOfEnemyWarningCutscenesShown = value;
	
	ScriptManager:storeValue("numberOfEnemyWarningCutscenesShown", numberOfEnemyWarningCutscenesShown);
end

function incrementNumberOfEnemyWarningCutscenesShown()
	setNumberOfEnemyWarningCutscenesShown(getNumberOfEnemyWarningCutscenesShown() + 1);
end

function getEnemyHqDefendersDestroyed()
	return enemyHqDefendersDestroyed;
end

function setEnemyHqDefendersDestroyed(value)
	enemyHqDefendersDestroyed = value;
	
	if(enemyHqDefendersDestroyed >= ENEMY_DEFENDERS_TO_DESTROY) then
		enemyHqDefendersDestroyed = ENEMY_DEFENDERS_TO_DESTROY;
	end
	
	ScriptManager:storeValue("enemyHqDefendersDestroyed", enemyHqDefendersDestroyed);
end

function incrementEnemyHqDefendersDestroyed()
	setEnemyHqDefendersDestroyed(getEnemyHqDefendersDestroyed() + 1);
end

function getEnemySpyUnitsDestroyed()
	return enemySpyUnitsDestroyed;
end

function setEnemySpyUnitsDestroyed(value)
	enemySpyUnitsDestroyed = value;
	
	if(enemySpyUnitsDestroyed >= NUMBER_OF_ENEMY_SPY_UNITS) then
		enemySpyUnitsDestroyed = NUMBER_OF_ENEMY_SPY_UNITS;
	end
	
	ScriptManager:storeValue("enemySpyUnitsDestroyed", enemySpyUnitsDestroyed);
end

function incrementEnemySpyUnitsDestroyed()
	setEnemySpyUnitsDestroyed(getEnemySpyUnitsDestroyed() + 1);
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