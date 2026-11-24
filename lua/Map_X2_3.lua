require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

ROUND_OF_ENEMY_PARATROOPER_SPAWN_INIT = 3;
ROUND_OF_ENEMY_PLANE_WAVE_SPAWN_INIT = 0;
ROUND_OF_ENEMY_SUPPLY_DEPOT_SPAWN = 7;
ENEMY_PARATROOPER_INIT_SQUAD_ID = 50;
MAX_NUMBER_OF_ENEMY_PARATROOPER_SPAWNS = 15;
MAX_NUMBER_OF_PARATROOPER_SPAWNS_PER_TURN = 3;
ENEMY_UNITS_TO_DEFEAT_FOR_VICTORY = 30;
ENEMY_PLANE_WAVE_RESPAWN_INTERVAL = 2; --respawn rate after previous spawn was destroyed

-- mission stuff
missionIds = {
	holdBridge= 1,
	destroyAirfield = 2,
	destroyOutpost = 3,
	occupyBunkers = 4,
	denyCrossings = 5,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {	
	{missionIds.holdBridge,			true,		Text.T_CAMP_X_2_3_PRIMARY1, 100},
	{missionIds.destroyAirfield,	true,		Text.T_MISSION_DESTROY_AIRFIELD, 50},
	{missionIds.destroyOutpost,		true,		Text.T_MISSION_DESTROY_BASE, 50},
	{missionIds.occupyBunkers,		false,		Text.T_CAMP_X_2_3_SECONDARY1, 50},
	{missionIds.denyCrossings,		false,		Text.T_CAMP_X_2_3_SECONDARY2, 50},
};

enemySquadIds = {
	tanks1 = 20,
	tanks2 = 21,
	tanks3 = 22,
	
	startUnits = 24,
	enemyHQdefenders = 25,
	mgNestHQ = 26,
	
	HQtank = 27,
	
	airfieldDefenders = 28,
	
	planes1 = 40,
	planes2 = 41,
	planes3 = 42,
};

enemyParatroopers = {
	-- unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{Units.L_INFANTRY_MG,			5, 28,	10, 22},
	{Units.L_INFANTRY_MORTAR,		5, 28, 	10, 22},
	{Units.L_INFANTRY_AT,			5, 28, 	10, 22},
	{Units.L_INFANTRY_AT,			1, 18, 	8, 19},
	{Units.L_INFANTRY_MG,			1, 18, 	8, 19},
	{Units.L_INFANTRY_FLAME,		1, 18, 	8, 19},
	{Units.L_INFANTRY_MG,			1, 1, 	11, 14},
	{Units.L_INFANTRY_AT,			1, 1, 	11, 14},
	{Units.L_INFANTRY_FLAME,		1, 1, 	11, 14},
	{Units.L_INFANTRY_SNIPER,		8, 1, 	14, 11},
	{Units.L_INFANTRY_AT,			8, 1, 	14, 11},
	{Units.L_INFANTRY_MG,			8, 1, 	14, 11},
	{Units.L_INFANTRY_FLAME,		17, 1, 	19, 8},
	{Units.L_INFANTRY_SNIPER,		17, 1, 	19, 8},
	{Units.L_INFANTRY_MG,			17, 1, 	19, 8}
};

rubberBoatCoastTiles = {{9, 22}, {7, 19}, {10, 13}, {14, 10}, {18, 7}, {19, 7}};
rubberBoatWaterTiles = {{10, 22, 11, 23}, {8, 19, 11, 20}, {11, 14, 13, 16}, {14, 11, 15, 13}, {19, 8, 19, 11}};

tanks1 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{Units.L_TANK_LIGHT,  		8, 1, enemySquadIds.tanks1};
	{Units.L_TANK_MEDIUM, 		8, 1, enemySquadIds.tanks1};
};

tanks2 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{Units.L_TANK_DESTROYER,  	1, 1, enemySquadIds.tanks2};
	{Units.L_TANK_HEAVY, 		2, 1, enemySquadIds.tanks2};
};

tanks3 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{Units.L_TANK_HEAVY,  		1, 1, enemySquadIds.tanks3};
	{Units.L_TANK_LIGHT, 		2, 1, enemySquadIds.tanks3};
	{Units.L_TANK_DESTROYER, 	2, 2, enemySquadIds.tanks3};
};

planeWavesInProgress = 1;

enemyPlaneSquads = {
	{Units.L_PLANE_LIGHT,		5, 1, 13, 14, enemySquadIds.planes1};
	{Units.L_PLANE_HEAVY,		5, 1, 20, 21, enemySquadIds.planes2};
	{Units.L_PLANE_BOMBER,		5, 1, 14, 16, enemySquadIds.planes3};
};

riverBankTiles = {
	{ 11, 28 }, { 10, 27 }, { 10, 26 }, { 10, 25 }, { 11, 24 }, { 11, 23 }, { 11, 22 }, { 11, 21 }, { 11, 20 },
	{ 11, 19 }, { 12, 18 }, { 12, 17 }, { 13, 16 }, { 13, 15 }, { 14, 14 }, { 14, 13 }, { 15, 13 }, { 16, 12 },
	{ 16, 11 }, { 17, 10 }, { 18, 10 }, { 18, 11 }, { 19, 11 }, { 20, 11 }, { 21, 11 }, { 22, 12 } 
};


bunker1 = 4;
bunker2 = 5;
bunker3 = 9;
bunker4 = 6;
bunker5 = 7;

bridge = 0 ;

airfieldSouth = 1;

playerHQ = 2 ;
playerAirfield = 3;

bunkersToOccupy = 5;

paratrooperIdStart = 200;
paratroopersToDefeat = 30;

HQid = {};

enemyParatrooperSpawnIsActive = 0;
generatedParatrooperSquadId = ENEMY_PARATROOPER_INIT_SQUAD_ID;
enemyParatrooperSpawns = 0;
enemyUnitDestroyed = 0;

enemyPlaneWaveSpawnIsActive = 0;
enemyPlaneWaveIsAlive = 0;
roundOfEnemyPlaneWaveInit = -1;

-- BEGIN Init


function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold(PLAYER_ID, 1500);
	ScriptManager:setAiAttackPriority(Units.N_BRIDGE_L, 1, true);

	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("enemyParatrooperSpawnIsActive", enemyParatrooperSpawnIsActive);
	ScriptManager:storeValue("generatedParatrooperSquadId", generatedParatrooperSquadId);
	ScriptManager:storeValue("enemyParatrooperSpawns", enemyParatrooperSpawns);
	ScriptManager:storeValue("enemyUnitDestroyed", enemyUnitDestroyed);
	
	ScriptManager:storeValue("enemyPlaneWaveSpawnIsActive", enemyPlaneWaveSpawnIsActive);
	ScriptManager:storeValue("enemyPlaneWaveIsAlive", enemyPlaneWaveIsAlive);
	ScriptManager:storeValue("roundOfEnemyPlaneWaveInit", roundOfEnemyPlaneWaveInit);
end

function loadValues()
	enemyParatrooperSpawnIsActive = ScriptManager:getValue("enemyParatrooperSpawnIsActive");
	generatedParatrooperSquadId = ScriptManager:getValue("generatedParatrooperSquadId");
	enemyParatrooperSpawns = ScriptManager:getValue("enemyParatrooperSpawns");
	enemyUnitDestroyed = ScriptManager:getValue("enemyUnitDestroyed");
	
	enemyPlaneWaveSpawnIsActive = ScriptManager:getValue("enemyPlaneWaveSpawnIsActive");
	enemyPlaneWaveIsAlive = ScriptManager:getValue("enemyPlaneWaveIsAlive");
	roundOfEnemyPlaneWaveInit = ScriptManager:getValue("roundOfEnemyPlaneWaveInit");
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	ScriptManager:addOnTurnStartTrigger(PLAYER_ID, -1, 2, "prepareAirfieldCutscene", "prepareAirfieldCutscene");
	ScriptManager:addOnTurnStartTrigger(PLAYER_ID, 2, -1, "prepareBunkerMissionCutscene", "prepareBunkerMissionCutscene");
	-- triggers for bunker mission
	ScriptManager:addOnUnitOccupiedTrigger(PLAYER_ID, -1, -1, "onBunkerOccupied", "onBunkerOccupied");
	ScriptManager:addOnUnitUnloadedTrigger(PLAYER_ID, -1, -1, "onUnitUnloadedFromBunker", "onUnitUnloadedFromBunker");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_EMPLACEMENT_BUNKER, -1, "onBunkerDestroyed", "onBunkerDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "onBunkerDestroyed", "onBunkerDestroyed");
	
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnAiCalculationTrigger(false, "onAiCalculated", "onAiCalculated");
	ScriptManager:addOnUnitUnloadedTrigger(AI_ID, -1, -1, "onEnemyUnloaded", "onEnemyUnloaded");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, -1, -1, "onEnemyUnitDestroyed", "onEnemyUnitDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.X_BUILDING_AIRFIELD, airfieldSouth, "onAirfieldDestroyed", "onAirfieldDestroyed");
	
	for i = 1, #riverBankTiles do
		ScriptManager:addOnEnterTileTrigger(riverBankTiles[i][1], riverBankTiles[i][2], AI_ID, -1, -1, false, "onRiverBankEntered", "onRiverBankEntered");
	end
	
	-- when an enemy unit (infantry) reaches a tile close to the river bank 
	for y = 7, 30 do
		for x = 6, 23 do
			ScriptManager:addOnEnterTileTrigger(x, y, 1, -1, -1, false, "onUnitsApproachRiverBank", "onUnitsApproachRiverBank", false);
		end
	end
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, Units.X_BUILDING_HQ, -1, "showAttackedWarning", "showAttackedWarning");
	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, Units.N_BRIDGE_L, -1, "stopAttackingHint",	"stopAttackingHint");
	ScriptManager:addOnUnitCapturedTrigger(-1, Units.N_BRIDGE_L, -1, "transitionToFail", "transitionToFail");
	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, Units.X_BUILDING_HQ , -1, "transitionToFail", "transitionToFail");
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BRIDGE_L , -1, "transitionToFail", "transitionToFail");
end

function onEnemyUnitDestroyed(unit)
	if(unit:getTemplateId() ~= Units.L_BUILDING_AIRFIELD) and
		(unit:getTemplateId() ~= Units.N_BUILDING_CRATES) and
		(unit:getTemplateId() ~= Units.L_BUILDING_HQ) then
		incrementEnemyUnitDestroyed();
		
		if(getEnemyUnitDestroyed() >= ENEMY_UNITS_TO_DEFEAT_FOR_VICTORY) then
			ScriptManager:removeTrigger("onEnemyUnitDestroyed");
			
			setEnemyParatrooperSpawnIsActive(0);
			
			local orderId = ScriptManager:addOrder(enemySquadIds.planes1, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			
			local orderId = ScriptManager:addOrder(enemySquadIds.planes2, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			
			local orderId = ScriptManager:addOrder(enemySquadIds.planes3, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

			checkForVictory();
		end
	end
end

function onEnemyTurnStart(playerId, turnId, roundId)
	if(ScriptManager:getCurrentRound() == ROUND_OF_ENEMY_PARATROOPER_SPAWN_INIT) then
		setEnemyParatrooperSpawnIsActive(1);
	elseif(ScriptManager:getCurrentRound() == ROUND_OF_ENEMY_PLANE_WAVE_SPAWN_INIT) then
		setEnemyPlaneWaveSpawnIsActive(1);
	elseif(ScriptManager:getCurrentRound() == ROUND_OF_ENEMY_SUPPLY_DEPOT_SPAWN) then
		buildEnemyOutpost();
	end
	
	if(getEnemyParatrooperSpawnIsActive() == 1) then
		if(getEnemyParatrooperSpawns() <= MAX_NUMBER_OF_ENEMY_PARATROOPER_SPAWNS) then
			local rnd = math.random(1, MAX_NUMBER_OF_PARATROOPER_SPAWNS_PER_TURN);
			
			for i = 1, rnd do
				spawnEnemyParatrooper();
			end
		else
			setEnemyParatrooperSpawnIsActive(0);
		end
	end
	
	if(getEnemyPlaneWaveSpawnIsActive() == 1) then
		if(getEnemyPlaneWaveIsAlive() == 0) then
			if(ScriptManager:getCurrentRound() >= getRoundOfEnemyPlaneWaveInit() + ENEMY_PLANE_WAVE_RESPAWN_INTERVAL) then
				spawnEnemyPlaneWave();
				setEnemyPlaneWaveIsAlive(1);
				setRoundOfEnemyPlaneWaveInit(ScriptManager:getCurrentRound());
			end
		end
	end
end

function onEnemySquadDestroyed(squadId)
	if(squadId >= enemySquadIds.planes1) and (squadId <= enemySquadIds.planes3) then
		setEnemyPlaneWaveIsAlive(0);
		setRoundOfEnemyPlaneWaveInit(ScriptManager:getCurrentRound());
	end
end

function onUnitsApproachRiverBank( tileX, tileY, playerId, unitTemplateId, unitInstanceId, stopUnit, callbackName, triggerId, hasSmoke )
	if(unitTemplateId >= Units.L_INFANTRY_MG) and
		(unitTemplateId <= Units.L_ARTILLERY_HOWITZER) then
		ScriptManager:removeTrigger("onUnitsApproachRiverBank");
		
		local unit = Unit:getUnitById( unitInstanceId ):getId();
		ScriptManager:storeValue("riverbankUnit", unit);
		ScriptManager:runForPlayer(PLAYER_ID, "prepareRiverbankCutscene")
	end
end

function onRiverBankEntered(tileX, tileY, playerId, unitTemplateId, unitInstanceId, stopUnit, callbackName, triggerId, hasSmoke)
	if(unitTemplateId >= Units.L_INFANTRY_MG) and
		(unitTemplateId <= Units.L_ARTILLERY_HOWITZER) then
		ScriptManager:removeTrigger("onRiverBankEntered");
		
		local unit = Unit:getUnitById( unitInstanceId ):getId();
		ScriptManager:storeValue("unitEnteredRiverbank", unit);
		ScriptManager:runForPlayer(PLAYER_ID, "prepareRiverCrossedCutscene");
	end
end

function onEnemyUnloaded(transporterUnit, transportedUnit)
	if(transportedUnit ~= nil) then
		if(transportedUnit:getTemplateId() >= Units.L_INFANTRY_MG) and (transportedUnit:getTemplateId() <= Units.L_INFANTRY_SNIPER) then
			--print("#################################################################################################_____UNLOADED!");
			local currentSquadId = transportedUnit:getSquadId();
			ScriptManager:removeAllOrders(currentSquadId);
			
			local currentOrder = ScriptManager:addOrder(currentSquadId, 20, 21, -1, 2, AiOrder.MOVE);
			ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_HOLD_FIRE);
		end
	end
end

function onAiCalculated(squadId, currentOrderMessageData, allOrderMessageData)
	if(squadId >= ENEMY_PARATROOPER_INIT_SQUAD_ID) then
		local tmp = ScriptManager:getSquadUnits(squadId);
		
		for i = 0, tmp:count() - 1 do
			local currentUnit = tolua.cast(tmp:objectAtIndex(i), "Unit");
			local currentUnitId = currentUnit:getId();
			local currentX, currentY = currentUnit:getX(), currentUnit:getY();
			
			if(checkForRuberBoatCoastTile(currentX, currentY) == true) then
				local transformX, transformY = getNeighbouringRubberBoatTile(currentX, currentY);
				ScriptManager:removeAllOrders(squadId);
				
				if(transformX ~= -1) and (transformY ~= -1) then
					if(Unit:getUnitAt(transformX, transformY) == nil) then
						--print("#########################################################################################_____TRANSFORM: %i, %i", transformX, transformY)
						local orderX, orderY = getNearestOrderTile(transformX, transformY);
						ScriptManager:transformUnit(currentUnitId,transformX, transformY, 0, true);
						local currentOrder = ScriptManager:addOrder(squadId, orderX, orderY, -1, 1, AiOrder.MOVE);
						ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD);
					end
				end
			end
		end
	end
end

function onBunkerOccupied(transporterUnit, transportedUnit)
	if(transporterUnit:getTemplateId() == Units.N_EMPLACEMENT_BUNKER) or
		(transporterUnit:getTemplateId() == Units.N_EMPLACEMENT_BUNKERTOWER) then
		if(ScriptManager:getMissionStatus(missionIds.occupyBunkers) ~= MissionStatus.FAILED) and
			(ScriptManager:getMissionStatus(missionIds.occupyBunkers) ~= MissionStatus.ACCOMPLISHED) then	
			Utils:incrementMissionProgress(missionIds.occupyBunkers);
			prepareBunkerOccupiedMissionProgress();
		end
	end
end

function onUnitUnloadedFromBunker(transporterUnit, transportedUnit)
	if(transporterUnit:getTemplateId() == Units.N_EMPLACEMENT_BUNKER) or
		(transporterUnit:getTemplateId() == Units.N_EMPLACEMENT_BUNKERTOWER) then
		Utils:decrementMissionProgress(missionIds.occupyBunkers);
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.occupyBunkers), bunkersToOccupy, Text.T_CAMP_X2_3_SECONDARY1_COUNTER);
	end
end

function onBunkerDestroyed()
	ScriptManager:removeTrigger("onBunkerDestroyed");
	Utils:setMissionStatus( missionIds.occupyBunkers, MissionStatus.FAILED );		
end

function onAirfieldDestroyed()
	ScriptManager:removeTrigger("onAirfieldDestroyed");
	setEnemyPlaneWaveSpawnIsActive(0);
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X_2_3_PRIMARY2_FLAVOR2, 5); 
	
	Utils:endCutscene();

	ScriptManager:setMissionStatus(missionIds.destroyAirfield, MissionStatus.ACCOMPLISHED);
	
	local orderId = ScriptManager:addOrder(enemySquadIds.airfieldDefenders, -1, -1, bridge, 3, AiOrder.ATTACK);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_CAPTURE);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	
	checkForVictory();
end

function onEnemyHQdestroyed()
	ScriptManager:removeTrigger("onEnemyHQdestroyed");
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_PRIMARY3_FLAVOR4, 5 );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.destroyOutpost, MissionStatus.ACCOMPLISHED );
	
	checkForVictory();
end

function checkForRuberBoatCoastTile(posX, posY)
	for i = 1, #rubberBoatCoastTiles do
		if(posX == rubberBoatCoastTiles[i][1]) and (posY == rubberBoatCoastTiles[i][2]) then
			return true;
		end
	end
	
	return false;
end

function getNeighbouringRubberBoatTile(posX, posY)
	for i = 1, #rubberBoatWaterTiles do
		if((posX >= rubberBoatWaterTiles[i][1] - 1) and (posX <= rubberBoatWaterTiles[i][1] + 1)) and
			((posY >= rubberBoatWaterTiles[i][2] - 1) and (posY <= rubberBoatWaterTiles[i][2] + 1)) then
			--print("####################################################################_______TILE FOUND: %i, %i", rubberBoatWaterTiles[i][1], rubberBoatWaterTiles[i][2]);
			return rubberBoatWaterTiles[i][1], rubberBoatWaterTiles[i][2];
		end
	end
	--print("####################################################################_______TILE NOT FOUND");
	return -1, -1;
end

function getNearestOrderTile(posX, posY)
	for i = 1, #rubberBoatWaterTiles do
		if((posX == rubberBoatWaterTiles[i][1]) and (posY == rubberBoatWaterTiles[i][2]))then
			return rubberBoatWaterTiles[i][3], rubberBoatWaterTiles[i][4];
		end
	end
	
	return -1, -1;
end

function checkForParatrooperOrder(squadId)
	if(ScriptManager:getSquadOrderCount(squadId) == 0) then
		return true;
	end
	
	return false;
end

function spawnEnemyParatrooper()
	local rnd = math.random(1, #enemyParatroopers);
	
	ScriptManager:spawnUnit(AI_ID, enemyParatroopers[rnd][1], enemyParatroopers[rnd][2], enemyParatroopers[rnd][3], getGeneratedParatrooperSquadId());
	
	local currentOrder = ScriptManager:addOrder(getGeneratedParatrooperSquadId(),enemyParatroopers[rnd][4], enemyParatroopers[rnd][5], -1, 1, AiOrder.MOVE);
	ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_HOLD_FIRE);
	
	incrementGeneratedParatrooperSquadId();
	incrementEnemyParatrooperSpawns();
end

function spawnEnemyPlaneWave()
	local rnd = math.random(1, #enemyPlaneSquads);
	ScriptManager:spawnUnit(AI_ID, enemyPlaneSquads[rnd][1], enemyPlaneSquads[rnd][2], enemyPlaneSquads[rnd][3], enemyPlaneSquads[rnd][6]);
	
	local currentOrder = ScriptManager:addOrder(enemyPlaneSquads[rnd][6], enemyPlaneSquads[rnd][4], enemyPlaneSquads[rnd][5], -1, 4, AiOrder.ATTACK);
	ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	ScriptManager:enableOrderFlag(currentOrder, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK);
end

function addAiOrders()

end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	local MG = ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 5, 2, -1 ):getId();
--	local flame = ScriptManager:spawnUnit( 0, Units.X_INFANTRY_FLAME, 5, 3, -1 ):getId();
	local truck = ScriptManager:spawnUnit( 0, Units.X_TRUCK_TRANSPORT, 4, 3, -1 ):getId();	
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X_2_3_INTRO_FLAVOR1 );
	
	ScriptManager:moveCameraEx( 2, 11, 0.7, 3, true );
	ScriptManager:revealFogOfWar( 3, 12, 1, true );
	ScriptManager:revealFogOfWar( 1, 11, 1, true );
	ScriptManager:wait( 1 );
	ScriptManager:runAbility( 1, Units.L_INFANTRY_MG, paratrooperIdStart + 1, GlobalAbility.PARATROOPER, 3, 12, enemySquadIds.startUnits );
	ScriptManager:wait( 3 );
	ScriptManager:runAbility( 1, Units.N_BUILDING_CRATES, -1, GlobalAbility.SUPPLY_CRATE, 1, 11, -1 );
	ScriptManager:wait( 3 );
	ScriptManager:revealFogOfWar( 1, 11, 1, false );
	ScriptManager:revealFogOfWar( 3, 12, 1, false );

	ScriptManager:moveCameraEx( 8, 3, 0.7, 2, true );
	ScriptManager:revealFogOfWar( 8, 3, 1, true );
	ScriptManager:wait( 1 );
	ScriptManager:runAbility( 1, Units.L_INFANTRY_AT, paratrooperIdStart + 1, GlobalAbility.PARATROOPER, 8, 3, enemySquadIds.startUnits );
	ScriptManager:wait( 3 );
	ScriptManager:revealFogOfWar( 8, 3, 1, false ); 
	
	ScriptManager:moveCameraEx( 15, 3, 0.7, 2, true );	
	ScriptManager:revealFogOfWar( 15, 3, 1, true );
	ScriptManager:wait( 1 );
	ScriptManager:runAbility( 1, Units.L_INFANTRY_MORTAR, paratrooperIdStart + 1, GlobalAbility.PARATROOPER, 15, 3, enemySquadIds.startUnits );
	ScriptManager:wait( 3 );
	ScriptManager:runAbility( 1, Units.L_INFANTRY_MG, paratrooperIdStart + 1, GlobalAbility.PARATROOPER, 16, 2, enemySquadIds.startUnits );
	ScriptManager:wait( 3 );
	ScriptManager:revealFogOfWar( 15, 3, 1, false );
	
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:moveCameraEx( 3, 3, 0.7, 2, true );
	ScriptManager:revealFogOfWar( 3, 3, 3, true );
	
	local tank = ScriptManager:spawnUnit( 1, Units.L_TANK_LIGHT, 1, 1, enemySquadIds.startUnits ):getId();
	local infantryMG = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 1, 2, enemySquadIds.startUnits ):getId();
	local infantryMortar = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MORTAR, 2, 1, enemySquadIds.startUnits ):getId();
	
	ScriptManager:attackUnitEx( tank, truck, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_INTRO_FLAVOR2, 4 );
	ScriptManager:loadUnitIntoTransporterEx( truck, MG, true );
	ScriptManager:wait( 2 );
			
		
	ScriptManager:moveUnitEx( truck, 10, 9, true );
	ScriptManager:wait( 3 );
	ScriptManager:moveUnitEx( infantryMG, 4, 1, true );
	ScriptManager:wait( 1 );
	ScriptManager:moveUnitEx( infantryMortar, 4, 2, true );
	
	ScriptManager:moveUnitEx( tank, 5, 2, true );
	
--	local airfield = Unit:getUnitById( airfieldSouth ):getId();	
	ScriptManager:captureUnit( tank, airfieldSouth, "" );

	ScriptManager:wait( 1 );

	Unit:getUnitById( airfieldSouth ):setCanBeCaptured( false );


	ScriptManager:moveCameraEx( 12, 13, 0.7, 3, true );
	
	ScriptManager:showScaledMarkerAt( 12, 13, 1.5, true, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_INTRO_FLAVOR3, 5 );

	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_INTRO_FLAVOR4, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_INTRO_FLAVOR5, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_INTRO_FLAVOR6, 6 );
	
	Utils:hideAllMarkers();
	
	ScriptManager:revealFogOfWar( 3, 3, 3, false );
		
	ScriptManager:spawnUnit( 1, Units.L_TANK_MEDIUM, 6, 1, enemySquadIds.airfieldDefenders );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 7, 2, enemySquadIds.airfieldDefenders );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT, 6, 3, enemySquadIds.airfieldDefenders );
	ScriptManager:spawnUnit( 1, Units.L_ARTILLERY_AA, 5, 3, enemySquadIds.airfieldDefenders );	
		
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	local orderId = ScriptManager:addOrder( enemySquadIds.startUnits, -1, -1, bridge, 4, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );

	orderId = ScriptManager:addOrder( enemySquadIds.airfieldDefenders, -1, -1, airfieldSouth, 3, AiOrder.DEFEND );
	
	ScriptManager:spawnUnit( 1, Units.L_TANK_MEDIUM, 2, 2, enemySquadIds.startUnits );
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.holdBridge, MissionStatus.IN_PROGRESS );
	Utils:enablePlayerInteraction();
end


function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN
-- insert missionstuff here

function prepareBunkerMissionCutscene()
	table.insert( queueTable, startBunkerMission );
	Utils:cutsceneQueue();
end

function startBunkerMission()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY1_FLAVOR1, 5 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X2_3_SECONDARY1_FLAVOR2 ); 
	
	ScriptManager:revealFogOfWar( 11, 25, 1, true );
	ScriptManager:revealFogOfWar( 12, 22, 1, true );
	ScriptManager:revealFogOfWar( 10, 16, 1, true );
	ScriptManager:revealFogOfWar( 17, 12, 1, true );
	ScriptManager:revealFogOfWar( 20, 11, 1, true );
	
	ScriptManager:moveCameraEx( 11, 23, 1, 3, true );	
	ScriptManager:wait( 1 );
	ScriptManager:moveCameraEx( 10, 16, 1, 2, true );
	ScriptManager:wait( 1 );
	ScriptManager:moveCameraEx( 18, 11, 1, 2, true );
	ScriptManager:wait( 3 );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:revealFogOfWar( 11, 25, 1, false );
	ScriptManager:revealFogOfWar( 12, 22, 1, false );
	ScriptManager:revealFogOfWar( 10, 16, 1, false );
	ScriptManager:revealFogOfWar( 17, 12, 1, false );
	ScriptManager:revealFogOfWar( 20, 11, 1, false );
	
	ScriptManager:moveCameraEx( 13, 14, 0.7, 2, true );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.occupyBunkers, MissionStatus.IN_PROGRESS );
end
	
function prepareBunkerOccupiedMissionProgress()
	table.insert( queueTable, showBunkerOccupiedMissionProgress );
	Utils:cutsceneQueue();
end
	
function showBunkerOccupiedMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.occupyBunkers ) >= bunkersToOccupy then
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 3 ); --"Well done {PLAYERRANK}!"
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY1_FLAVOR3, 5 );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.occupyBunkers, MissionStatus.ACCOMPLISHED );
	
	ScriptManager:removeTrigger("onBunkerOccupied");
	ScriptManager:removeTrigger("onUnitUnloadedFromBunker");
	else
	Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress( missionIds.occupyBunkers), bunkersToOccupy, Text.T_CAMP_X2_3_SECONDARY1_COUNTER );
	end
end

function prepareRiverbankCutscene()
	table.insert( queueTable, startRiverbankCutscene );
	Utils:cutsceneQueue();
end

function startRiverbankCutscene()
	Utils:startCutscene();
	
	local riverbankUnit = Unit:getUnitById(ScriptManager:getValue("riverbankUnit"));
	
	ScriptManager:wait( 1 );
	
	local transUnit = riverbankUnit:getTransporterUnit(); 
	local tX = riverbankUnit:getX();
	local tY = riverbankUnit:getY();
	if transUnit ~= nil then
		tX = transUnit:getX();
		tY = transUnit:getY();
	end
		
	ScriptManager:moveCameraEx( tX, tY, 0.7, 3, true );
	
	ScriptManager:wait( 0.5 );
	
	ScriptManager:revealFogOfWar( riverbankUnit:getX(), riverbankUnit:getY(), 1, true );
	ScriptManager:wait( 1 )
	ScriptManager:showMarkerAt( riverbankUnit:getX(), riverbankUnit:getY(), true, false );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY2_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY2_FLAVOR2, 6 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY2_FLAVOR3, 5 );
	
	Utils:hideAllMarkers();
	
	ScriptManager:wait( 2 );
	
	ScriptManager:revealFogOfWar( riverbankUnit:getX(), riverbankUnit:getY(), 1, false );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.denyCrossings, MissionStatus.IN_PROGRESS );
end
	 
function prepareRiverCrossedCutscene()
	table.insert( queueTable, startRiverCrossedCutscene );
	Utils:cutsceneQueue();
end 

function startRiverCrossedCutscene()
	
	local unit = Unit:getUnitById( ScriptManager:getValue("unitEnteredRiverbank") );
	
	Utils:startCutscene();
	 
	ScriptManager:moveCameraEx( unit:getX(), unit:getY(), 0.7, 3, true );
	 
	ScriptManager:revealFogOfWar( unit:getX(), unit:getY(), 1, true );
	 
	ScriptManager:showMarkerAt( unit:getX(), unit:getY(), true, false );
	 
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_SECONDARY2_FLAVOR5, 4 );
	 
	Utils:hideAllMarkers();
	 
	ScriptManager:wait( 2 );
	 
	ScriptManager:revealFogOfWar( unit:getX(), unit:getY(), 1, false );
	 
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.denyCrossings, MissionStatus.FAILED );
	
end

function buildEnemyOutpost()
	ScriptManager:removeTrigger("buildEnemyOutpost");
	ScriptManager:runForPlayer(PLAYER_ID, "buildEnemyOutpostCutscene");
end

function buildEnemyOutpostCutscene()
	Utils:startCutscene();

	-- load an engineer into a transport truck
	local truckTransport = ScriptManager:spawnUnit( 1, Units.L_TRUCK_TRANSPORT, 1, 18, enemySquadIds.enemyHQdefenders ):getId();

	print( "************************************************************************************************************************truckTransport: %i", truckTransport );


	local infantry = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 1, 17, enemySquadIds.enemyHQdefenders ):getId();
	
	ScriptManager:loadUnitIntoTransporterEx( truckTransport, infantry, true );

	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_PRIMARY3_FLAVOR1, 3 );

	ScriptManager:moveCameraEx( 3, 18, 0.7, 3, true );
	ScriptManager:revealFogOfWar( 3, 18, 2, true );
	ScriptManager:wait( 1 );
	
	ScriptManager:moveUnitEx( truckTransport, 3, 19, true );

	ScriptManager:wait( 1 );
	ScriptManager:unloadUnitFromTransporterEx( truckTransport, infantry, 2, 19, true );
	ScriptManager:fortifyUnit( infantry, true ); 
	
	ScriptManager:wait( 2 );
	
	local HQ = ScriptManager:spawnUnit( 1, Units.L_BUILDING_HQ, 3, 20, -1 ):getId();
	
	ScriptManager:storeValue("HQ",HQ)	
	
--	Utils:saveValuesIntoSavefileForEmptyTable( HQ, HQid );

--TODO
	
	Unit:getUnitById( HQ ):setCanBeCaptured( false );
		
	ScriptManager:wait( 2 );
		
--	ScriptManager:wait( 2 );
	-- transform component truck AA = 0
	-- transform component truck MG = 1

	ScriptManager:transformUnit( truckTransport, -1, -1, 1, true );
	
	ScriptManager:wait( 2 );

	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_PRIMARY3_FLAVOR2, 6 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_PRIMARY3_FLAVOR3, 5 );
	
	ScriptManager:revealFogOfWar( 3, 18, 2, false );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.destroyOutpost, MissionStatus.IN_PROGRESS );
		
	-- when the enemy command post is destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_BUILDING_HQ, -1, "onEnemyHQdestroyed", "onEnemyHQdestroyed" );
	
		
	ScriptManager:spawnUnit( 1, Units.L_ARTILLERY_AA, 2, 21, enemySquadIds.enemyHQdefenders );
	local tank = ScriptManager:spawnUnit( 1, Units.L_TANK_MEDIUM, 2, 20, enemySquadIds.HQtank );

	local orderId = ScriptManager:addOrder( enemySquadIds.enemyHQdefenders, -1, -1, ScriptManager:getValue("HQ"), 3, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.HQtank, -1, -1, ScriptManager:getValue("HQ"), 5, AiOrder.DEFEND );
		
	orderId = ScriptManager:addOrder( enemySquadIds.mgNestHQ, 3, 19, -1, 3, AiOrder.DEFEND );
end

function prepareAirfieldCutscene()
	table.insert( queueTable, playAirfieldCutscene );
	Utils:cutsceneQueue();
end

function playAirfieldCutscene()
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 6, 2, 0.7, 3, true );
	
	ScriptManager:wait( 1 );
	
	ScriptManager:revealFogOfWar( 6, 2, 1, true );
	
	ScriptManager:wait( 1 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_3_PRIMARY2_FLAVOR1, 4 );
		
	ScriptManager:revealFogOfWar( 6, 2, 1, false );
		
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.destroyAirfield, MissionStatus.IN_PROGRESS );
end
--[[
function spawnTanks1()
	for i = 1, #tanks1 do
	Utils:spawnUnitFromTable( tanks1 );
	end
	local orderId = ScriptManager:addOrder( enemySquadIds.tanks1, -1, -1, bridge, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

		
		local unit = Unit:getUnitById( bridge ):getPlayerId();
		
		if unit:getPlayerId() == 1 then
			local orderId = ScriptManager:addOrder( enemySquadIds.tanks1, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
end

function spawnTanks2()
	for i = 1, #tanks2 do
	Utils:spawnUnitFromTable( tanks2 );
	end
	
	local orderId = ScriptManager:addOrder( enemySquadIds.tanks2, -1, -1, bridge, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );


		local unit = Unit:getUnitById( bridge ):getPlayerId();
		
		if unit:getPlayerId() == 1 then
			local orderId = ScriptManager:addOrder( enemySquadIds.tanks2, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
end

function spawnTanks3()
	for i = 1, tanks3 do
	Utils:spawnUnitFromTable( tanks3 );
	end
	
	local orderId = ScriptManager:addOrder( enemySquadIds.tanks3, -1, -1, bridge, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

		local unit = Unit:getUnitById( bridge ):getPlayerId();
		
		if unit:getPlayerId() == 1 then
			local orderId = ScriptManager:addOrder( enemySquadIds.tanks3, -1, -1, playerHQ, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
end
--]]

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.destroyAirfield) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.destroyOutpost) == MissionStatus.ACCOMPLISHED) then
		Utils:missionCheckerAccomplish(missionIds.holdBridge);
		
		if(ScriptManager:getMissionStatus(missionIds.denyCrossings) ~= MissionStatus.FAILED) then
			Utils:missionCheckerAccomplish(missionIds.denyCrossings);
		end

		ScriptManager:runForPlayer(PLAYER_ID, "queueVictoryCutscene");
	end
end

-- END
-- BEGIN Victory

function queueVictoryCutscene()
	table.insert(queueTable, startVictoryCutscene);
	Utils:cutsceneQueue();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:revealFogOfWar( 12, 13, 2, true );
	ScriptManager:moveCameraEx( 12, 13, 1, 3, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_VICTORY_FLAVOR1, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_VICTORY_FLAVOR2, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_3_VICTORY_FLAVOR3, 4 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end

-- END Victory
-- BEGIN Defeated

function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );
end

function transitionToFail()
	ScriptManager:runForPlayer( 0, "missionFailed" );
end

function missionFailed()
	Utils:disablePlayerInteraction();
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle( Text.T_MISSION_FAILED );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


function getEnemyParatrooperSpawnIsActive()
	return enemyParatrooperSpawnIsActive;
end

function setEnemyParatrooperSpawnIsActive(bool)
	enemyParatrooperSpawnIsActive = bool;
	
	ScriptManager:storeValue("enemyParatrooperSpawnIsActive", enemyParatrooperSpawnIsActive);
end

function getGeneratedParatrooperSquadId()
	return generatedParatrooperSquadId;
end

function setGeneratedParatrooperSquadId(value)
	generatedParatrooperSquadId = value;
	
	ScriptManager:storeValue("generatedParatrooperSquadId", generatedParatrooperSquadId);
end

function incrementGeneratedParatrooperSquadId()
	setGeneratedParatrooperSquadId(getGeneratedParatrooperSquadId() + 1);
end

function getEnemyParatrooperSpawns()
	return enemyParatrooperSpawns;
end

function setEnemyParatrooperSpawns(value)
	enemyParatrooperSpawns = value;
	
	ScriptManager:storeValue("enemyParatrooperSpawns", enemyParatrooperSpawns);
end

function incrementEnemyParatrooperSpawns()
	setEnemyParatrooperSpawns(getEnemyParatrooperSpawns() + 1);
end

function getEnemyUnitDestroyed()
	return enemyUnitDestroyed;
end

function setEnemyUnitDestroyed(value)
	enemyUnitDestroyed = value;
	
	ScriptManager:storeValue("enemyUnitDestroyed", enemyUnitDestroyed);
end

function incrementEnemyUnitDestroyed()
	setEnemyUnitDestroyed(getEnemyUnitDestroyed() + 1);
end

function getEnemyPlaneWaveSpawnIsActive()
	return enemyPlaneWaveSpawnIsActive;
end

function setEnemyPlaneWaveSpawnIsActive(bool)
	enemyPlaneWaveSpawnIsActive = bool;
	
	ScriptManager:storeValue("enemyPlaneWaveSpawnIsActive", enemyPlaneWaveSpawnIsActive);
end

function getEnemyPlaneWaveIsAlive()
	return enemyPlaneWaveIsAlive;
end

function setEnemyPlaneWaveIsAlive(bool)
	enemyPlaneWaveIsAlive = bool;
	
	ScriptManager:storeValue("enemyPlaneWaveIsAlive", enemyPlaneWaveIsAlive);
end

function getRoundOfEnemyPlaneWaveInit()
	return roundOfEnemyPlaneWaveInit;
end

function setRoundOfEnemyPlaneWaveInit(value)
	roundOfEnemyPlaneWaveInit = value;
	
	ScriptManager:storeValue("roundOfEnemyPlaneWaveInit", roundOfEnemyPlaneWaveInit);
end

-- END Defeated