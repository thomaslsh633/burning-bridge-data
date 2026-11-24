require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

ENEMY_HQ_UNIT_ID = 0;
ENEMY_TANK_FACTORY_UNIT_ID = 1;

CENTER_BRIDGE_UNIT_ID = 2;
NORTHERN_BRIDGE_UNIT_ID = 3;

ENEMY_MORTAR_ONE_UNIT_ID = 9;
ENEMY_MORTAR_TWO_UNIT_ID = 12;
ENEMY_MORTAR_THREE_UNIT_ID = 13;
ENEMY_MORTAR_FOUR_UNIT_ID = 14;
ENEMY_MORTAR_FIVE_UNIT_ID = 15;

ENEMY_HOWITZER_CENTER_UNIT_ID = 59;
ENEMY_HOWITZER_NORTH_UNIT_ID = 60;

ENEMY_MORTARS_TO_DESTROY = 5;
BRIDGES_TO_DESTROY = 2;
MAX_HP_OF_BRIDGE_UNITS = 1200;

ROUND_OF_BRIDGE_MISSION_START = 1;
ROUND_OF_ENEMY_SUPPLY_TRUCK_SPAWN = 6; --6
ROUNDS_BETWEEN_SUPPLY_TRUCK_SPAWN = 1;
ROUNDS_BETWEEN_BRIDGE_DEFENDER_SPAWN = 3;
MAX_NUMBER_OF_ENEMY_SUPPLY_TRUCK_SPAWNS = 5;
MAX_NUMBER_OF_ENEMY_SAPPER_SPAWNS = 3;

-- mission stuff
missionIds = {
	CAPTURE_DESTROY_ENEMY_HQ = 1,
	CAPTURE_DESTROY_TANK_FACTORY = 2,
	DESTROY_ENEMY_MORTARS = 3,
	DETONATE_BRIDGES = 4,
	PREVENT_ENEMY_EXCHANGE = 5
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.CAPTURE_DESTROY_ENEMY_HQ, true, Text.T_CAMP_L_4_3_PRIMARY1, 100},
	{missionIds.CAPTURE_DESTROY_TANK_FACTORY, true, Text.T_CAMP_L_4_3_PRIMARY2, 100},
	{missionIds.DESTROY_ENEMY_MORTARS, false, Text.T_CAMP_L_4_3_SECONDARY2, 50},
	{missionIds.DETONATE_BRIDGES, false, Text.T_CAMP_L_4_3_SECONDARY1, 50},
	{missionIds.PREVENT_ENEMY_EXCHANGE, false, Text.T_CAMP_L_4_3_SECONDARY3, 50}
};

enemySquadIds = {
	DEFENDER_HQ = 1,
	DEFENDER_TF = 2,
	
	DEFENDER_SUPPLY_CRATES_SOUTH = 3,
	ROAD_BLOCK_SOUTH = 4,
	ROAD_BLOCK_CENTER = 5,
	ROAD_BLOCK_NORTH = 6,
	VILLAGE_NORTH = 7,
	
	DEFENDER_BRIDGE_SOUTH = 8,
	DEFENDER_BRIDGE_CENTER = 9,
	DEFENDER_BRIDGE_NORTH = 10,
	DEFENDER_SUPPLY_CRATES_RIVER = 11,
	
	SNIPER_SNOW_MOUNTAIN = 15,
	SNIPER_PLATEAU = 16,
	
	ARTILLERY_HOWITZER_CENTER = 20,
	ARTILLERY_HOWITZER_NORTH = 21,
	
	MG_NEST_ROAD_SOUTH = 25,
	MG_NEST_ROAD_CENTER = 26,
	MG_NEST_ROAD_NORTH = 27,
	
	BUNKER_SOUTH_ONE = 30,
	BUNKER_SOUTH_TWO = 31,
	BUNKER_CENTER_ONE = 32,
	BUNKER_CENTER_TWO = 33,
	BUNKER_NORTH_ONE = 34,
	BUNKER_NORTH_TWO = 35,
	BUNKER_NORTH_THREE = 36,
	
	SUPPLY_TRUCK_WAVE = 40,
	BRIDGE_SUPPORT_SAPPER = 41,
	BRIDGE_SUPPORT_DEFENDER = 42,
	
	MINES = 50,
};

enemyMortarUnitSquad = {
	{ENEMY_MORTAR_ONE_UNIT_ID, 		6, 16},
	{ENEMY_MORTAR_TWO_UNIT_ID, 		9, 23},
	{ENEMY_MORTAR_THREE_UNIT_ID, 	12, 20},
	{ENEMY_MORTAR_FOUR_UNIT_ID, 	12, 30},
	{ENEMY_MORTAR_FIVE_UNIT_ID, 	15, 27}
};

enemyBridgeSupportSquad = {
	{Units.X_INFANTRY_ENGINEER, 	21, 12, 0, 0, enemySquadIds.BRIDGE_SUPPORT_SAPPER},
	{Units.X_TANK_MEDIUM, 			20, 15, 0, 0, enemySquadIds.BRIDGE_SUPPORT_DEFENDER},
	{Units.X_TANK_MEDIUM, 			20, 15, 0, 0, enemySquadIds.BRIDGE_SUPPORT_DEFENDER},
	{Units.X_TANK_MEDIUM, 			20, 15, 0, 0, enemySquadIds.BRIDGE_SUPPORT_DEFENDER}
}

enemyReinforcementTankPattern = {
	Units.X_TANK_MEDIUM, Units.X_TANK_MEDIUM, Units.X_TANK_DESTROYER, Units.X_TANK_HEAVY, Units.X_TANK_MEDIUM
};

enemySupplyTruckOrderFields = {
	northernBridge = {20, 26, 22, 22},
	centerBridge = {14, 16, 18, 16},
	southernBridge = {12, 7, 17, 7}
};

enemyReinforcementTriggerFields = {{20, 11}, {21, 11}, {20, 12}, {22, 12}, {20, 13}, {21, 13}};
enemyBridgeSupportSapperTriggerFields = {{18, 16}, {17, 15}, {22, 22}, {22, 23}};

enemyHqIsCapturedDestroyed = 0;
enemyTankFactoryIsCapturedDestroyed = 0;
enemyMortarsDestroyed = 0;
bridgesDestroyed = 0;
northernBridgeIsDestroyed = 0;
centerBridgeIsDestroyed = 0;
playerHasBridges = 0;

enemySupplyTruckUnitId = -1;
enemySupplyTruckIsActive = 0;
enemySupplyTruckIsOnSavePath = 0;
enemySupplyTrucksSpawned = 0;

enemyTankWaveInitSquadId = 100;

enemyBridgeSupportSapperUnitId = -1;
enemyBridgeSupportSapperIsActive = 0;
enemyBridgeSupportSapperIsInRange = 0;
enemyBridgeSupportSapperFinishedRepair = 0;
numberOfEnemySapperSpawns = 0;

enemyBridgeSupportDefenderSquadIsActive = 0;
enemyBridgeSupportDefenderSquadIsDefending = 0;

roundOfReinforcementSpawnInit = -1;
roundOfEnemyBridgeSupportDefenderSquadSpawnInit = -1;

cutsceneForEnemySupplyTruckAppearanceShown = 0;
cutsceneForEnemySapperRepairBridgeShown = 0;

-- #######################################-START_GAME-#######################################

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	setUpTriggersForBridges();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold(PLAYER_ID, 1500);
	ScriptManager:blockGlobalAbilityButton(GlobalAbility.BLIMB);
	--ScriptManager:fortifyUnit(33, true);
	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("enemyHqIsCapturedDestroyed", enemyHqIsCapturedDestroyed);
	ScriptManager:storeValue("enemyTankFactoryIsCapturedDestroyed", enemyTankFactoryIsCapturedDestroyed);
	ScriptManager:storeValue("enemyMortarsDestroyed", enemyMortarsDestroyed);
	ScriptManager:storeValue("bridgesDestroyed", bridgesDestroyed);
	ScriptManager:storeValue("northernBridgeIsDestroyed", northernBridgeIsDestroyed);
	ScriptManager:storeValue("centerBridgeIsDestroyed", centerBridgeIsDestroyed)
	ScriptManager:storeValue("playerHasBridges", playerHasBridges);

	ScriptManager:storeValue("enemySupplyTruckUnitId", enemySupplyTruckUnitId);
	ScriptManager:storeValue("enemySupplyTruckIsActive", enemySupplyTruckIsActive);
	ScriptManager:storeValue("enemySupplyTruckIsOnSavePath", enemySupplyTruckIsOnSavePath);
	ScriptManager:storeValue("enemySupplyTrucksSpawned", enemySupplyTrucksSpawned);
	
	ScriptManager:storeValue("enemyTankWaveInitSquadId", enemyTankWaveInitSquadId);
	
	ScriptManager:storeValue("enemyBridgeSupportSapperUnitId", enemyBridgeSupportSapperUnitId);
	ScriptManager:storeValue("enemyBridgeSupportSapperIsActive", enemyBridgeSupportSapperIsActive);
	ScriptManager:storeValue("enemyBridgeSupportSapperIsInRange", enemyBridgeSupportSapperIsInRange);
	ScriptManager:storeValue("enemyBridgeSupportSapperFinishedRepair", enemyBridgeSupportSapperFinishedRepair);
	ScriptManager:storeValue("numberOfEnemySapperSpawns", numberOfEnemySapperSpawns);
	
	ScriptManager:storeValue("enemyBridgeSupportDefenderSquadIsActive", enemyBridgeSupportDefenderSquadIsActive);
	ScriptManager:storeValue("enemyBridgeSupportDefenderSquadIsDefending", enemyBridgeSupportDefenderSquadIsDefending);
	
	ScriptManager:storeValue("roundOfReinforcementSpawnInit", roundOfReinforcementSpawnInit);
	ScriptManager:storeValue("roundOfEnemyBridgeSupportDefenderSquadSpawnInit", roundOfEnemyBridgeSupportDefenderSquadSpawnInit);
	ScriptManager:storeValue("cutsceneForEnemySupplyTruckAppearanceShown", cutsceneForEnemySupplyTruckAppearanceShown);
	ScriptManager:storeValue("cutsceneForEnemySapperRepairBridgeShown", cutsceneForEnemySapperRepairBridgeShown);
end

function loadValues()
	enemyHqIsCapturedDestroyed = ScriptManager:getValue("enemyHqIsCapturedDestroyed");
	enemyTankFactoryIsCapturedDestroyed = ScriptManager:getValue("enemyTankFactoryIsCapturedDestroyed");
	enemyMortarsDestroyed = ScriptManager:getValue("enemyMortarsDestroyed");
	bridgesDestroyed = ScriptManager:getValue("bridgesDestroyed");
	northernBridgeIsDestroyed = ScriptManager:getValue("northernBridgeIsDestroyed");
	centerBridgeIsDestroyed = ScriptManager:getValue("centerBridgeIsDestroyed");
	playerHasBridges = ScriptManager:getValue("playerHasBridges");
	
	enemySupplyTruckUnitId = ScriptManager:getValue("enemySupplyTruckUnitId");
	enemySupplyTruckIsActive = ScriptManager:getValue("enemySupplyTruckIsActive");
	enemySupplyTruckIsOnSavePath = ScriptManager:getValue("enemySupplyTruckIsOnSavePath");
	enemySupplyTrucksSpawned = ScriptManager:getValue("enemySupplyTrucksSpawned");
	
	enemyTankWaveInitSquadId = ScriptManager:getValue("enemyTankWaveInitSquadId");
	
	enemyBridgeSupportSapperUnitId = ScriptManager:getValue("enemyBridgeSupportSapperUnitId");
	enemyBridgeSupportSapperIsActive = ScriptManager:getValue("enemyBridgeSupportSapperIsActive");
	enemyBridgeSupportSapperIsInRange = ScriptManager:getValue("enemyBridgeSupportSapperIsInRange");
	enemyBridgeSupportSapperFinishedRepair = ScriptManager:getValue("enemyBridgeSupportSapperFinishedRepair");
	numberOfEnemySapperSpawns = ScriptManager:getValue("numberOfEnemySapperSpawns");
	
	enemyBridgeSupportDefenderSquadIsActive = ScriptManager:getValue("enemyBridgeSupportDefenderSquadIsActive");
	enemyBridgeSupportDefenderSquadIsDefending = ScriptManager:getValue("enemyBridgeSupportDefenderSquadIsDefending");
	
	roundOfReinforcementSpawnInit = ScriptManager:getValue("roundOfReinforcementSpawnInit");
	roundOfEnemyBridgeSupportDefenderSquadSpawnInit = ScriptManager:getValue("roundOfEnemyBridgeSupportDefenderSquadSpawnInit");
	cutsceneForEnemySupplyTruckAppearanceShown = ScriptManager:getValue("cutsceneForEnemySupplyTruckAppearanceShown");
	cutsceneForEnemySapperRepairBridgeShown = ScriptManager:getValue("cutsceneForEnemySapperRepairBridgeShown");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	local triggerX, triggerY = 21, 12;
	local triggerRadius = 1;
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false)
	
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.X_BUILDING_HQ, -1, "onEnemyHqCaptured", "onEnemyHqCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_BUILDING_HQ, -1, "onEnemyHqDestroyed", "onEnemyHqDestroyed");
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankFactoryCaptured", "onEnemyTankFactoryCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankFactoryDestroyed", "onEnemyTankFactoryDestroyed");
	
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnUnitSightedTrigger(AI_ID, Units.X_TRUCK_SUPPLY, -1, true, "onEnemySupplyTruckSighted", "onEnemySupplyTruckSighted");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_ARTILLERY_MORTAR, -1, "onEnemyMortarDestroyed", "onEnemyMortarDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_TRUCK_SUPPLY, -1, "onEnemySupplyTruckDestroyed", "onEnemySupplyTruckDestroyed");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
	
	ScriptManager:addOnTurnStartTrigger(PLAYER_ID, -1, -1, "onPlayerTurnStart", "onPlayerTurnStart");
	
	for i = 1, #enemyMortarUnitSquad do
		Utils:addOnEnterAreaTrigger(enemyMortarUnitSquad[i][2], enemyMortarUnitSquad[i][3], 4, PLAYER_ID, -1, -1, true, "onPlayerEnterArea", "onPlayerEnterArea");
	end
	--Utils:addOnEnterAreaTrigger(triggerX, triggerY, triggerRadius, AI_ID, Units.X_TRUCK_SUPPLY, -1, true, "onEnemyTruckEnterArea", "onEnemyTruckEnterArea");
	ScriptManager:addOnUnitMovedTrigger(AI_ID, Units.X_TRUCK_SUPPLY, -1, "onEnemyTruckUnitMoved", "onEnemyTruckUnitMoved");
	
	-- trigger for main building / unit
--	ScriptManager:addOnUnitHasAttackedTrigger(	1, , -1,	"showAttackedWarning",	"showAttackedWarning" );
--	ScriptManager:addOnUnitHasAttackedTrigger(	0, , -1,	"stopAttackingHint",	"stopAttackingHint" );
--	ScriptManager:addOnUnitDestroyedTrigger(	0, , -1,	"transitionToFail",		"transitionToFail" );
end

function setUpTriggersForBridges()
	ScriptManager:addOnBridgeRepairTrigger(-1, Units.N_BRIDGE_L, -1, "onBridgeRepaired", "onBridgeRepaired");
	ScriptManager:addOnBridgeDetonateTrigger(-1, Units.N_BRIDGE_L, -1, "onBridgeDetonated", "onBridgeDetonated");
	ScriptManager:addOnUnitCapturedTrigger(-1, Units.N_BRIDGE_L, -1, "onBridgeCaptured", "onBridgeCaptured");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BRIDGE_L, -1, "onBridgeDestroyed", "onBridgeDestroyed");
end

function onPlayerTurnStart(playerId, turnId, roundId)
	setBridgesAttackable(true);
	
	if(roundId == ROUND_OF_BRIDGE_MISSION_START) then
		startBridgeMissionCutscene();
	end
end

function onPlayerEnterArea()
	if(ScriptManager:getCurrentRound() > 0) then
		ScriptManager:removeTrigger("onPlayerEnterArea");
		
		startMortarMissionCutscene();
	end
end

function onEnemySupplyTruckSighted(discoveringUnit, discoveredUnit)
	if(getCutsceneForEnemySupplyTruckAppearanceShown() == 0) then
		ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemySupplyTruckSightedCutscene");
		setCutsceneForEnemySupplyTruckAppearanceShown(1);
	end
end

function onEnemySquadDestroyed(squadId)
	if(squadId == enemySquadIds.BRIDGE_SUPPORT_SAPPER) then
		setEnemyBridgeSupportSapperIsActive(0);
		setEnemyBridgeSupportSapperIsInRange(0);
		setEnemyBridgeSupportSapperFinishedRepair(0);
	--[[elseif(squadId == enemySquadIds.BRIDGE_SUPPORT_DEFENDER) then
		setEnemyBridgeSupportDefenderSquadIsActive(0);
		setEnemyBridgeSupportDefenderSquadIsDefending(0);
		setRoundOfEnemyBridgeSupportDefenderSquadSpawnInit(ScriptManager:getCurrentRound());--]]
	end
end

function onEnemyTruckUnitMoved(unit)
	local currentX, currentY = unit:getX(), unit:getY();
	for i = 1, #enemyReinforcementTriggerFields do
		if(enemyReinforcementTriggerFields[i][1] == currentX) and (enemyReinforcementTriggerFields[i][2] == currentY) then
			if(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
				ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemySupplyTruckExchangeCutscene");
			end
		end
	end
end

function onEnemyTruckEnterArea()
	ScriptManager:removeTrigger("onEnemyTruckEnterArea");
	
	exchangeSuppliesForEnemyReinforcements();
	Utils:addOnEnterAreaTrigger(21, 12, 1, AI_ID, Units.X_TRUCK_SUPPLY, -1, true, "onEnemyTruckEnterArea", "onEnemyTruckEnterArea");
end

function onEnemyHqCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	ScriptManager:removeTrigger("onEnemyHqDestroyed");

	setEnemyHqIsCapturedDestroyed(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) ~= MissionStatus.FAILED) then
		if(getEnemySupplyTruckIsActive() == 0) then
			if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) ~= MissionStatus.FAILED) then
				ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.ACCOMPLISHED);
			end
		end
	end
	
	checkForVictory();
end

function onEnemyHqDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyHqDestroyed");
	ScriptManager:removeTrigger("onEnemyHqCaptured");
	
	setEnemyHqIsCapturedDestroyed(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) ~= MissionStatus.FAILED) then
		if(getEnemySupplyTruckIsActive() == 0) then
			if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) == MissionStatus.IN_PROGRESS) then
				ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.ACCOMPLISHED);
			end
		end
	end
	
	checkForVictory();
end

function onEnemyTankFactoryCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyTankFactoryCaptured");
	ScriptManager:removeTrigger("onEnemyTankFactoryDestroyed");
	ScriptManager:removeTrigger("onEnemySupplyTruckDestroyed");
	ScriptManager:removeTrigger("onEnemySupplyTruckSighted");
	
	setEnemyTankFactoryIsCapturedDestroyed(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_TANK_FACTORY, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) == MissionStatus.IN_PROGRESS) then
		ScriptManager:removeTrigger("onEnemySupplyTruckSighted");
		ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.ACCOMPLISHED);
	end
	
	if(getEnemySupplyTruckIsActive() == 1) then
		ScriptManager:removeAllOrders(enemySquadIds.SUPPLY_TRUCK_WAVE);
		ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, 3, 33, -1, 2, AiOrder.DEFEND)
	end
	
	checkForVictory();
end

function onEnemyTankFactoryDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyTankFactoryDestroyed");
	ScriptManager:removeTrigger("onEnemyTankFactoryCaptured");
	ScriptManager:removeTrigger("onEnemySupplyTruckDestroyed");
	ScriptManager:removeTrigger("onEnemySupplyTruckSighted");

	setEnemyTankFactoryIsCapturedDestroyed(1);
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_TANK_FACTORY, MissionStatus.ACCOMPLISHED);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) == MissionStatus.IN_PROGRESS) then
		ScriptManager:removeTrigger("onEnemySupplyTruckSighted");
		ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.ACCOMPLISHED);
	end
	
	if(getEnemySupplyTruckIsActive() == 1) then
		ScriptManager:removeAllOrders(enemySquadIds.SUPPLY_TRUCK_WAVE);
		ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, 3, 33, -1, 2, AiOrder.DEFEND)
	end
	
	checkForVictory();
end

function onEnemySupplyTruckDestroyed(unit)
	--print("#####################################################_____DESTROYED!");
	setEnemySupplyTruckIsActive(0);
	setRoundOfReinforcementSpawnInit(ScriptManager:getCurrentRound());
	setCutsceneForEnemySupplyTruckAppearanceShown(0);
	
	if(getEnemyHqIsCapturedDestroyed() == 1) then
		if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) == MissionStatus.IN_PROGRESS) then
			ScriptManager:removeTrigger("onEnemySupplyTruckDestroyed");
			ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.ACCOMPLISHED);
		end
	end
	
	ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemySupplyTruckDestroyedCutscene");
end

function onEnemyMortarDestroyed()
	incrementEnemyMortarsDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_MORTARS, getEnemyMortarsDestroyed());
	
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_MORTARS) == MissionStatus.IN_PROGRESS) then
		if(getEnemyMortarsDestroyed() >= ENEMY_MORTARS_TO_DESTROY) then
			ScriptManager:removeTrigger("onEnemyMortarDestroyed");
			
			ScriptManager:setMissionStatus(missionIds.DESTROY_ENEMY_MORTARS, MissionStatus.ACCOMPLISHED);
		else
			ScriptManager:runForPlayer(PLAYER_ID, "updateDestroyMortarMissionProgress");
		end
	end
end

function updateDestroyMortarMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_ENEMY_MORTARS), ENEMY_MORTARS_TO_DESTROY, Text.T_CAMP_L_4_3_SECONDARY3_COUNTER);
end

function onEnemyTurnStart(playerId, turnId, roundId)
	setBridgesAttackable(false);
	
	if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) or
		(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) then
		setPlayerHasBridges(1);
	elseif(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() ~= PLAYER_ID) and
		(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() ~= PLAYER_ID) then
		setPlayerHasBridges(0);
	end
	
	if(ScriptManager:getCurrentRound() < ROUND_OF_BRIDGE_MISSION_START) then
		spawnEnemyBridgeSupportDefenderSquad();
		setEnemyBridgeSupportDefenderSquadIsActive(1);
		setRoundOfEnemyBridgeSupportDefenderSquadSpawnInit(ScriptManager:getCurrentRound());
	end
	
	updateEnemyMortarUnits();
	updateEnemyHowitzerUnits();
	
	if(getEnemyHqIsCapturedDestroyed() == 0) then
		if(getEnemySupplyTruckIsActive() == 0) and (getEnemySupplyTrucksSpawned() < MAX_NUMBER_OF_ENEMY_SUPPLY_TRUCK_SPAWNS)then
			if(roundId == ROUND_OF_ENEMY_SUPPLY_TRUCK_SPAWN) then
				spawnEnemySupplyTruck();
				setRoundOfReinforcementSpawnInit(ScriptManager:getCurrentRound());
			elseif(getRoundOfReinforcementSpawnInit() ~= -1) then
				if(roundId >= getRoundOfReinforcementSpawnInit() + ROUNDS_BETWEEN_SUPPLY_TRUCK_SPAWN) then
					spawnEnemySupplyTruck();
				end
			end
		end
	end
	
	if(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
		if(bridgeUnitNeedsRepair(NORTHERN_BRIDGE_UNIT_ID) == 1) or
			(bridgeUnitNeedsRepair(CENTER_BRIDGE_UNIT_ID) == 1) then
			if(getEnemyBridgeSupportSapperIsActive() == 0) and (getNumberOfEnemySapperSpawns() < MAX_NUMBER_OF_ENEMY_SAPPER_SPAWNS) then
				spawnEnemyBridgeSupportSapper();
				setEnemyBridgeSupportSapperIsActive(1);
			end
		end
		
		--[[if(getPlayerHasBridges() ~= 0) then
			if(getEnemyBridgeSupportDefenderSquadIsActive() == 0) then
				if(getRoundOfEnemyBridgeSupportDefenderSquadSpawnInit() == -1) then
					spawnEnemyBridgeSupportDefenderSquad();
					setEnemyBridgeSupportDefenderSquadIsActive(1);
					setRoundOfEnemyBridgeSupportDefenderSquadSpawnInit(ScriptManager:getCurrentRound());
				else
					if(roundId >= getRoundOfEnemyBridgeSupportDefenderSquadSpawnInit() + ROUNDS_BETWEEN_BRIDGE_DEFENDER_SPAWN) then
						spawnEnemyBridgeSupportDefenderSquad();
						setEnemyBridgeSupportDefenderSquadIsActive(1);
					end
				end
			end
		end--]]
	end
	
	if(getEnemyBridgeSupportSapperIsActive() == 1) then
		updateEnemyBridgeSupportSapper();
	end
		
	if(getEnemyBridgeSupportDefenderSquadIsActive() == 1) then
		updateEnemyBridgeSupportDefenderSquad();
	end
end

function onBridgeDestroyed(unit)
	--print("#############################################################_______BRIDGE DESTROYED!");
	if(unit ~= nil) then
		if(unit:getId() == NORTHERN_BRIDGE_UNIT_ID) then
			if(getNorthernBridgeIsDestroyed() == 0) then
				setNorthernBridgeIsDestroyed(1);
				unit:setIsAttackable(false);
				incrementBridgeMissionProgress();
			end
		elseif(unit:getId() == CENTER_BRIDGE_UNIT_ID) then
			if(getCenterBridgeIsDestroyed() == 0) then
				setCenterBridgeIsDestroyed(1);
				unit:setIsAttackable(false);
				incrementBridgeMissionProgress();
			end
		end
	end
end

function onBridgeRepaired(repairer, bridge)	
	if(repairer ~= nil) and (bridge ~= nil) then
		if(repairer:getPlayerId() == PLAYER_ID) then
			onPlayerRepairedBridge(repairer, bridge);
		else
			onEnemyRepairedBridge(repairer, bridge);
		end
	end
end

function onPlayerRepairedBridge(repairer, bridge)
	local currentHealth = bridge:getHealth();
	
	if(currentHealth >= MAX_HP_OF_BRIDGE_UNITS) then
		if(bridge:getId() == NORTHERN_BRIDGE_UNIT_ID) then
			if(getNorthernBridgeIsDestroyed() == 1) then
				decrementBridgeMissionProgress();
				setNorthernBridgeIsDestroyed(0);
				bridge:setIsAttackable(true);
				
				ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
			end
		elseif(bridge:getId() == CENTER_BRIDGE_UNIT_ID) then
			if(getCenterBridgeIsDestroyed() == 1) then
				decrementBridgeMissionProgress();
				setCenterBridgeIsDestroyed(0);
				bridge:setIsAttackable(true);
				
				ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
			end
		end
	end
end

function onEnemyRepairedBridge(repairer, bridge)
	local currentHealth = bridge:getHealth();
	
	if(currentHealth >= MAX_HP_OF_BRIDGE_UNITS) then
		setEnemyBridgeSupportSapperIsInRange(0);
		setEnemyBridgeSupportSapperFinishedRepair(1);
		
		if(bridge:getId() == NORTHERN_BRIDGE_UNIT_ID) then
			if(getNorthernBridgeIsDestroyed() == 1) then
				decrementBridgeMissionProgress();
				setNorthernBridgeIsDestroyed(0);
				bridge:setIsAttackable(true);
			end
		elseif(bridge:getId() == CENTER_BRIDGE_UNIT_ID) then
			if(getCenterBridgeIsDestroyed() == 1) then
				decrementBridgeMissionProgress();
				setCenterBridgeIsDestroyed(0);
				bridge:setIsAttackable(true);
			end
		end
		
		ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemyRepairFinishCutscene");
	else
		if(getCutsceneForEnemySapperRepairBridgeShown() == 0) then
			setCutsceneForEnemySapperRepairBridgeShown(1);
		
			ScriptManager:runForPlayer(PLAYER_ID, "prepareEnemyRepairAlertCutscene");
		end
	end
end

function onBridgeCaptured(capturingUnit, capturedUnit)
	--print("#############################################################_______BRIDGE CAPTURED!");
	if(capturingUnit ~= nil) then
		if(capturingUnit:getPlayerId() == PLAYER_ID) then
			if(getEnemySupplyTruckIsActive() == 1) then
				if(Unit:getUnitById(getEnemySupplyTruckUnitId()) ~= nil) then
					local pointOfNoReturn = 13;
					
					if(Unit:getUnitById(getEnemySupplyTruckUnitId()):getX() <= pointOfNoReturn) and
						(getEnemySupplyTruckIsOnSavePath() == 0) then
						local orderX, orderY = 0, 0;
						
						orderX, orderY = getNewEnemySupplyTruckOrderCoords();
						resetEnemySupplyTruckOrder(orderX, orderY);
					end
				end
			end
		else
			ScriptManager:removeAllOrders(enemySquadIds.BRIDGE_SUPPORT_DEFENDER);
		end
	end
end

function onBridgeDetonated(detonater, bridge)
	--print("#############################################################_______BRIDGE DETONATED!");
	if(getEnemyBridgeSupportSapperIsActive() == 1) then
		if(ScriptManager:getSquadOrderCount(enemySquadIds.BRIDGE_SUPPORT_SAPPER) <= 0) and
			(getEnemyBridgeSupportSapperIsInRange() == 0) then
			setMoveOrderForEnemyBridgeSupportSapper();
		end
	end
	
	if(getEnemyBridgeSupportDefenderSquadIsActive() == 1) then
		if(ScriptManager:getSquadOrderCount(enemySquadIds.BRIDGE_SUPPORT_DEFENDER) > 0) then
			if(getEnemyBridgeSupportDefenderSquadIsDefending() == 0) then
				ScriptManager:removeAllOrders(enemySquadIds.BRIDGE_SUPPORT_DEFENDER);
			end
		end
	end
end

function incrementBridgeMissionProgress()
	incrementBridgesDestroyed();
	ScriptManager:setMissionProgress(missionIds.DETONATE_BRIDGES, getBridgesDestroyed());
	
	if(getBridgesDestroyed() >= BRIDGES_TO_DESTROY) then
		--[[if(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY2_FLAVOR4, 6);
		else
			if(getEnemyBridgeSupportSapperIsActive() == 0) then
				ScriptManager:removeTrigger("onBridgeDestroyed");
				ScriptManager:removeTrigger("onBridgeRepaired");
				
				ScriptManager:setMissionStatus(missionIds.DETONATE_BRIDGES, MissionStatus.ACCOMPLISHED);
			else
				Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY2_FLAVOR4, 6);
			end
		end--]]
		if(ScriptManager:getMissionStatus(missionIds.DETONATE_BRIDGES) == MissionStatus.IN_PROGRESS) then
			ScriptManager:setMissionStatus(missionIds.DETONATE_BRIDGES, MissionStatus.ACCOMPLISHED);
		end
	else
		if(ScriptManager:getMissionStatus(missionIds.DETONATE_BRIDGES) == MissionStatus.IN_PROGRESS) then
			ScriptManager:runForPlayer(PLAYER_ID, "updateBridgeMissionProgress");
		end
	end
end

function decrementBridgeMissionProgress()
	decrementBridgesDestroyed();
	ScriptManager:setMissionProgress(missionIds.DETONATE_BRIDGES, getBridgesDestroyed());
end

function updateBridgeMissionProgress()
	if(ScriptManager:getMissionStatus(missionIds.DETONATE_BRIDGES) == MissionStatus.IN_PROGRESS) then
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DETONATE_BRIDGES), BRIDGES_TO_DESTROY, Text.T_COUNTER_DESTROY_BRIDGES);
	end
end

-- #######################################-AI_ORDER-#######################################

function addAiOrders()
	local aiRadiusNormal = 2;
	local aiRadiusWide = 3;
	local aiRadiusArti = 4;
	local aiRadiusHowitzer = 6;
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_HQ, 3, 33, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_TF, 21, 12, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES_SOUTH, 4, 16, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ROAD_BLOCK_SOUTH, 4, 20, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ROAD_BLOCK_CENTER, 9, 23, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ROAD_BLOCK_NORTH, 11, 31, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.VILLAGE_NORTH, 16, 30, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_SOUTH, 12, 7, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_CENTER, 13, 17, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_BRIDGE_NORTH, 18, 26, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SUPPLY_CRATES_RIVER, 17, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.SNIPER_SNOW_MOUNTAIN, 10, 16, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_PLATEAU, 20, 6, -1, aiRadiusArti, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_HOWITZER_CENTER, 19, 14, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_HOWITZER_NORTH, 24, 22, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.MG_NEST_ROAD_SOUTH, 14, 21, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_ROAD_CENTER, 5, 30, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_ROAD_NORTH, 19, 29, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.BUNKER_SOUTH_ONE, 2, 22, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_SOUTH_TWO, 5, 24, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_CENTER_ONE, 7, 26, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_CENTER_TWO, 9, 27, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_NORTH_ONE, 9, 31, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_NORTH_TWO, 10, 32, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_NORTH_THREE, 10, 34, -1, aiRadiusWide, AiOrder.DEFEND);
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
	
	if(missionId == missionIds.DESTROY_ENEMY_MORTARS) then
		ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_MORTARS, getEnemyMortarsDestroyed());
	end
end

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_TANK_FACTORY) == MissionStatus.ACCOMPLISHED) then
		
		if(getBridgesDestroyed() >= BRIDGES_TO_DESTROY) and
			(ScriptManager:getMissionStatus(missionIds.DETONATE_BRIDGES) == MissionStatus.IN_PROGRESS) then
			ScriptManager:setMissionStatus(missionIds.DETONATE_BRIDGES, MissionStatus.ACCOMPLISHED);
		end
		
		startVictoryCutscene();
	elseif(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ) ~= MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_TANK_FACTORY) == MissionStatus.ACCOMPLISHED) then
		startTankFactoryDestroyedCutscene();
	elseif(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_ENEMY_HQ) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.CAPTURE_DESTROY_TANK_FACTORY) ~= MissionStatus.ACCOMPLISHED) then
		startHqDestroyedCutscene();
	end
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );-- TODO: add templateDI @end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_INTRO_FLAVOR1, 5);
	
	ScriptManager:moveCameraEx(3, 33, 0.7, 3, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_INTRO_FLAVOR2, 6);
	ScriptManager:moveCameraEx(21, 12, 0.7, 3, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_INTRO_FLAVOR3, 4);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.CAPTURE_DESTROY_ENEMY_HQ);
	startMission(missionIds.CAPTURE_DESTROY_TANK_FACTORY);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_VICTORY_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_VICTORY_FLAVOR2, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_VICTORY_FLAVOR3, 4);

	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function startTankFactoryDestroyedCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_PRIMARY1_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_PRIMARY1_FLAVOR2, 3);
	
	Utils:endCutscene();
end

function startHqDestroyedCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_PRIMARY2_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_PRIMARY2_FLAVOR2, 3);
	
	Utils:endCutscene();
end

function startBridgeMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY1_FLAVOR1, 5);
	
	ScriptManager:moveCameraEx(3, 33, 0.7, 3, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY1_FLAVOR2, 5);
	
	ScriptManager:moveCameraEx(21, 12, 0.7, 3, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY1_FLAVOR3, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY1_FLAVOR4, 6);
	
	ScriptManager:moveCameraEx(9, 28, 0.4, 3, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY2_FLAVOR1, 6);
	
	ScriptManager:moveCameraEx(18, 20, 0.5, 2, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY2_FLAVOR2, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY2_FLAVOR3, 7);
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	
	Utils:endCutscene();
	
	startMission(missionIds.DETONATE_BRIDGES);
	startMission(missionIds.PREVENT_ENEMY_EXCHANGE);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startMortarMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(10, 28, 0.4, 3, true);
	
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) ~= MissionStatus.ACCOMPLISHED) and
		(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR1, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR2, 6);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR3, 5);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR4, 4);
	else
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR5, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR6, 4);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SECONDARY3_FLAVOR7, 3);
	end
	
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	
	Utils:endCutscene();
	
	startMission(missionIds.DESTROY_ENEMY_MORTARS);
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function prepareEnemyRepairAlertCutscene()
	table.insert(queueTable, playEnemyRepairAlertCutscene);
	Utils:cutsceneQueue();
end

function playEnemyRepairAlertCutscene()
	if(Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()) ~= nil) then
		local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
		local sapperX, sapperY = Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getX(), Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getY();
		
		Utils:startCutscene();
		
		ScriptManager:revealFogOfWar(sapperX, sapperY, 1, true);
		ScriptManager:moveCameraEx(sapperX, sapperY, 0.7, 3, true);
		ScriptManager:showMarkerAt(sapperX, sapperY);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_ENEMY_REPAIR_ALERT_FLAVOR1, 3);
		
		ScriptManager:removeAllMarkers();
		ScriptManager:revealFogOfWar(sapperX, sapperY, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
		
		Utils:endCutscene();
	end
end

function prepareEnemyRepairFinishCutscene()
	table.insert(queueTable, playEnemyRepairFinishCutscene);
	Utils:cutsceneQueue();
end

function playEnemyRepairFinishCutscene()
	if(Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()) ~= nil) then
		local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
		local sapperX, sapperY = Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getX(), Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getY();
		local bridgeX, bridgeY = 16, 16;
		
		if(sapperY >= 20) then
			bridgeX, bridgeY = 21, 24;
		end
		
		Utils:startCutscene();
		
		ScriptManager:revealFogOfWar(bridgeX, bridgeY, 2, true);
		ScriptManager:moveCameraEx(bridgeX, bridgeY, 0.7, 3, true);
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_ENEMY_REPAIR_FINISH_FLAVOR1, 3);
		
		ScriptManager:revealFogOfWar(bridgeX, bridgeY, 2, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
		
		Utils:endCutscene();
	end
	
	if(ScriptManager:getMissionStatus(missionIds.DETONATE_BRIDGES) == MissionStatus.IN_PROGRESS) then
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DETONATE_BRIDGES), BRIDGES_TO_DESTROY, Text.T_COUNTER_DESTROY_BRIDGES);
	end
end

function prepareEnemySupplyTruckSightedCutscene()
	table.insert(queueTable, playEnemySupplyTruckSightedCutscene);
	Utils:cutsceneQueue();
end

function playEnemySupplyTruckSightedCutscene()
	if(Unit:getUnitById(getEnemySupplyTruckUnitId()) ~= nil) then
		local truckX, truckY = Unit:getUnitById(getEnemySupplyTruckUnitId()):getX(), Unit:getUnitById(getEnemySupplyTruckUnitId()):getY();
		
		Utils:startCutscene();
		
		ScriptManager:revealFogOfWar(truckX, truckY, 1, true);
		ScriptManager:moveCameraEx(truckX, truckY, 0.7, 2, true);
		ScriptManager:showMarkerAt(truckX, truckY);
		
		if(getEnemySupplyTrucksSpawned() <= 1) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_SIGHTED_FLAVOR1, 3);
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_SIGHTED_FLAVOR2, 2);
		else
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_SIGHTED_FLAVOR3, 3);
		end
		
		ScriptManager:removeAllMarkers();
		ScriptManager:revealFogOfWar(truckX, truckY, 1, false);
		
		Utils:endCutscene();
	end
end

function prepareEnemySupplyTruckDestroyedCutscene()
	table.insert(queueTable, playEnemySupplyTruckDestroyedCutscene);
	Utils:cutsceneQueue();
end

function playEnemySupplyTruckDestroyedCutscene()
	Utils:startCutscene();
	
	if(getEnemyHqIsCapturedDestroyed() == 0) then
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_DESTROYED_FLAVOR1, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_DESTROYED_FLAVOR2, 4);
	else
		if(getEnemySupplyTrucksSpawned() <= 1) then
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_DESTROYED_FLAVOR3, 5);
		else
			Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_SUPPLY_TRUCK_DESTROYED_FLAVOR4, 3);
		end
	end
	
	Utils:endCutscene();
end

function prepareEnemySupplyTruckExchangeCutscene()
	table.insert(queueTable, playEnemySupplyTruckExchangeCutscene);
	Utils:cutsceneQueue();
end

function playEnemySupplyTruckExchangeCutscene()
	if(ScriptManager:getMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE) == MissionStatus.IN_PROGRESS) then
		ScriptManager:setMissionStatus(missionIds.PREVENT_ENEMY_EXCHANGE, MissionStatus.FAILED);
	end
	
	if(Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID) ~= nil) then
		local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
		local hqX, hqY = Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getX(), Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getY();
		
		Utils:startCutscene();
		
		ScriptManager:revealFogOfWar(hqX, hqY, 1, true);
		ScriptManager:moveCameraEx(hqX, hqY, 0.7, 2, true);

		Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_3_ENEMY_EXCHANGE_FLAVOR1, 4);
		
		exchangeSuppliesForEnemyReinforcements();
		ScriptManager:wait(3.5);
		
		ScriptManager:revealFogOfWar(hqX, hqY, 1, false);
		ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2, true);
		
		Utils:endCutscene();
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

function setBridgesAttackable(bool)
	if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID) ~= nil) then
		Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):setIsAttackable(bool);
		if(getNorthernBridgeIsDestroyed() == 1) then
			Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):setIsAttackable(false);
		end
	end
	
	if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID) ~= nil) then
		Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):setIsAttackable(bool);
		if(getCenterBridgeIsDestroyed() == 1) then
			Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):setIsAttackable(false);
		end
	end
end

function updateEnemyMortarUnits()
	for i = 1, #enemyMortarUnitSquad do
		if(Unit:getUnitById(enemyMortarUnitSquad[i][1]) ~= nil) then
			Unit:getUnitById(enemyMortarUnitSquad[i][1]):setActionPoints(0);
			ScriptManager:smokeTile(enemyMortarUnitSquad[i][1], enemyMortarUnitSquad[i][2], enemyMortarUnitSquad[i][3], true);
		end
	end
end

function updateEnemyHowitzerUnits()
	if(Unit:getUnitById(ENEMY_HOWITZER_CENTER_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_HOWITZER_CENTER_UNIT_ID):setActionPoints(0);
	end
	
	if(Unit:getUnitById(ENEMY_HOWITZER_NORTH_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_HOWITZER_NORTH_UNIT_ID):setActionPoints(0);
	end
end

function spawnEnemySupplyTruck()
	if(Unit:getUnitById(ENEMY_HQ_UNIT_ID) ~= nil) then
		local hqX, hqY = Unit:getUnitById(ENEMY_HQ_UNIT_ID):getX(), Unit:getUnitById(ENEMY_HQ_UNIT_ID):getY();

		setEnemySupplyTruckUnitId(ScriptManager:spawnUnit(AI_ID, Units.X_TRUCK_SUPPLY, hqX, hqY, enemySquadIds.SUPPLY_TRUCK_WAVE):getId());
		setEnemySupplyTruckIsActive(1);
		setEnemySupplyTruckIsOnSavePath(0);
		incrementEnemySupplyTrucksSpawned();
		
		if(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
			local orderX, orderY = getEnemySupplyTruckOrderCoords();
			local currentOrder = ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, orderX, orderY, -1, 1, AiOrder.MOVE);
			--ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
			
			local tankFactoryX, tankFactoryY = 21, 12;
			local nextOrder = ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, tankFactoryX, tankFactoryY, -1, 1, AiOrder.MOVE);
			--ScriptManager:enableOrderFlag(nextOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
		end
	end
end

function despawnEnemySupplyTruck()
	--print("###############################################################_____DESPAWN!");
	if(Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID) ~= nil) then
		--print("##########################################_____SUPPLIES: ", Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getSupplyLoad());
		Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):setSupplyLoad(Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getSupplyLoad() - Unit:getUnitById(getEnemySupplyTruckUnitId()):getSupplyLoad());
		--print("##########################################_____SUPPLIES: ", Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getSupplyLoad());
		ScriptManager:supplyUnitEx(getEnemySupplyTruckUnitId(), ENEMY_TANK_FACTORY_UNIT_ID, true);
		ScriptManager:wait(1);
		--print("##########################################_____SUPPLIES: ", Unit:getUnitById(ENEMY_TANK_FACTORY_UNIT_ID):getSupplyLoad());
		ScriptManager:removeUnitEx(getEnemySupplyTruckUnitId(), true);
		setCutsceneForEnemySupplyTruckAppearanceShown(0);
	end
end

function spawnEnemyReinforcementTankWave()
	local numberOfSpawningUnits = math.random(2, 5);
	local currentSquadId = getEnemyTankWaveInitSquadId();
	
	for i = 1, numberOfSpawningUnits do
		ScriptManager:spawnUnit(AI_ID, enemyReinforcementTankPattern[i], 21, 12, currentSquadId);
	end
	
	if(getEnemyHqIsCapturedDestroyed() == 0) then
		local currentX, currentY = 3, 33;
		local currentOrder = ScriptManager:addOrder(currentSquadId, currentX, currentY, -1, 2, AiOrder.MOVE);
		
		ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_HOLD_FIRE);
		
		ScriptManager:addOrder(currentSquadId, currentX, currentY, -1, 2, AiOrder.DEFEND);
	else
		local currentOrder = ScriptManager:addOrder(currentSquadId, 21, 12, -1, 3, AiOrder.DEFEND);
	end

	
	setEnemyTankWaveInitSquadId(getEnemyTankWaveInitSquadId() + 1);
end

function exchangeSuppliesForEnemyReinforcements()
	despawnEnemySupplyTruck();
	ScriptManager:wait(1);
	spawnEnemyReinforcementTankWave();
	setEnemySupplyTruckIsActive(0);
	setRoundOfReinforcementSpawnInit(ScriptManager:getCurrentRound() + 1);
end

function getEnemySupplyTruckOrderCoords()
	local rnd = math.random(1, 100);
	local orderX, orderY = 0, 0;
	
	if(rnd <= 20) then
		orderX, orderY = enemySupplyTruckOrderFields.southernBridge[1], enemySupplyTruckOrderFields.southernBridge[2];
		setEnemySupplyTruckIsOnSavePath(1);
	elseif(rnd > 20) and (rnd <= 60) then
		orderX, orderY = enemySupplyTruckOrderFields.northernBridge[1], enemySupplyTruckOrderFields.northernBridge[2];
		
		if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID) ~= nil) then
			if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() ~= AI_ID) then
				orderX, orderY = getEnemySupplyTruckOrderCoords();
			end
		end
	else
		orderX, orderY = enemySupplyTruckOrderFields.centerBridge[1], enemySupplyTruckOrderFields.centerBridge[2];
		
		if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID) ~= nil) then
			if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() ~= AI_ID) then
				orderX, orderY = getEnemySupplyTruckOrderCoords();
			end
		end
	end
	
	return orderX, orderY;
end

function getNewEnemySupplyTruckOrderCoords()
	--print("#################################################____REROLL!");
	local currentBridgeId = checkBridgeUnitBelongingToAi();
	
	if(currentBridgeId == CENTER_BRIDGE_UNIT_ID) then
		--print("#################################################____CENTER!");
		return enemySupplyTruckOrderFields.centerBridge[1], enemySupplyTruckOrderFields.centerBridge[2];
	elseif(currentBridgeId == NORTHERN_BRIDGE_UNIT_ID) then
		--print("#################################################____NORTHERN!");
		return enemySupplyTruckOrderFields.northernBridge[1], enemySupplyTruckOrderFields.northernBridge[2];
	else
		--print("#################################################____SOUTH!");
		return enemySupplyTruckOrderFields.southernBridge[1], enemySupplyTruckOrderFields.southernBridge[2];
	end
end

function resetEnemySupplyTruckOrder(x, y)
	ScriptManager:removeAllOrders(enemySquadIds.SUPPLY_TRUCK_WAVE);
	
	local currentOrder = ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, x, y, -1, 1, AiOrder.MOVE);
	--ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
	
	local tankFactoryX, tankFactoryY = 21, 12;
	local nextOrder = ScriptManager:addOrder(enemySquadIds.SUPPLY_TRUCK_WAVE, tankFactoryX, tankFactoryY, -1, 1, AiOrder.MOVE);
	--ScriptManager:enableOrderFlag(nextOrder, AiOrderFlag.FLAG_AVOID_ENEMY);
end

function checkBridgeUnitBelongingToAi()
	if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID) ~= nil) then
		if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() == AI_ID) then
			return CENTER_BRIDGE_UNIT_ID;
		end
	end
	
	if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID) ~= nil) then
		if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() == AI_ID) then
			return NORTHERN_BRIDGE_UNIT_ID;
		end
	end
	
	return -1;
end

function bridgeUnitNeedsRepair(bridgeId)
	if(Unit:getUnitById(bridgeId) ~= nil) then
		if(Unit:getUnitById(bridgeId):getHealth() < MAX_HP_OF_BRIDGE_UNITS) then
			return 1;
		end
	end
	
	return 0;
end

function spawnEnemyBridgeSupportSapper()
	setEnemyBridgeSupportSapperUnitId(ScriptManager:spawnUnit(AI_ID, enemyBridgeSupportSquad[1][1], enemyBridgeSupportSquad[1][2], enemyBridgeSupportSquad[1][3], enemyBridgeSupportSquad[1][6]):getId());
	setMoveOrderForEnemyBridgeSupportSapper();
	incrementNumberOfEnemySapperSpawns()
end

function spawnEnemyBridgeSupportDefenderSquad()
	for i = 2, #enemyBridgeSupportSquad do
		ScriptManager:spawnUnit(AI_ID, enemyBridgeSupportSquad[i][1], enemyBridgeSupportSquad[i][2], enemyBridgeSupportSquad[i][3], enemyBridgeSupportSquad[i][6]);
	end
	
	setCaptureOrderForEnemyBridgeSupportDefenderSquad();
end

function updateEnemyBridgeSupportSapper()
	if(Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()) ~= nil) then
		if(ScriptManager:getSquadOrderCount(enemySquadIds.BRIDGE_SUPPORT_SAPPER) <= 0) then
			local currentX, currentY = Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getX(), Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getY();
		
			for i = 1, #enemyBridgeSupportSapperTriggerFields do
				if(currentX == enemyBridgeSupportSapperTriggerFields[i][1]) and
					(currentY == enemyBridgeSupportSapperTriggerFields[i][2]) then
					setEnemyBridgeSupportSapperIsInRange(1);
				end
			end
			
			if(getEnemyBridgeSupportSapperIsInRange() == 1) then
				local bridgeId = CENTER_BRIDGE_UNIT_ID;
				
				if(Unit:getUnitById(getEnemyBridgeSupportSapperUnitId()):getY() > 20) then
					bridgeId = NORTHERN_BRIDGE_UNIT_ID;
				end
				
				if(Unit:getUnitById(bridgeId) ~= nil) then
					if(Unit:getUnitById(bridgeId):getPlayerId() ~= PLAYER_ID) and
						(Unit:getUnitById(bridgeId):getHealth() < MAX_HP_OF_BRIDGE_UNITS) then
						setEnemyBridgeSupportSapperFinishedRepair(0);
						ScriptManager:repairBridge(getEnemyBridgeSupportSapperUnitId(), bridgeId, true);
					else
						if((bridgeUnitNeedsRepair(NORTHERN_BRIDGE_UNIT_ID) == 1) or 
							(bridgeUnitNeedsRepair(CENTER_BRIDGE_UNIT_ID) == 1)) then
							setEnemyBridgeSupportSapperFinishedRepair(1);
							setMoveOrderForEnemyBridgeSupportSapper();
						end
					end
				end
			end
			
			if(getEnemyBridgeSupportSapperFinishedRepair() == 1) then
				if((bridgeUnitNeedsRepair(NORTHERN_BRIDGE_UNIT_ID) == 1) or 
					(bridgeUnitNeedsRepair(CENTER_BRIDGE_UNIT_ID) == 1)) then
					setMoveOrderForEnemyBridgeSupportSapper();
				end
			end
		end
		
		if((bridgeUnitNeedsRepair(NORTHERN_BRIDGE_UNIT_ID) ~= 1) and 
			(bridgeUnitNeedsRepair(CENTER_BRIDGE_UNIT_ID) ~= 1)) then
			--print("###############################################################____NOTHING TO DO - RETREAT!");
			ScriptManager:removeAllOrders(enemySquadIds.BRIDGE_SUPPORT_SAPPER);
			ScriptManager:addOrder(enemySquadIds.BRIDGE_SUPPORT_SAPPER, 21, 12, -1, 2, AiOrder.MOVE);
			setEnemyBridgeSupportSapperIsInRange(0);
			setEnemyBridgeSupportSapperFinishedRepair(1);
		end
	end
end

function updateEnemyBridgeSupportDefenderSquad()
	if(ScriptManager:getSquadOrderCount(enemySquadIds.BRIDGE_SUPPORT_DEFENDER) <= 0) then
		if(getPlayerHasBridges() ~= 0) then
			if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) or
				(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) then
				setCaptureOrderForEnemyBridgeSupportDefenderSquad();
			end
		else
			if(getEnemyTankFactoryIsCapturedDestroyed() == 0) then
				if(getEnemyBridgeSupportSapperIsActive() == 1) then
					setDefendOrderForEnemyBridgeSupportDefenderSquad(getEnemyBridgeSupportSapperUnitId());
				else
					setDefendOrderForEnemyBridgeSupportDefenderSquad(ENEMY_TANK_FACTORY_UNIT_ID);
				end
			else
				setDefendOrderForEnemyBridgeSupportDefenderSquad(ENEMY_HQ_UNIT_ID);
			end
		end
	else
		if(getEnemyBridgeSupportDefenderSquadIsDefending() == 1) then
			if(getPlayerHasBridges() ~= 0) then
				if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) or
					(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) then
					ScriptManager:removeAllOrders(enemySquadIds.BRIDGE_SUPPORT_DEFENDER);
					setCaptureOrderForEnemyBridgeSupportDefenderSquad();
				end
			end
		end
	end
end

function setMoveOrderForEnemyBridgeSupportSapper()
	local orderX, orderY = 21, 23;
	
	if(bridgeUnitNeedsRepair(CENTER_BRIDGE_UNIT_ID) == 1) then
		orderX, orderY = 16, 15;
	end
	
	ScriptManager:addOrder(enemyBridgeSupportSquad[1][6], orderX, orderY, -1, 1, AiOrder.MOVE);
	setEnemyBridgeSupportSapperIsInRange(0);
	setCutsceneForEnemySapperRepairBridgeShown(0);
end

function setCaptureOrderForEnemyBridgeSupportDefenderSquad()
	local bridgeUnitId = nil;

	if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) then
		if(Unit:getUnitById(CENTER_BRIDGE_UNIT_ID) ~= nil) then
			bridgeUnitId = CENTER_BRIDGE_UNIT_ID;
			--print("#####################################################################################___CAPTURE CENTER");
		end
	end
	
	if(bridgeUnitId == nil) then
		if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID):getPlayerId() == PLAYER_ID) then
			if(Unit:getUnitById(NORTHERN_BRIDGE_UNIT_ID) ~= nil) then
				bridgeUnitId = NORTHERN_BRIDGE_UNIT_ID;
				--print("#####################################################################################___CAPTURE NORTH");
			end
		end
	end
	
	if(bridgeUnitId ~= nil) then
		local currentOrder = ScriptManager:addOrder(enemySquadIds.BRIDGE_SUPPORT_DEFENDER, -1, -1, bridgeUnitId, 2, AiOrder.ATTACK);
		ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_CAPTURE);
		
		setEnemyBridgeSupportDefenderSquadIsDefending(0);
	end
end

function setDefendOrderForEnemyBridgeSupportDefenderSquad(defendUnitId)
	if(Unit:getUnitById(defendUnitId) ~= nil) then
		local defendX, defendY = Unit:getUnitById(defendUnitId):getX(), Unit:getUnitById(defendUnitId):getY();
		
		ScriptManager:addOrder(enemySquadIds.BRIDGE_SUPPORT_DEFENDER, defendX, defendY, defendUnitId, 2, AiOrder.DEFEND);
		setEnemyBridgeSupportDefenderSquadIsDefending(1);
	end
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getEnemyHqIsCapturedDestroyed()
	return enemyHqIsCapturedDestroyed;
end

function setEnemyHqIsCapturedDestroyed(bool)
	enemyHqIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyHqIsCapturedDestroyed", enemyHqIsCapturedDestroyed);
end

function getEnemyTankFactoryIsCapturedDestroyed()
	return enemyTankFactoryIsCapturedDestroyed;
end

function setEnemyTankFactoryIsCapturedDestroyed(bool)
	enemyTankFactoryIsCapturedDestroyed = bool;
	
	ScriptManager:storeValue("enemyTankFactoryIsCapturedDestroyed", enemyTankFactoryIsCapturedDestroyed);
end

function getEnemyMortarsDestroyed()
	return enemyMortarsDestroyed;
end

function setEnemyMortarsDestroyed(value)
	enemyMortarsDestroyed = value;
	
	if(enemyMortarsDestroyed >= ENEMY_MORTARS_TO_DESTROY) then
		enemyMortarsDestroyed = ENEMY_MORTARS_TO_DESTROY;
	end
	
	ScriptManager:storeValue("enemyMortarsDestroyed", enemyMortarsDestroyed);
end

function incrementEnemyMortarsDestroyed()
	setEnemyMortarsDestroyed(getEnemyMortarsDestroyed() + 1);
end

function getBridgesDestroyed()
	return bridgesDestroyed;
end

function setBridgesDestroyed(value)
	bridgesDestroyed = value;
	
	if(bridgesDestroyed >= BRIDGES_TO_DESTROY) then
		bridgesDestroyed = BRIDGES_TO_DESTROY;
	elseif(bridgesDestroyed <= 0) then
		bridgesDestroyed = 0;
	end
	
	ScriptManager:storeValue("bridgesDestroyed", bridgesDestroyed);
end

function incrementBridgesDestroyed()
	setBridgesDestroyed(getBridgesDestroyed() + 1);
end

function decrementBridgesDestroyed()
	setBridgesDestroyed(getBridgesDestroyed() - 1);
end

function getNorthernBridgeIsDestroyed()
	return northernBridgeIsDestroyed;
end

function setNorthernBridgeIsDestroyed(bool)
	northernBridgeIsDestroyed = bool;
	
	ScriptManager:storeValue("northernBridgeIsDestroyed", northernBridgeIsDestroyed);
end

function getCenterBridgeIsDestroyed()
	return centerBridgeIsDestroyed;
end

function setCenterBridgeIsDestroyed(bool)
	centerBridgeIsDestroyed = bool;
	
	ScriptManager:storeValue("centerBridgeIsDestroyed", centerBridgeIsDestroyed);
end

function getPlayerHasBridges()
	return playerHasBridges;
end

function setPlayerHasBridges(bool)
	playerHasBridges = bool;
	
	ScriptManager:storeValue("playerHasBridges", playerHasBridges);
end

function getEnemySupplyTruckUnitId()
	return enemySupplyTruckUnitId;
end

function setEnemySupplyTruckUnitId(value)
	enemySupplyTruckUnitId = value;
	
	ScriptManager:storeValue("enemySupplyTruckUnitId", enemySupplyTruckUnitId);
end

function getEnemySupplyTruckIsActive()
	return enemySupplyTruckIsActive;
end

function setEnemySupplyTruckIsActive(bool)
	enemySupplyTruckIsActive = bool;
	
	ScriptManager:storeValue("enemySupplyTruckIsActive", enemySupplyTruckIsActive);
end

function getEnemySupplyTruckIsOnSavePath()
	return enemySupplyTruckIsOnSavePath;
end

function setEnemySupplyTruckIsOnSavePath(bool)
	enemySupplyTruckIsOnSavePath = bool;
	
	ScriptManager:storeValue("enemySupplyTruckIsOnSavePath", enemySupplyTruckIsOnSavePath);
end

function getEnemySupplyTrucksSpawned()
	return enemySupplyTrucksSpawned;
end

function setEnemySupplyTrucksSpawned(value)
	enemySupplyTrucksSpawned = value;
	
	ScriptManager:storeValue("enemySupplyTrucksSpawned", enemySupplyTrucksSpawned);
end

function incrementEnemySupplyTrucksSpawned()
	setEnemySupplyTrucksSpawned(getEnemySupplyTrucksSpawned() + 1);
end

function decrementEnemySupplyTrucksSpawned()
	setEnemySupplyTrucksSpawned(getEnemySupplyTrucksSpawned() - 1);
end

function getEnemyTankWaveInitSquadId()
	return enemyTankWaveInitSquadId;
end

function setEnemyTankWaveInitSquadId(value)
	enemyTankWaveInitSquadId = value;
	
	ScriptManager:storeValue("enemyTankWaveInitSquadId", enemyTankWaveInitSquadId);
end

function getEnemyBridgeSupportSapperUnitId()
	return enemyBridgeSupportSapperUnitId;
end

function setEnemyBridgeSupportSapperUnitId(value)
	enemyBridgeSupportSapperUnitId = value;
	
	ScriptManager:storeValue("enemyBridgeSupportSapperUnitId", enemyBridgeSupportSapperUnitId);
end

function getEnemyBridgeSupportSapperIsActive()
	return enemyBridgeSupportSapperIsActive;
end

function setEnemyBridgeSupportSapperIsActive(bool)
	enemyBridgeSupportSapperIsActive = bool;
	
	ScriptManager:storeValue("enemyBridgeSupportSapperIsActive", enemyBridgeSupportSapperIsActive);
end

function getEnemyBridgeSupportSapperIsInRange()
	return enemyBridgeSupportSapperIsInRange;
end

function setEnemyBridgeSupportSapperIsInRange(bool)
	enemyBridgeSupportSapperIsInRange = bool;
	
	ScriptManager:storeValue("enemyBridgeSupportSapperIsInRange", enemyBridgeSupportSapperIsInRange);
end

function getEnemyBridgeSupportSapperFinishedRepair()
	return enemyBridgeSupportSapperFinishedRepair;
end

function setEnemyBridgeSupportSapperFinishedRepair(bool)
	enemyBridgeSupportSapperFinishedRepair = bool;
	
	ScriptManager:storeValue("enemyBridgeSupportSapperFinishedRepair", enemyBridgeSupportSapperFinishedRepair);
end

function getNumberOfEnemySapperSpawns()
	return numberOfEnemySapperSpawns;
end

function setNumberOfEnemySapperSpawns(value)
	numberOfEnemySapperSpawns = value;
	
	ScriptManager:storeValue("numberOfEnemySapperSpawns", numberOfEnemySapperSpawns);
end

function incrementNumberOfEnemySapperSpawns()
	setNumberOfEnemySapperSpawns(getNumberOfEnemySapperSpawns() + 1);
end

function getEnemyBridgeSupportDefenderSquadIsActive()
	return enemyBridgeSupportDefenderSquadIsActive;
end

function setEnemyBridgeSupportDefenderSquadIsActive(bool)
	enemyBridgeSupportDefenderSquadIsActive = bool;
	
	ScriptManager:storeValue("enemyBridgeSupportDefenderSquadIsActive", enemyBridgeSupportDefenderSquadIsActive);
end

function getEnemyBridgeSupportDefenderSquadIsDefending()
	return enemyBridgeSupportDefenderSquadIsDefending;
end

function setEnemyBridgeSupportDefenderSquadIsDefending(bool)
	enemyBridgeSupportDefenderSquadIsDefending = bool;
	
	ScriptManager:storeValue("enemyBridgeSupportDefenderSquadIsDefending", enemyBridgeSupportDefenderSquadIsDefending);
end

function getRoundOfReinforcementSpawnInit()
	return roundOfReinforcementSpawnInit;
end

function setRoundOfReinforcementSpawnInit(value)
	roundOfReinforcementSpawnInit = value;
	
	ScriptManager:storeValue("roundOfReinforcementSpawnInit", roundOfReinforcementSpawnInit);
end

function getRoundOfEnemyBridgeSupportDefenderSquadSpawnInit()
	return roundOfEnemyBridgeSupportDefenderSquadSpawnInit;
end

function setRoundOfEnemyBridgeSupportDefenderSquadSpawnInit(value)
	roundOfEnemyBridgeSupportDefenderSquadSpawnInit = value;
	
	ScriptManager:storeValue("roundOfEnemyBridgeSupportDefenderSquadSpawnInit", roundOfEnemyBridgeSupportDefenderSquadSpawnInit);
end

function getCutsceneForEnemySupplyTruckAppearanceShown()
	return cutsceneForEnemySupplyTruckAppearanceShown;
end

function setCutsceneForEnemySupplyTruckAppearanceShown(bool)
	cutsceneForEnemySupplyTruckAppearanceShown = bool;
	
	ScriptManager:storeValue("cutsceneForEnemySupplyTruckAppearanceShown", cutsceneForEnemySupplyTruckAppearanceShown);
end

function getCutsceneForEnemySapperRepairBridgeShown()
	return cutsceneForEnemySapperRepairBridgeShown
end

function setCutsceneForEnemySapperRepairBridgeShown(bool)
	cutsceneForEnemySapperRepairBridgeShown = bool;
	
	ScriptManager:storeValue("cutsceneForEnemySapperRepairBridgeShown", cutsceneForEnemySapperRepairBridgeShown);
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