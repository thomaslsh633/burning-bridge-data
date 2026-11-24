require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

PLAYER_ID = 0;
AI_ID = 1;

AIRFIELD_EAST_UNIT_ID = 4;
AIRFIELD_WEST_UNIT_ID = 3;
AIRFIELD_NORTH_UNIT_ID = 2;
AIRFIELD_SOUTH_UNIT_ID = 1;
BUNKER_AIRFIELD_EAST_UNIT_ID = 10;
PLAYER_HQ_UNIT_ID = 0;
PLAYER_TANK_FACTORY_UNIT_ID = 6;

MAX_NUMBER_OF_ROUNDS_BETWEEN_ENEMY_RECONNAISSANCE_SPAWN = 5;
AIRFIELD_CARGO = 30;
AIRFIELDS_TO_RESUPPLY = 3;
MAX_NUMBER_OF_PLANES_TO_DESTROY = 15;
ENEMY_SCOUTS_TO_DESTROY	= 4;
ENEMY_RECONNAISSANCE_SQUADS_TO_DESTROY = 4;
PLANE_WAVE_RESPAWN_INTERVAL = 1; -- defines how often waves will spawn

-- mission stuff
missionIds = {
	RESUPPLY_AIRFIELDS = 1,
	PROTECT_OWN_BUILDINGS = 2,
	DESTROY_ENEMY_PATROLS = 3,
	DESTROY_SCOUTS = 4
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.RESUPPLY_AIRFIELDS, true, Text.T_CAMP_X_2_1_PRIMARY1, 50},
	{missionIds.PROTECT_OWN_BUILDINGS, true, Text.T_CAMP_X_2_1_PRIMARY2, 100},
	{missionIds.DESTROY_ENEMY_PATROLS, true, Text.T_CAMP_X_2_1_PRIMARY3, 100},
	{missionIds.DESTROY_SCOUTS, false, Text.T_CAMP_X_2_1_SECONDARY1, 50},
};

enemySquadIds = {
	reconnaissancePatrolOne = 1;
	reconnaissancePatrolTwo = 2;
	reconnaissancePatrolThree = 3;
	reconnaissancePatrolFour = 4;
	
	spyBalloons = 5;
	
	planeWave1 = 6;
	planeWave2 = 7;
	planeWave3 = 8;
	planeWave4 = 9;
	planeWave5 = 10;
	planeWaveAirfield = 11;
	
	airfieldDefenders = 12;
	villageDefenders = 13;
	bridgeDefenders = 14;
	woodDefenders = 15;
	
	patrolAA = 16;
	
	bunkerAirfield = 50;
};

enemyScoutPlanes = {
	{Units.L_PLANE_SCOUT, 				5, 7, enemySquadIds.spyBalloons},
	{Units.L_PLANE_SCOUT, 				12, 15, enemySquadIds.spyBalloons},
	{Units.L_PLANE_SCOUT, 				13, 8, enemySquadIds.spyBalloons},
	{Units.L_PLANE_SCOUT, 				20, 15, enemySquadIds.spyBalloons},
	{Units.L_PLANE_SCOUT, 				21, 6, enemySquadIds.spyBalloons},
}

--near the airfield
reconnaissancePatrolOne = {-- playerId, unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{AI_ID, Units.L_INFANTRY_MG,		10, 18, 19, 16, enemySquadIds.reconnaissancePatrolOne},
	{AI_ID, Units.L_INFANTRY_AT,		10, 18, 19, 16, enemySquadIds.reconnaissancePatrolOne},
	{AI_ID, Units.L_INFANTRY_MG,		10, 18, 19, 16, enemySquadIds.reconnaissancePatrolOne},
	{AI_ID, Units.L_TRUCK_MG,			10, 18, 19, 16, enemySquadIds.reconnaissancePatrolOne},
	{AI_ID, Units.L_TRUCK_AA,			10, 18, 19, 16, enemySquadIds.reconnaissancePatrolOne},
};

-- near the right bridge
reconnaissancePatrolTwo = {-- playerId, unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{AI_ID, Units.L_INFANTRY_MG,		10, 18, 19, 16, enemySquadIds.reconnaissancePatrolTwo},
	{AI_ID, Units.L_INFANTRY_MG,		10, 18, 19, 16, enemySquadIds.reconnaissancePatrolTwo},
	{AI_ID, Units.L_TANK_HEAVY,			10, 18, 19, 16, enemySquadIds.reconnaissancePatrolTwo},
	{AI_ID, Units.L_TRUCK_AA,			10, 18, 19, 16, enemySquadIds.reconnaissancePatrolTwo},
	{AI_ID, Units.L_TRUCK_MG,			10, 18, 19, 16, enemySquadIds.reconnaissancePatrolTwo},
};

-- near the left bridge
reconnaissancePatrolThree = {-- playerId, unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{AI_ID, Units.L_INFANTRY_AT,		1, 5, 15, 4, enemySquadIds.reconnaissancePatrolThree},
	{AI_ID, Units.L_TANK_LIGHT,			1, 7, 15, 4, enemySquadIds.reconnaissancePatrolThree},
	{AI_ID, Units.L_TRUCK_MG,			2, 6, 15, 4, enemySquadIds.reconnaissancePatrolThree},
	{AI_ID, Units.L_TRUCK_AA,			1, 6, 15, 4, enemySquadIds.reconnaissancePatrolThree},
	{AI_ID, Units.L_INFANTRY_FLAME,		1, 4, 15, 4, enemySquadIds.reconnaissancePatrolThree},
};

reconnaissancePatrolFour = {-- playerId, unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{AI_ID, Units.L_TRUCK_AA,			1, 7, 15, 4, enemySquadIds.reconnaissancePatrolFour},
	{AI_ID, Units.L_INFANTRY_FLAME,		1, 4, 15, 4, enemySquadIds.reconnaissancePatrolFour},
	{AI_ID, Units.L_INFANTRY_MG,		1, 5, 15, 4, enemySquadIds.reconnaissancePatrolFour},
	{AI_ID, Units.L_INFANTRY_MORTAR,	2, 6, 15, 4, enemySquadIds.reconnaissancePatrolFour},
	{AI_ID, Units.L_TANK_MEDIUM,		1, 6, 15, 4, enemySquadIds.reconnaissancePatrolFour},
};

planeWaveOne = {-- playerId, unitTemplateId, tileX, tileY, orderX, orderY, squadId
	{AI_ID, Units.L_PLANE_LIGHT,		1, 4, -1, -1, enemySquadIds.planeWave1},
	{AI_ID, Units.L_PLANE_LIGHT,		1, 2, -1, -1, enemySquadIds.planeWave1},
};

planeWaveTwo = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.L_PLANE_LIGHT,		1, 14, -1, -1, enemySquadIds.planeWave2},
	{AI_ID, Units.L_PLANE_HEAVY,		1, 12, -1, -1, enemySquadIds.planeWave2},
};

planeWaveThree = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.L_PLANE_LIGHT, 		1, 14, -1, -1, enemySquadIds.planeWave3},
	{AI_ID, Units.L_PLANE_LIGHT, 		1, 12, -1, -1, enemySquadIds.planeWave3},
};

planeWaveFour = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{AI_ID, Units.L_PLANE_LIGHT,		1, 12, -1, -1, enemySquadIds.planeWave4},
	{AI_ID, Units.L_PLANE_HEAVY,		1, 10, -1, -1, enemySquadIds.planeWave4},
};

planeWaveFive = {-- playerId, unitTemplateId, tileX, tileY, squadIdwesternfront% 
	{AI_ID, Units.L_PLANE_HEAVY,		1, 12, -1, -1, enemySquadIds.planeWave5},
	{AI_ID, Units.L_PLANE_BOMBER,		1, 10, -1, -1, enemySquadIds.planeWave5},
};

planeWaveAirfield = {
	{AI_ID, Units.L_PLANE_BOMBER, 		1, 12, 35, 6, enemySquadIds.planeWave5},
};

planeWaveOneWaypoints	= {{5, 4},--[[village south]]		 {15,  4},--[[ airfield left]]	{19, 16},--[[airfield middle]]
							{33, 15},--[[airfield right]]		{35, 6} --[[HQ]]};
planeWaveTwoWaypoints	= {{7, 15},--[[village north]]		 {19, 16},--[[airfield middle]]	{25, 11},--[[railway crossing]]	{36,  9},--[[tank factory]]};
planeWaveThreeWaypoints	= {{15, 4},--[[airfield left]]		 {17, 11},--[[supplies left]]		{25, 11},--[[railway crossing]]
							{29, 4},--[[village south right]] {35, 6}--[[HQ]]};
planeWaveFourWaypoints	= {{19, 16},--[[airfield middle]]	 {33, 15},--[[airfield right]]	{36,  9},--[[tank factory]]		{35,  6},--[[HQ]]};
planeWaveFiveWaypoints	= {{19, 16},--[[airfield middle]]	 {25, 11},--[[railway crossing]]	{33, 15},--[[airfield right]]		{36,  9},--[[HQ]]};

AApatrolTiles = {{9, 18}, {5, 15}, {1, 11}};

airfieldUnits = {Units.X_PLANE_BOMBER, Units.X_PLANE_HEAVY, Units.X_PLANE_LIGHT, Units.X_PLANE_TRANSPORT};

airfieldWest = {AIRFIELD_WEST_UNIT_ID, Units.X_PLANE_TRANSPORT, 33, 16, 33, 16};
airfieldNorth = {AIRFIELD_NORTH_UNIT_ID, Units.X_PLANE_LIGHT, 18, 15, 18, 16};
airfieldSouth = {AIRFIELD_SOUTH_UNIT_ID, Units.X_PLANE_HEAVY, 14, 5, 15, 5};

airfieldWestIsActive = 0;
airfieldNorthIsActive = 0;
airfieldSouthIsActive = 0;

northernReconnaissanceSquadIsActive = 0;
southernReconnaissanceSquadIsActive = 0;
roundOfNorthernReconnaissanceInitSpawn = -1;
roundOfSouthernReconnaissanceInitSpawn = -1;

patrolwavesInProgress = 0;
planeWavesInProgress = 0;

-- BEGIN Init

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold(0, 1500);
	spawnEnemyScoutPlanes();
	setAirfieldSupplies();
	
	local unit1 = ScriptManager:spawnUnit(PLAYER_ID, Units.X_INFANTRY_MG, 4, 16, -1):setHealth(1);	
	local unit2 = ScriptManager:spawnUnit(PLAYER_ID, Units.X_TRUCK_MG, 5, 17, -1):setHealth(1);
	local unit3 = ScriptManager:spawnUnit(PLAYER_ID, Units.X_PLANE_LIGHT, 4, 17, -1):setHealth(1);

	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("planeTrigger", 0);
	
	ScriptManager:storeValue("roundOfNorthernReconnaissanceInitSpawn", roundOfNorthernReconnaissanceInitSpawn);
	ScriptManager:storeValue("roundOfSouthernReconnaissanceInitSpawn", roundOfSouthernReconnaissanceInitSpawn);
	ScriptManager:storeValue("northernReconnaissanceSquadIsActive", northernReconnaissanceSquadIsActive);
	ScriptManager:storeValue("southernReconnaissanceSquadIsActive", southernReconnaissanceSquadIsActive);
	
	ScriptManager:storeValue("airfieldWestIsActive", airfieldWestIsActive);
	ScriptManager:storeValue("airfieldNorthIsActive", airfieldNorthIsActive);
	ScriptManager:storeValue("airfieldSouthIsActive", airfieldSouthIsActive);
end

function loadValues()
	balloonCheck();
	
	patrolwavesInProgress = ScriptManager:getValue( "patrolwavesInProgress" );
	planeWavesInProgress = ScriptManager:getValue( "planeWavesInProgress" );
	
	roundOfNorthernReconnaissanceInitSpawn = ScriptManager:getValue("roundOfNorthernReconnaissanceInitSpawn");
	roundOfSouthernReconnaissanceInitSpawn = ScriptManager:getValue("roundOfSouthernReconnaissanceInitSpawn");
	northernReconnaissanceSquadIsActive = ScriptManager:getValue("northernReconnaissanceSquadIsActive");
	southernReconnaissanceSquadIsActive = ScriptManager:getValue("southernReconnaissanceSquadIsActive");
	
	airfieldWestIsActive = ScriptManager:getValue("airfieldWestIsActive");
	airfieldNorthIsActive = ScriptManager:getValue("airfieldNorthIsActive");
	airfieldSouthIsActive = ScriptManager:getValue("airfieldSouthIsActive");
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
--	ScriptManager:addOnUnitHasAttackedTrigger(	1, , -1,	"showAttackedWarning",	"showAttackedWarning" );
--	ScriptManager:addOnUnitHasAttackedTrigger(	0, , -1,	"stopAttackingHint",	"stopAttackingHint" );
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_BUILDING_AIRFIELD,		AIRFIELD_SOUTH_UNIT_ID,	"transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_BUILDING_AIRFIELD,		AIRFIELD_NORTH_UNIT_ID,	"transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_BUILDING_AIRFIELD,		AIRFIELD_WEST_UNIT_ID,	"transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.X_BUILDING_HQ,			PLAYER_HQ_UNIT_ID,			"transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(-1, Units.N_BUILDING_TANKFACTORY,	PLAYER_TANK_FACTORY_UNIT_ID,			"transitionToFail", "transitionToFail" );	
	
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnSquadDestroyedTrigger(-1, "onEnemySquadDestroyed", "onEnemySquadDestroyed");
	
	-- when any airfield is supplied for the first time
	ScriptManager:addOnUnitSuppliedTrigger(PLAYER_ID, Units.X_BUILDING_AIRFIELD, -1, "onInitAirfieldSupplied",			"onInitAirfieldSupplied" );
	ScriptManager:addOnUnitInstantSuppliedTrigger(PLAYER_ID, Units.X_BUILDING_AIRFIELD, -1, "onInitAirfieldInstantSupplied",	"onInitAirfieldInstantSupplied" );
	
	-- when an airfield is supplied
	ScriptManager:addOnUnitSuppliedTrigger(PLAYER_ID, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldSupplied", "onAirfieldSupplied");
	ScriptManager:addOnUnitInstantSuppliedTrigger(PLAYER_ID, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldInstantSupplied", "onAirfieldInstantSupplied");

	-- when a special unit has been sighted or has attacked
	ScriptManager:addOnUnitSightedTrigger( 1, Units.L_PLANE_SCOUT, -1, true, "onScoutPlaneSighted", "onScoutPlaneSighted" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_PLANE_SCOUT, -1, "onScoutPlaneDestroyed", "onScoutPlaneDestroyed" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, -1, -1, "onPatrolHasAttacked", "onPatrolHasAttacked" );
	ScriptManager:addOnUnitSightedTrigger( 1, -1, -1, true, "onPatrolSighted", "onPatrolSighted" );
	
	-- when the tileTrigger hasn’t been triggered for a certain amount of rounds
	ScriptManager:addOnTurnStartTrigger( 1, -1, 2, "preparePlaneWaveStart", "preparePlaneWaveStart" );
	
	-- After x enemy planes have been shot down, the mission is won
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onEnemyPlaneDestroyed", "onEnemyPlaneDestroyed" );
	
	-- triggers the plane spawn
	for y = 1, 18 do
		ScriptManager:addOnEnterTileTrigger(25, y, 0, -1, -1, false, "onPlaneWaveStart", "onPlaneWaveStart", false);
	end
	
	-- waypoints 
	ScriptManager:addOnAiCalculationTrigger(true, "checkWaypointsPatrolAA", "checkWaypointsPatrolAA");
	ScriptManager:addOnAiCalculationTrigger(true, "checkPlaneWaypoints", "checkPlaneWaypoints");	
end

function onEnemyTurnStart(playerId, turnId, roundId)
	if(ScriptManager:getCurrentRound() <= 0) then
		spawnEnemyReconnaissanceSquad(reconnaissancePatrolOne);
		spawnEnemyReconnaissanceSquad(reconnaissancePatrolThree);
		
		setNorthernReconnaissanceSquadIsActive(1);
		setSouthernReconnaissanceSquadIsActive(1);
	end
	
	if(getNorthernReconnaissanceSquadIsActive() == 0) or
		(getRoundOfNorthernReconnaissanceInitSpawn() ~= -1) then
		if(ScriptManager:getCurrentRound() >= getRoundOfNorthernReconnaissanceInitSpawn() + MAX_NUMBER_OF_ROUNDS_BETWEEN_ENEMY_RECONNAISSANCE_SPAWN) then
			spawnEnemyReconnaissanceSquad(reconnaissancePatrolTwo);
			enableMoveOrderForEnemyReconnaissanceSquad(reconnaissancePatrolTwo[1][7], reconnaissancePatrolTwo[1][5], reconnaissancePatrolTwo[1][6]);
			setNorthernReconnaissanceSquadIsActive(1);
			setRoundOfNorthernReconnaissanceInitSpawn(-1);
		end
	end
	
	if(getSouthernReconnaissanceSquadIsActive() == 0) or
		(getRoundOfSouthernReconnaissanceInitSpawn() ~= -1) then
		if(ScriptManager:getCurrentRound() >= getRoundOfSouthernReconnaissanceInitSpawn() + MAX_NUMBER_OF_ROUNDS_BETWEEN_ENEMY_RECONNAISSANCE_SPAWN) then
			spawnEnemyReconnaissanceSquad(reconnaissancePatrolFour);
			enableMoveOrderForEnemyReconnaissanceSquad(reconnaissancePatrolFour[1][7], reconnaissancePatrolFour[1][5], reconnaissancePatrolFour[1][6]);
			setSouthernReconnaissanceSquadIsActive(1);
			setRoundOfSouthernReconnaissanceInitSpawn(-1);
		end
	end
end

function onEnemySquadDestroyed(squadId)
	if(squadId >= enemySquadIds.reconnaissancePatrolOne) and 
		(squadId <= enemySquadIds.reconnaissancePatrolFour) then
		
		if(squadId == enemySquadIds.reconnaissancePatrolOne) then
			setNorthernReconnaissanceSquadIsActive(0);
		elseif(squadId == enemySquadIds.reconnaissancePatrolThree) then
			setSouthernReconnaissanceSquadIsActive(0);
		end
		
		onReconnaissanceSquadDestroyed();
	end
	
	if(squadId >= enemySquadIds.planeWave1) and
		(squadId <= enemySquadIds.planeWave5) then
		onPlaneSquadDestroyed();
	end
end

function onReconnaissanceSquadDestroyed()
	Utils:incrementMissionProgress( missionIds.DESTROY_ENEMY_PATROLS );
	
	if(ScriptManager:getMissionProgress( missionIds.DESTROY_ENEMY_PATROLS ) >= ENEMY_RECONNAISSANCE_SQUADS_TO_DESTROY) then
		Utils:setMissionStatus(missionIds.DESTROY_ENEMY_PATROLS, MissionStatus.ACCOMPLISHED);
		
		patrolwavesInProgress = 0;
		ScriptManager:storeValue("patrolwavesInProgress", patrolwavesInProgress);
		
		checkForVictory();
	else
		Utils:showMissionProgress(ScriptManager:getMissionProgress( missionIds.DESTROY_ENEMY_PATROLS ), Text.T_CAMP_X2_1_PRIMARY3_COUNTER);
	end
end

function onPlaneSquadDestroyed()
		-- old wave squad was destroyed, prepare spawn for next
	local nextSpawnRound = ScriptManager:getCurrentRound() + PLANE_WAVE_RESPAWN_INTERVAL;
	ScriptManager:addOnTurnStartTrigger(1, -1, nextSpawnRound, "spawnNewWave", "spawnNewWave");
end

function onEnemyPlaneDestroyed( unit )
	if(unit:getTemplateId() >= Units.L_PLANE_LIGHT) and
		(unit:getTemplateId() <= Units.L_PLANE_TRANSPORT) then
		Utils:incrementMissionProgress( missionIds.PROTECT_OWN_BUILDINGS );

		if(ScriptManager:getMissionProgress( missionIds.PROTECT_OWN_BUILDINGS ) >= MAX_NUMBER_OF_PLANES_TO_DESTROY) then
			ScriptManager:removeTrigger("onEnemyPlaneDestroyed");
			
			planeWavesInProgress = 0;
			ScriptManager:storeValue("planeWavesInProgress", planeWavesInProgress);
			
			checkForVictory();		
		end	
	end
end

function onPlaneWaveStart()
	ScriptManager:removeTrigger("onPlaneWaveStart");
	ScriptManager:storeValue("planeTrigger", 1);
	ScriptManager:runForPlayer(AI_ID, "spawnPlaneWave");
	
	planeWavesInProgress = 1;
	ScriptManager:storeValue("planeWavesInProgress", planeWavesInProgress);
end

function onInitAirfieldSupplied(supplyUnit, suppliedUnit)
	onInitAirfieldInstantSupplied(suppliedUnit);
end

function onInitAirfieldInstantSupplied(unit)
	if(unit ~= nil) then
		if(unit:getId() == AIRFIELD_NORTH_UNIT_ID) or
			(unit:getId() == AIRFIELD_SOUTH_UNIT_ID) or
			(unit:getId() == AIRFIELD_WEST_UNIT_ID) then
			if(unit:getSupplyLoad() >= 1) then
				Utils:disablePlayerInteraction();
				
				Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_PRIMARY1_FLAVOR1, 7 );
				
				Utils:enablePlayerInteraction();
					
				ScriptManager:removeTrigger("onInitAirfieldSupplied");
				ScriptManager:removeTrigger("onInitAirfieldInstantSupplied");
			end
		end
	end
end

function onAirfieldSupplied(supplyUnit, suppliedUnit)
	onAirfieldInstantSupplied(suppliedUnit);
end

function onAirfieldInstantSupplied(unit)
	if(unit ~= nil) then
		if(unit:getSupplyLoad() >= AIRFIELD_CARGO * 0.5) then
			local airfieldTable = -1;
			
			if(unit:getId() == AIRFIELD_WEST_UNIT_ID) then
				airfieldTable = airfieldWest;
				
				if(getAirfieldWestIsActive() == 0) then
					enablePlaneUnitsToAirfield(AIRFIELD_WEST_UNIT_ID);
					spawnPlayerAirfieldUnit(airfieldTable);
					updateAirfieldMissionProgress();
					setAirfieldWestIsActive(1);
				end
			elseif(unit:getId() == AIRFIELD_NORTH_UNIT_ID) then
				airfieldTable = airfieldNorth;
				
				if(getAirfieldNorthIsActive() == 0) then
					enablePlaneUnitsToAirfield(AIRFIELD_NORTH_UNIT_ID);
					spawnPlayerAirfieldUnit(airfieldTable);
					updateAirfieldMissionProgress();
					setAirfieldNorthIsActive(1);
					
					enableMoveOrderForEnemyReconnaissanceSquad(reconnaissancePatrolOne[1][7], reconnaissancePatrolOne[1][5], reconnaissancePatrolOne[1][6]);
					setRoundOfNorthernReconnaissanceInitSpawn(ScriptManager:getCurrentRound());
				end
			elseif(unit:getId() == AIRFIELD_SOUTH_UNIT_ID) then
				airfieldTable = airfieldSouth;
				
				if(getAirfieldSouthIsActive() == 0) then
					enablePlaneUnitsToAirfield(AIRFIELD_SOUTH_UNIT_ID);
					spawnPlayerAirfieldUnit(airfieldTable);
					updateAirfieldMissionProgress();
					setAirfieldSouthIsActive(1);
					
					enableMoveOrderForEnemyReconnaissanceSquad(reconnaissancePatrolThree[1][7], reconnaissancePatrolThree[1][5], reconnaissancePatrolThree[1][6]);
					setRoundOfSouthernReconnaissanceInitSpawn(ScriptManager:getCurrentRound());
				end
			end
		end
	end
end

function onScoutPlaneSighted( discoveringUnit, discoveredUnit )
	ScriptManager:removeTrigger( "onScoutPlaneSighted" );

	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( discoveredUnit:getX(), discoveredUnit:getY(), 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_SECONDARY1_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_SECONDARY1_FLAVOR2, 4 );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.DESTROY_SCOUTS, MissionStatus.IN_PROGRESS );
end

function onScoutPlaneDestroyed(unit)
	if unit:getTemplateId() == Units.L_PLANE_SCOUT then
 	
		Utils:incrementMissionProgress( missionIds.DESTROY_SCOUTS );
		ScriptManager:wait(1);
		if ScriptManager:getMissionProgress( missionIds.DESTROY_SCOUTS ) >= ENEMY_SCOUTS_TO_DESTROY then
			ScriptManager:removeTrigger( "onScoutPlaneDestroyed" );
			Utils:setMissionStatus( missionIds.DESTROY_SCOUTS, MissionStatus.ACCOMPLISHED );
		else
			Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.DESTROY_SCOUTS), Text.T_CAMP_X2_1_SECONDARY1_COUNTER );
		end
	end
end

function onPatrolSighted(discoveringUnit, unit)
	if(unit:getSquadId() >= enemySquadIds.reconnaissancePatrolOne) and
		(unit:getSquadId() <= enemySquadIds.reconnaissancePatrolFour) then
		
		ScriptManager:storeValue( "unitX", unit:getX() );
		ScriptManager:storeValue( "unitY", unit:getY() );
		
		ScriptManager:removeTrigger( "onPatrolSighted" );
		ScriptManager:removeTrigger( "onPatrolHasAttacked" );
		ScriptManager:runForPlayer(PLAYER_ID, "preparePatrolCutscene");
	end
end

function onPatrolHasAttacked(unit)
	if(unit:getSquadId() >= enemySquadIds.reconnaissancePatrolOne) and
		(unit:getSquadId() <= enemySquadIds.reconnaissancePatrolFour) then
		
		ScriptManager:storeValue( "unitX", unit:getX() );
		ScriptManager:storeValue( "unitY", unit:getY() );
		
		ScriptManager:removeTrigger( "onPatrolSighted" );
		ScriptManager:removeTrigger( "onPatrolHasAttacked" );
		ScriptManager:runForPlayer(PLAYER_ID, "preparePatrolCutscene");
	end
end

function updateAirfieldMissionProgress()
	Utils:incrementMissionProgress(missionIds.RESUPPLY_AIRFIELDS);
			
	if ScriptManager:getMissionProgress(missionIds.RESUPPLY_AIRFIELDS) >= AIRFIELDS_TO_RESUPPLY then
		Utils:setMissionStatus(missionIds.RESUPPLY_AIRFIELDS, MissionStatus.ACCOMPLISHED);
		checkForVictory()
	else
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.RESUPPLY_AIRFIELDS), AIRFIELDS_TO_RESUPPLY, Text.T_CAMP_X2_1_PRIMARY1_COUNTER );
	end
end

-- #######################################-AI_ORDERS-#######################################

function addAiOrders()

end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:revealFogOfWar( 3, 15, 3, true );
	
	ScriptManager:runAbility( 1, -1, -1, GlobalAbility.AIRSTRIKE, 5, 16, -1 );
	
	ScriptManager:wait( 5 );
	
	local flame = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	local bunkerDefender = Unit:getUnitAt( 4, 14 ):getId();
	
	ScriptManager:moveUnitEx( flame, 3, 15, true );
	ScriptManager:attackUnitEx( flame, bunkerDefender, true );
	
	local MG1 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 1, 16, -1 ):getId();
	ScriptManager:moveUnitEx( MG1, 3, 14, true );
	
	ScriptManager:loadUnitIntoTransporterEx( BUNKER_AIRFIELD_EAST_UNIT_ID, MG1, true );
	
	ScriptManager:wait( 0.2 );
	
	local MG2 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	ScriptManager:moveUnitEx( MG2, 4, 16, true );
	
	ScriptManager:captureUnitEx( MG2, AIRFIELD_EAST_UNIT_ID, true );
	
	ScriptManager:wait( 0.2 );
	
	local tank = ScriptManager:spawnUnit( 1, Units.L_TANK_LIGHT, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	ScriptManager:moveUnitEx( tank, 5, 16, true );
	
	ScriptManager:wait( 0.1 );
	
	local sniper = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_SNIPER, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_1_INTRO_FLAVOR1, 4 );
		
	ScriptManager:revealFogOfWar( 3, 15, 3, false );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X_2_1_INTRO_FLAVOR2 );
	
	ScriptManager:moveCameraEx(		15, 4, 0.7, 3, true );
	ScriptManager:revealFogOfWar(	15, 4, 1, true );
	ScriptManager:showMarkerAt(		15, 4 );
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx(		19, 16, 0.7, 3, true );
	ScriptManager:revealFogOfWar(	19, 16, 1, true );
	ScriptManager:showMarkerAt(		19, 16 );
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx(		33, 15, 0.7, 3, true );
	ScriptManager:revealFogOfWar(	33, 15, 1, true );
	ScriptManager:showMarkerAt(		33, 15 );
	ScriptManager:wait( 2 );
	
	ScriptManager:removeAllMarkers()
	ScriptManager:revealFogOfWar( 15, 4, 1, false );
	ScriptManager:revealFogOfWar( 19, 16, 1, false );
	ScriptManager:revealFogOfWar( 33, 15, 1, false );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:moveCameraEx( 35, 8, 0.7, 2, true );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_1_INTRO_FLAVOR3, 6 );
	
	local truck1 =  ScriptManager:spawnUnit( 0, Units.X_TRUCK_SUPPLY, 36, 8, -1 ):getId();
	ScriptManager:wait( 0.5 );
	local truck2 = ScriptManager:spawnUnit( 0, Units.X_TRUCK_SUPPLY, 35, 9, -1 ):getId();	
	ScriptManager:wait( 0.5 );
	local truck3 = ScriptManager:spawnUnit( 0, Units.X_TRUCK_SUPPLY, 36, 10, -1 ):getId();
	ScriptManager:wait( 0.5 );
	
	ScriptManager:moveUnitEx( truck2, 33, 9, true );
	ScriptManager:moveUnitEx( truck1, 34, 8, true );
	ScriptManager:moveUnitEx( truck3, 34, 9, true );
	
	local truck4 = ScriptManager:spawnUnit( 0, Units.X_TRUCK_SUPPLY, 35, 9, -1 ):getId();
	ScriptManager:moveUnitEx( truck4, 35, 10, true );	
	
	ScriptManager:spawnUnit( 0, Units.X_TRUCK_AA, 36, 10, -1 );
	ScriptManager:wait( 0.5 );
	ScriptManager:spawnUnit( 0, Units.X_TRUCK_MG, 36, 8, -1 );
	ScriptManager:wait( 0.5 );
	ScriptManager:spawnUnit( 0, Units.X_TRUCK_TRANSPORT, 35, 9, -1 );
	ScriptManager:wait( 0.5 );
	
	local MG = ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 34, 5, -1 ):getId();
	ScriptManager:moveUnitEx( MG, 33, 7, true );
	local AT = ScriptManager:spawnUnit( 0, Units.X_INFANTRY_AT, 34, 5, -1 ):getId();
	ScriptManager:moveUnitEx( AT, 33, 6, true );
	local MG2 = ScriptManager:spawnUnit( 0, Units.X_TANK_MEDIUM, 34, 5, -1 ):getId();
	ScriptManager:moveUnitEx( MG2, 33, 5, true );
	local MG2 = ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 34, 5, -1 ):getId();
		
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_1_INTRO_FLAVOR4, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_1_INTRO_FLAVOR5, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_1_INTRO_FLAVOR6, 3 );
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 3 ); -- "Good luck!"
	
	Utils:endCutscene();
	
	ScriptManager:moveUnitEx( sniper, 1, 17, true)
	
	ScriptManager:spawnUnit( 1, Units.L_TANK_MEDIUM, 4, 16, enemySquadIds.airfieldDefenders );
	
	-- spawn the defenders
	local unit4 = ScriptManager:spawnUnit( 1, Units.L_TANK_HEAVY, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	ScriptManager:fortifyUnit( unit4, true );
	
	local unit5 = ScriptManager:spawnUnit( 1, Units.L_ARTILLERY_AA, 1, 16, enemySquadIds.airfieldDefenders ):getId();
	ScriptManager:fortifyUnit( unit5, true );
	
	ScriptManager:spawnUnit(AI_ID, Units.L_TANK_LIGHT,		3, 3, enemySquadIds.villageDefenders);
	ScriptManager:spawnUnit(AI_ID, Units.L_INFANTRY_MG,		4, 2, enemySquadIds.villageDefenders);
	ScriptManager:spawnUnit(AI_ID, Units.L_TRUCK_MG,	 	4, 3, enemySquadIds.villageDefenders);
	ScriptManager:spawnUnit(AI_ID, Units.L_TRUCK_AA,	 	3, 2, enemySquadIds.villageDefenders);
	
	local tank = ScriptManager:spawnUnit(AI_ID, Units.L_TANK_HEAVY, 1, 10, enemySquadIds.bridgeDefenders ):getId();
	ScriptManager:fortifyUnit( tank, true );
	
	local sniper = ScriptManager:spawnUnit(AI_ID, Units.L_INFANTRY_SNIPER, 1, 12, enemySquadIds.bridgeDefenders ):getId();
	ScriptManager:fortifyUnit( sniper, true );
	
	local MG = ScriptManager:spawnUnit(AI_ID, Units.L_INFANTRY_MG, 2, 8, enemySquadIds.bridgeDefenders ):getId();
	ScriptManager:fortifyUnit( MG, true );
	
	ScriptManager:spawnUnit(AI_ID, Units.L_TANK_MEDIUM,	  9, 16, enemySquadIds.woodDefenders );
	ScriptManager:spawnUnit(AI_ID, Units.L_INFANTRY_SNIPER,  9, 15, enemySquadIds.woodDefenders );
	ScriptManager:spawnUnit(AI_ID, Units.L_INFANTRY_MORTAR, 10, 15, enemySquadIds.woodDefenders );
	
	ScriptManager:spawnUnit(AI_ID, Units.L_TRUCK_AA, 10, 18, enemySquadIds.patrolAA );
	
	ScriptManager:addOrder(enemySquadIds.airfieldDefenders, 5, 15, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.bunkerAirfield, 4, 14, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.villageDefenders, 4, 3, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.bridgeDefenders, 2, 12, -1, 3, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.woodDefenders, 9, 15, -1, 3, AiOrder.DEFEND);
	
	startTheMission();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_VICTORY_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_VICTORY_FLAVOR2, 7 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_VICTORY_FLAVOR3, 3 );
	 
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function preparePatrolCutscene()
	table.insert( queueTable, playPatrolCutscene )
	Utils:cutsceneQueue();
end

function playPatrolCutscene()
	local unitX = ScriptManager:getValue( "unitX" );
	local unitY = ScriptManager:getValue( "unitY" );
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( unitX, unitY, 0.7, 2, true );
	
	ScriptManager:wait( 1 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_PRIMARY3_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_PRIMARY3_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_PRIMARY3_FLAVOR3, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_1_PRIMARY3_FLAVOR4, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	Utils:setMissionStatus( missionIds.DESTROY_ENEMY_PATROLS, MissionStatus.IN_PROGRESS );
	
	Utils:enablePlayerInteraction();
end

-- #######################################-MISSIONS-#######################################

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.RESUPPLY_AIRFIELDS, MissionStatus.IN_PROGRESS );	
	ScriptManager:setMissionStatus( missionIds.PROTECT_OWN_BUILDINGS, MissionStatus.IN_PROGRESS );
end

function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );
end

-- #######################################-END_GAME-#######################################

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_PATROLS) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.RESUPPLY_AIRFIELDS) == MissionStatus.ACCOMPLISHED) then
		ScriptManager:wait(2);
		
		Utils:missionCheckerAccomplish(missionIds.PROTECT_OWN_BUILDINGS);
		ScriptManager:wait(2);
		
		startVictoryCutscene();
	end
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
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

-- #######################################-UNTS_AND_HELPER-#######################################

function setAirfieldSupplies()
	Unit:getUnitById(AIRFIELD_SOUTH_UNIT_ID):setSupplyLoad(0);
	Unit:getUnitById(AIRFIELD_NORTH_UNIT_ID):setSupplyLoad(0);
	Unit:getUnitById(AIRFIELD_WEST_UNIT_ID):setSupplyLoad(0);
	
	for i = 1, #airfieldUnits do
		ScriptManager:removeReinforcementsFromBase(AIRFIELD_SOUTH_UNIT_ID, airfieldUnits[i]);
		ScriptManager:removeReinforcementsFromBase(AIRFIELD_NORTH_UNIT_ID, airfieldUnits[i]);
		ScriptManager:removeReinforcementsFromBase(AIRFIELD_WEST_UNIT_ID, airfieldUnits[i]);
	end
end

function balloonCheck()
	local heuristicMaxNumberOfUnits = 100;
	
	for i = 0, heuristicMaxNumberOfUnits do
		if(Unit:getUnitById(i) ~= nil) then
			if(Unit:getUnitById(i):getTemplateId() == Units.X_PLANE_SCOUT) then
				Unit:getUnitById(i):setMaxPlaneTurns(-1);
				Unit:getUnitById(i):setPlaneTurns(-1);
			end
		end
	end
end

function enablePlaneUnitsToAirfield(airfieldId)
	if(Unit:getUnitById(airfieldId) ~= nil) then
		for i = 1, #airfieldUnits do
			ScriptManager:addReinforcementsToBase(airfieldId, airfieldUnits[i] );
		end
	end
end

function spawnEnemyScoutPlanes()
	for i = 1, #enemyScoutPlanes do
		local currentUnitId = ScriptManager:spawnUnit(AI_ID, enemyScoutPlanes[i][1], enemyScoutPlanes[i][2], enemyScoutPlanes[i][3], enemyScoutPlanes[i][4]):getId();
		
		Unit:getUnitById(currentUnitId):setMaxPlaneTurns(-1);
		Unit:getUnitById(currentUnitId):setPlaneTurns(-1);
	end
end

function spawnPlayerAirfieldUnit(unitTable)
	if(unitTable ~= nil) and (unitTable ~= -1) then
		if(Unit:getUnitAt(unitTable[3], unitTable[4]) == nil) then
			ScriptManager:spawnUnit(PLAYER_ID, unitTable[2], unitTable[3], unitTable[4], -1);
		else
			ScriptManager:spawnUnit(PLAYER_ID, unitTable[2], unitTable[5], unitTable[6], -1);
		end
	end
end

function spawnEnemyReconnaissanceSquad(unitTable)
	local currentUnitTable = nil;
	
	currentUnitTable = unitTable;
	
	if(currentUnitTable ~= nil) then
		for i = 1, #currentUnitTable do
			ScriptManager:spawnUnit(currentUnitTable[i][1], currentUnitTable[i][2], currentUnitTable[i][3], currentUnitTable[i][4], currentUnitTable[i][7]);
		end
		
		local currentOrder = ScriptManager:addOrder(currentUnitTable[1][7], currentUnitTable[1][3], currentUnitTable[1][4], -1, 2, AiOrder.DEFEND);
	end
end

function enableMoveOrderForEnemyReconnaissanceSquad(squadId, orderX, orderY)
	ScriptManager:removeAllOrders(squadId);
	
	local orderId = ScriptManager:addOrder(squadId, orderX, orderY, -1, 3, AiOrder.MOVE);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_HOLD_FIRE);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_STACK_TOGETHER);
end

function spawnPlaneWave()
	local rnd = math.random ( 0, 4 );
	local spawnTable = 0;
	
	if(planeWavesInProgress == 1) then
		ScriptManager:removeTrigger( "spawnPlaneWave" );
		
		if(rnd == 0) then
			spawnTable = planeWaveOne
		elseif(rnd == 1) then
			spawnTable = planeWaveTwo
		elseif(rnd == 2) then
			spawnTable = planeWaveThree
		elseif(rnd == 3) then
			spawnTable = planeWaveFour
		elseif(rnd == 4) then
			spawnTable = planeWaveFive
		else
			spawnTable = planeWaveAirfield
		end
	end
	
	for i = 1, #spawnTable do
		ScriptManager:spawnUnit(AI_ID, spawnTable[i][2], spawnTable[i][3], spawnTable[i][4], spawnTable[i][7]);
	end
	
	local currentOrderId = ScriptManager:addOrder(spawnTable[1][7], spawnTable[1][5], spawnTable[1][6], -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_STACK_TOGETHER);
	
	if(spawnTable[1][7] ~= enemySquadIds.planeWaveAirfield) then
		ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY);
	ScriptManager:enableOrderFlag(orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK);
	end
end

function preparePlaneWaveStart()
	ScriptManager:removeTrigger("preparePlaneWaveStart");
	ScriptManager:removeTrigger("onPlaneWaveStart");
	
	planeWavesInProgress = 1;
	ScriptManager:storeValue( "planeWavesInProgress", planeWavesInProgress );
	ScriptManager:runForPlayer( 1, "spawnNewWave" );
end

function spawnNewWave()
	if ScriptManager:getMissionStatus( missionIds.PROTECT_OWN_BUILDINGS ) ~= MissionStatus.ACCOMPLISHED then
		spawnPlaneWave()
	end
end

function checkWaypointsPatrolAA( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.patrolAA then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, AApatrolTiles );
	end
end

function checkPlaneWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.planeWave1 then
		Utils:checkWaypoints( enemySquadIds.planeWave1, mainOrderData, allMainOrderData, planeWaveOneWaypoints );
	elseif
		squadId == enemySquadIds.planeWave2 then
		Utils:checkWaypoints( enemySquadIds.planeWave2, mainOrderData, allMainOrderData, planeWaveTwoWaypoints );
	elseif
		squadId == enemySquadIds.planeWave3 then
		Utils:checkWaypoints( enemySquadIds.planeWave3, mainOrderData, allMainOrderData, planeWaveThreeWaypoints );
	elseif
		squadId == enemySquadIds.planeWave4 then
		Utils:checkWaypoints( enemySquadIds.planeWave4, mainOrderData, allMainOrderData, planeWaveFourWaypoints );
	elseif
		squadId == enemySquadIds.planeWave5 then
		Utils:checkWaypoints( enemySquadIds.planeWave5, mainOrderData, allMainOrderData, planeWaveFiveWaypoints );
	end
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getRoundOfNorthernReconnaissanceInitSpawn()
	return roundOfNorthernReconnaissanceInitSpawn;
end

function setRoundOfNorthernReconnaissanceInitSpawn(value)
	roundOfNorthernReconnaissanceInitSpawn = value;
	
	ScriptManager:storeValue("roundOfNorthernReconnaissanceInitSpawn", roundOfNorthernReconnaissanceInitSpawn);
end

function getRoundOfSouthernReconnaissanceInitSpawn()
	return roundOfSouthernReconnaissanceInitSpawn;
end

function setRoundOfSouthernReconnaissanceInitSpawn(value)
	roundOfSouthernReconnaissanceInitSpawn = value;
	
	ScriptManager:storeValue("roundOfSouthernReconnaissanceInitSpawn", roundOfSouthernReconnaissanceInitSpawn);
end

function getNorthernReconnaissanceSquadIsActive()
	return northernReconnaissanceSquadIsActive;
end

function setNorthernReconnaissanceSquadIsActive(bool)
	northernReconnaissanceSquadIsActive = bool;
	
	ScriptManager:storeValue("northernReconnaissanceSquadIsActive", northernReconnaissanceSquadIsActive);
end

function getSouthernReconnaissanceSquadIsActive()
	return southernReconnaissanceSquadIsActive;
end

function setSouthernReconnaissanceSquadIsActive(bool)
	southernReconnaissanceSquadIsActive = bool;
	
	ScriptManager:storeValue("southernReconnaissanceSquadIsActive", southernReconnaissanceSquadIsActive);
end

function getAirfieldWestIsActive()
	return airfieldWestIsActive;
end

function setAirfieldWestIsActive(bool)
	airfieldWestIsActive = bool;
	
	ScriptManager:storeValue("airfieldWestIsActive", airfieldWestIsActive);
end

function getAirfieldNorthIsActive()
	return airfieldNorthIsActive;
end

function setAirfieldNorthIsActive(bool)
	airfieldNorthIsActive = bool;
	
	ScriptManager:storeValue("airfieldNorthIsActive", airfieldNorthIsActive);
end

function getAirfieldSouthIsActive()
	return airfieldSouthIsActive;
end

function setAirfieldSouthIsActive(bool)
	airfieldSouthIsActive = bool;
	
	ScriptManager:storeValue("airfieldSouthIsActive", airfieldSouthIsActive);
end

-- #######################################-TESTING-#######################################

function removeSquads()

end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end

-- END Defeated