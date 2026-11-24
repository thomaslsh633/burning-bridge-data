require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	capBase				= 1,
	capFactory			= 2,
	capAirfield			= 3,
	destroyDefenders	= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.capBase,			true,	Text.T_MISSION_CAP_BASE,		175 },
	{ missionIds.capFactory,		true,	Text.T_MISSION_CAP_FACOTRY,		150 },
	{ missionIds.capAirfield,		false,	Text.T_MISSION_CAP_AIRFIELD,	 70 },
	{ missionIds.destroyDefenders,	false,	Text.T_CAMP_L5_3_SECONDARY2,	100 },
};

enemySquadIds = {
	cityBase			=  1,
	cityFactory			=  2,
	cityAirfield		=  3,
	cityAirfieldArty	=  4,
	cityNorth			=  5,
	cityNorthMortar		=  6,
	--more squads ?
	cityMgNest			=  9, -- must stay last city squad!
	railDef				= 10,
	roadDef				= 11,
	roadMortar			= 12,
	roadMgNestW			= 13,
	roadMgNestE			= 14,
	roadBunkerN			= 15,
	roadBunkerS			= 16,
	railBridge			= 17,
	planeWave			= 18;
};

baseId		= 3;
factoryId	= 2;
airfieldId	= 4;
railId		= 1;

defendersToDestroy = 23;

waypointTable = { { 18, 5 }, { 13, 4 }, { 16, 11 }, { 12, 13 }, { 12, 5 }, };
planeWaveRespawnInterval = 3; -- defines how often waves will spawn
spawnPlaneWaves			 = 1;

planeWave1 = {
	{ Units.X_PLANE_LIGHT, 21, 4 },
	{ Units.X_PLANE_LIGHT, 21, 5 },
};

planeWave2 = {
	{ Units.X_PLANE_HEAVY, 21, 4 },
	{ Units.X_PLANE_LIGHT, 21, 5 },
};

planeWave3 = {
	{ Units.X_PLANE_BOMBER, 21, 5 },
};

-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:gainGold( 0, 750 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "spawnPlaneWaves", spawnPlaneWaves );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.X_BUILDING_HQ,			 -1, "stopAttackingHint1",	"stopAttackingHint1" );
	ScriptManager:addOnUnitDestroyedTrigger(	1, Units.X_BUILDING_HQ,			 -1, "transitionToFail",	"transitionToFail" );
	ScriptManager:addOnUnitCapturedTrigger(		0, Units.X_BUILDING_HQ,			 -1, "onBaseCaptured", 		"onBaseCaptured" );
	
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.N_BUILDING_TANKFACTORY, -1, "stopAttackingHint2",	"stopAttackingHint2" );
	ScriptManager:addOnUnitDestroyedTrigger(	1, Units.N_BUILDING_TANKFACTORY, -1, "transitionToFail",	"transitionToFail" );
	ScriptManager:addOnUnitCapturedTrigger(		0, Units.N_BUILDING_TANKFACTORY, -1, "onFactoryCaptured", 	"onFactoryCaptured" );
	
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.X_BUILDING_AIRFIELD,	 -1, "stopAttackingHint3",	"stopAttackingHint3" );
	ScriptManager:addOnUnitDestroyedTrigger(	1, Units.X_BUILDING_AIRFIELD,	 -1, "onAirfieldDestroyed",	"onAirfieldDestroyed" );
	ScriptManager:addOnUnitCapturedTrigger(		0, Units.X_BUILDING_AIRFIELD,	 -1, "onAirfieldCaptured", 	"onAirfieldCaptured" );
	
	--trigger for destroying enemies
	local x, y;
	
	--north west entrance of city
	x = 10;
	for y = 8, 12 do
		--print( x .. " | " .. y );
		ScriptManager:addOnEnterTileTrigger( x, y, 0, -1, -1, true, "startEnteringBaseCutscene", "startEnteringBaseCutscene" );
	end
	x = 9;
	for y = 13, 23 do
		if y % 2 == 0 then
			x = x + 1;
		end
		--print( x .. " | " .. y );
		ScriptManager:addOnEnterTileTrigger( x, y, 0, -1, -1, true, "startEnteringBaseCutscene", "startEnteringBaseCutscene" );
	end
	
	-- west ( over the rail bridge )
	ScriptManager:addOnEnterTileTrigger( 7, 5, 0, -1, -1, true, "startEnteringBaseCutscene", "startEnteringBaseCutscene" );
	
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onEnemyDestroyed",	"onEnemyDestroyed" );
	ScriptManager:addOnBunkerClearedTrigger( 1, -1, -1, "onBunkerCleared",	"onEnemyDestroyed" );
	
	-- trigger for wave spawn
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, "spawnPlaneWave", "spawnPlaneWave" );
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planeWave, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	
	-- triggers for ai
	ScriptManager:addOnAiCalculationTrigger( true, "addAiOrders", "addAiOrders" );
end

function loadValues()
	spawnPlaneWaves = ScriptManager:getValue( "spawnPlaneWaves" );
end

function addAiOrders( squadId, mainOrderData, allMainOrderData )
	if allMainOrderData:count() <= 0 then
		print( "squad #" .. squadId .. " needs new orders" );
		
		if squadId == enemySquadIds.cityBase then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityBase, -1, -1, baseId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.cityBase, 17, 10, -1,		3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.cityFactory then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityFactory, -1, -1, factoryId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.cityFactory, 14,  4, -1,			3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.cityAirfield then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityAirfield, -1, -1, airfieldId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.cityAirfield, 21,  4, -1,			3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.railBridge then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.railBridge, -1, -1, railId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.railBridge,  5,  5, -1,		3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.cityNorth then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityNorth, 18, 13, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.railDef then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.railDef, 3,  7, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadDef then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadDef, 12, 15, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.cityAirfieldArty then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityAirfieldArty, 20,  2, -1, 6, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.cityNorthMortar then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityNorthMortar, 17, 13, -1, 5, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.cityMgNest then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityMgNest, 17,  7, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadMortar then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadMortar, 11, 15, -1, 5, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadMgNestW then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadMgNestW, 10, 14, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadMgNestE then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadMgNestE, 13, 17, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadBunkerN then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadBunkerN, 11, 16, -1, 3, AiOrder.DEFEND );
			
		elseif squadId == enemySquadIds.roadBunkerS then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.roadBunkerS, 13, 14, -1, 3, AiOrder.DEFEND );
		end
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_3_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx( 12, 16, 0.7, 7, true );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_3_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx(	17, 10, 0.7, 4, true );
	Utils:markUnit(				17, 10, 1, 2, 0 );
	ScriptManager:moveCameraEx(	14,  4, 0.7, 3, true );
	Utils:markUnit(				14,  4, 1, 2, 0 );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_3_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 21,  4, 0.7, 5, true );
	Utils:markUnit(				21,  4, 1, 2, 0 );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_SUBTITLE_INTRO_END_1 );
	ScriptManager:moveCameraEx( 3, 21, 0.7, 5, true );
	Utils:hideDialogue();
	Utils:antiRush();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.capBase,		MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.capFactory,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.capAirfield,	MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.destroyDefenders, defendersToDestroy, defendersToDestroy );
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Unit Stuff


function startEnteringBaseCutscene()
	ScriptManager:removeTrigger( "startEnteringBaseCutscene" );
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_3_SECONDARY2_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_3_SECONDARY2_FLAVOR2, 4 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyDefenders, MissionStatus.IN_PROGRESS );
end

function onBunkerCleared( flamethrower, bunker )
	onEnemyDestroyed( bunker );
end

function onEnemyDestroyed( destroyedUnit )
	local squadId = destroyedUnit:getSquadId()
	if squadId <= enemySquadIds.cityMgNest and squadId > 0 then
		Utils:decrementMissionProgress( missionIds.destroyDefenders );
		ScriptManager:runForPlayer( 0, "prepareDefenderMissionProgress" );
	end
end

function prepareDefenderMissionProgress()
	local progress = ScriptManager:getMissionProgress( missionIds.destroyDefenders );
	
	if progress % 5 == 0 or progress < 5 then 
	table.insert( queueTable, showDefenderMissionProgress );
	Utils:cutsceneQueue();
	end
end

function showDefenderMissionProgress()
	local progress = ScriptManager:getMissionProgress( missionIds.destroyDefenders );
	
	if progress <= 0 then
		ScriptManager:removeTrigger( "onEnemyDestroyed" );
		Utils:setMissionStatus( missionIds.destroyDefenders, MissionStatus.ACCOMPLISHED );
		
	else
		Utils:showMissionProgress( progress, Text.T_CAMP_L5_3_SECONDARY2_COUNTER );
	end
end


-- END Unit Stuff
-- BEGIN Plane Waves


function spawnPlaneWave()
	if spawnPlaneWaves == 1 then
		ScriptManager:removeTrigger( "spawnPlaneWave" );
		
		-- find a wave to spawn by random number
		local rnd = math.random ( 0, 2 );
		local spawnTable = 0;
		
		if rnd == 0 then
			spawnTable = planeWave1
		
		elseif rnd == 1 then
			spawnTable = planeWave2
		
		elseif rnd == 2 then
			spawnTable = planeWave3
		end
		
		for i = 1, #spawnTable do
			Utils:spawnUnitFromShortTable( 1, enemySquadIds.planeWave, spawnTable[i] );
		end
	end
end

function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.planeWave then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTable );
	end
end

function waveSquadPlaneDestroyed()
	if spawnPlaneWaves == 1 then
		-- old wave squad was destroyed, prepare spawn for the next round
		local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval
		ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );
	end;
end


-- END Plane Waves
-- BEGIN Building Stuff


function setAirfieldMission( missionStatus )
	ScriptManager:removeTrigger( "onAirfieldCaptured" );
	ScriptManager:removeTrigger( "onAirfieldDestroyed" );
	
	spawnPlaneWaves = 0;
	ScriptManager:storeValue( "spawnPlaneWaves", spawnPlaneWaves );
	
	Utils:setMissionStatus( missionIds.capAirfield, missionStatus );
end

function onAirfieldCaptured()
	setAirfieldMission( MissionStatus.ACCOMPLISHED );
end

function onAirfieldDestroyed()
	setAirfieldMission( MissionStatus.FAILED );
end

function setMainMission( triggerId, missionId )
	ScriptManager:removeTrigger( triggerId );
	
	Utils:setMissionStatus( missionId, MissionStatus.ACCOMPLISHED );
	checkForVictory();
end

function onFactoryCaptured()
	setMainMission( "onFactoryCaptured", missionIds.capFactory );
end

function onBaseCaptured()
	setMainMission( "onBaseCaptured", missionIds.capBase );
end


-- END Building Stuff
-- BEGIN Victory


function checkForVictory()
	if ScriptManager:getMissionStatus( missionIds.capBase )		== MissionStatus.ACCOMPLISHED and
	   ScriptManager:getMissionStatus( missionIds.capFactory )	== MissionStatus.ACCOMPLISHED then
		startVictoryCutscene()
	end
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_3_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_3_VICTORY_FLAVOR2, 6 );

	
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


function stopAttackingHint1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_HQ ); 
end

function stopAttackingHint2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.N_BUILDING_TANKFACTORY );
end

function stopAttackingHint3( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_AIRFIELD );
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


-- END Defeated