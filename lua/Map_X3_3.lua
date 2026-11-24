require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

--[[ story summary
	player arrives on the street to the right just in time to help the allies in both towns ( N / S )
	the depot in the north and the tank factory in the south have to be kept intact ( airfield is irrelevant ). the bridge on the middle left is destroyed and 
	the enemy tries to repair it for additional units / pressure against the player.
	so keep the bridge destroyed, and your buildings intact until the enemy runs out of steam
--]]

-- mission stuff
missionIds = {
	defeatAttackers	= 1,
	keepDepot		= 2,
	keepFactory		= 3,
	bridgeDown		= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.defeatAttackers,	true,	Text.T_CAMP_X3_3_PRIMARY1,		100 },
	{ missionIds.keepDepot,			true,	Text.T_CAMP_X3_3_PRIMARY2,		100 },
	{ missionIds.keepFactory,		true,	Text.T_CAMP_X3_3_PRIMARY3,		 50 },
	{ missionIds.bridgeDown,		false,	Text.T_CAMP_X3_3_SECONDARY1,	 50 },
};

enemySquadIds = {
	wave1N			=  1,
	wave1S			=  2,
	wave2N			=  3,
	wave2S			=  4,
	wave3N			=  5,
	wave3S			=  6,
	wave4N			=  7,
	wave4S			=  8,
	wave5N			=  9,
	wave5S			= 10,
	wave6N			= 11,
	wave6S			= 12,
	wave7N			= 13,
	wave7S			= 14,
	wave8N			= 15,
	bridgeRepair	= 16,
	repairDef		= 17,
	waveC			= 18,
	repairAa		= 19,
};

nextSquadN	= 3; -- first wave already on the map so start @ second
nextSquadS	= 4; -- they count up after every wave by 2

showProgress = 0;

bridgeId	= 0;
factoryId	= 1;
airfieldId	= 2;
depotId		= 3;

bridgeDefSpawn		= { { 0, 19 }, { 0, 17 } };
bridgeRepairId		=   -1; -- set when first engineer spawns
bridgeMaxHp			= 1200;
destroyedEngineers	=    0;
mortarId			=   -1;
aaId				=   -1;

playerIntroUnits = {
	{ Units.X_INFANTRY_MG,		12, 13 },
	{ Units.X_TANK_MEDIUM,		12, 14 },
	{ Units.X_TRUCK_MG,			13, 14 },
	{ Units.X_INFANTRY_FLAME,	13, 13 },
	{ Units.X_TRUCK_AA,			14, 14 },
};

pCutsceneUnits	= { 
	firstBlood	= 35,
	attackedMg	=  6,
	secondBlood	= 36,
};

eCutsceneUnits	= {
	attackerMgN		= 23,
	attackerTankN	= 25,
	movingMgN		= 24,
	attackerAtN		= 26,
	attackerTankS	= 29,
	attackerMgS		= 30,
	movingMgS		= 31,
};

enemyWave1N = {
	{ Units.L_INFANTRY_MG, 0, 26 },
	{ Units.L_INFANTRY_MG, 0, 27 },
	{ Units.L_INFANTRY_AT, 0, 25 },
	{ Units.L_PLANE_LIGHT, 0, 24 },
};

enemyWave2N = {
	{ Units.L_TRUCK_MG,			0, 26 },
	{ Units.L_TRUCK_AA,			0, 27 },
	{ Units.L_INFANTRY_MORTAR,	0, 25 },
	{ Units.L_PLANE_LIGHT,		0, 24 },
};

enemyWave3N = {
	{ Units.L_TANK_LIGHT,		0, 27 },
	{ Units.L_INFANTRY_MG,		0, 25 },
	{ Units.L_INFANTRY_SNIPER,	0, 26 },
};

enemyWave4N = {
	{ Units.L_INFANTRY_MG,	1, 26 },
	{ Units.L_INFANTRY_AT,	0, 27 },
	{ Units.L_TANK_MEDIUM,	0, 25 },
};


enemyWave1S = {
	{ Units.L_INFANTRY_MG,	0, 3 },
	{ Units.L_TANK_LIGHT,	0, 1 },
	{ Units.L_TRUCK_AA,		0, 2 },
	{ Units.L_PLANE_LIGHT,	0, 4 },
};

enemyWave2S = {
	{ Units.L_TANK_MEDIUM,	0, 2 },
	{ Units.L_INFANTRY_AT,	0, 3 },
	{ Units.L_PLANE_LIGHT,	0, 4 },
	{ Units.L_PLANE_HEAVY,	0, 1 },
};

enemyWave3S = {
	{ Units.L_TANK_MEDIUM,	0, 1 },
	{ Units.L_TRUCK_AA,		0, 3 },
	{ Units.L_INFANTRY_AT,	0, 2 },
	{ Units.L_PLANE_LIGHT,	0, 4 },
};

enemyWave4S = {
	{ Units.L_TANK_LIGHT,		0, 3 },
	{ Units.L_TANK_DESTROYER,	0, 1 },
	{ Units.L_PLANE_HEAVY,		0, 2 },
};


enemyWave1C = {
	{ Units.L_TANK_LIGHT,	0, 18 },
	{ Units.L_INFANTRY_MG,	0, 17 },
}

enemyWave2C = {
	{ Units.L_INFANTRY_MORTAR,	0, 18 },
	{ Units.L_INFANTRY_FLAME,	0, 17 },
}

enemyWave3C = {
	{ Units.L_TRUCK_MG,		0, 18 },
	{ Units.L_INFANTRY_AT,	0, 17 },
}

enemyWave4C = {
	{ Units.L_TANK_DESTROYER,	0, 18 },
	{ Units.L_INFANTRY_SNIPER,	0, 17 },
}


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:setInstantDestroyed(	bridgeId, true );
	
	ScriptManager:gainGold( 0, 1000 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "nextSquadN",			nextSquadN );
	ScriptManager:storeValue( "nextSquadS",			nextSquadS );
	ScriptManager:storeValue( "destroyedEngineers",	destroyedEngineers );
	ScriptManager:storeValue( "mortarId",			mortarId );
	ScriptManager:storeValue( "aaId",				aaId );
	ScriptManager:storeValue( "showProgress",		showProgress );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	--trigger for secondary intro
	ScriptManager:addOnTurnStartTrigger( 0, -1, 1, "startSecondaryIntroCutscene", "startSecondaryIntroCutscene" );
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_BUILDING_HQ,			-1, "showAttackedWarning1", "showAttackedWarning1" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.N_BUILDING_TANKFACTORY,	-1, "showAttackedWarning2", "showAttackedWarning2" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_BUILDING_AIRFIELD,	-1, "showAttackedWarning3", "showAttackedWarning3" );
	
	ScriptManager:addOnBridgeRepairTrigger( -1, -1,	-1,			"onAiRepairedBridge",		"onAiRepairedBridge" );
	ScriptManager:addOnUnitCapturedTrigger(  0, -1, bridgeId,	"onPlayerCapturedBridge",	"onPlayerCapturedBridge" );
	
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.X_BUILDING_HQ,			-1, "transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.N_BUILDING_TANKFACTORY,	-1, "transitionToFail", "transitionToFail" );
	
	-- trigger for enemy waves
	ScriptManager:addOnTurnStartTrigger(	 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onEnemyDestroyed", "onEnemyDestroyed" );
	
	ScriptManager:addOnAiCalculationTrigger( true, "checkForOrders", "checkForOrders" );
end

function loadValues()
	nextSquadN			= ScriptManager:getValue( "nextSquadN" );
	nextSquadS			= ScriptManager:getValue( "nextSquadS" );
	destroyedEngineers	= ScriptManager:getValue( "destroyedEngineers" );
	mortarId			= ScriptManager:getValue( "mortarId" );
	aaId				= ScriptManager:getValue( "aaId" );
	showProgress		= ScriptManager:getValue( "showProgress" );
end

function addAiOrders()
	
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_INTRO_FLAVOR1 );
	local unit
	for i = 1, #playerIntroUnits do
		unit = ScriptManager:spawnUnit( 0, playerIntroUnits[i][1], 15, 14, 0 );
		ScriptManager:moveUnitEx( unit:getId(), playerIntroUnits[i][2], playerIntroUnits[i][3], true );
		ScriptManager:wait( 0.5 );
	end
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx( 8, 25, 0.7, 4, true );
	
	moveAndAttack( eCutsceneUnits.attackerMgN,	 pCutsceneUnits.firstBlood, 8, 24 )
	moveAndAttack( eCutsceneUnits.attackerTankN, pCutsceneUnits.firstBlood, 8, 26 )
	
	ScriptManager:moveCameraEx( 8, 21, 0.7, 2, true );
	ScriptManager:moveUnitEx( eCutsceneUnits.movingMgN, 7, 22, true );
	
	moveAndAttack( eCutsceneUnits.attackerAtN, pCutsceneUnits.attackedMg, 6, 20 )
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 6, 5, 0.7, 6, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_INTRO_FLAVOR4 );
	
	moveAndAttack( eCutsceneUnits.attackerTankS, pCutsceneUnits.secondBlood, 6, 6 )
	moveAndAttack( eCutsceneUnits.attackerMgS,	 pCutsceneUnits.secondBlood, 6, 5 )
	
	ScriptManager:moveUnitEx( eCutsceneUnits.movingMgS, 5, 3, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	local orderId = ScriptManager:addOrder( enemySquadIds.wave1N, 12, 23, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.wave1S, 11, 7, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	startTheMission();
end

function moveAndAttack( attackerId, defenderId, moveX, moveY )
	ScriptManager:moveUnitEx( attackerId, moveX, moveY, true );
	ScriptManager:wait( 0.5 );
	
	ScriptManager:attackUnitEx( attackerId, defenderId, true );
	ScriptManager:wait( 0.5 );
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.defeatAttackers,	MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.bridgeDown,		 0, -1 );
	Utils:setMissionProgress( missionIds.defeatAttackers,	10, 55 ); -- 10 starting enemy units; 55 is an estimated guess based on avg. unit / wave x total waves
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		13, 16, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	12, 15, 42 );
	ScriptManager:spawnUnit( 0, Units.SHORTSIGHTED_GOD,		13, 15, 42 );
end

function removeSquads()
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end

function startSecondaryIntroCutscene()
	ScriptManager:removeTrigger( "startSecondaryIntroCutscene" );
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_INTRO_FLAVOR5, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_INTRO_FLAVOR6, 4 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionIds.keepDepot,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.keepFactory,	MissionStatus.IN_PROGRESS );
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end


-- END Intro Cutscene
-- BEGIN Enemy Waves


function onEnemyTurnStart( playerId, turnId, roundId )
	-- spawn waves in a 15 turn pattern, after that the player has to destroy all remaining
	-- north spawn on turn: 0, 1, 3, 5, 7, 9, 12, 14 | south spawn on turn: 0, 2, 5, 6, 8, 11, 14
	-- engineer spawn on turn 2; after kill respawn of 2
	-- north gets one more wave because south has to watch bridge too
	
	-- south waves
	if roundId == 0 or roundId == 1 or roundId == 2 or roundId == 5 or roundId == 7 or roundId == 8 or roundId == 9 or roundId == 10 or roundId == 12 then
		spawnWaveSouth();
	end
	
	-- north waves
	if roundId == 0 or roundId == 1 or roundId == 3 or roundId == 5 or roundId == 6 or roundId == 8 or roundId == 9 or roundId == 11 or roundId == 12 then
		spawnWaveNorth();
	end
	
	if roundId == 2 then
		if ScriptManager:getMissionStatus( missionIds.bridgeDown ) ~= MissionStatus.FAILED then
			spawnNewEngineer();
			ScriptManager:runForPlayer( 0, "prepareBridgeCutscene" );
		end
		
	elseif roundId == 12 then
		ScriptManager:removeTrigger( "onEnemyTurnStart" );
		ScriptManager:runForPlayer( 0, "prepareAlmostDoneCutscene" );
	end
end

function spawnWaveSouth()
	spawnWave( nextSquadS, "S" );
	
	ScriptManager:storeValue( "nextSquadS", nextSquadS + 2 );
end

function spawnWaveNorth()
	spawnWave( nextSquadN, "N" );
	
	ScriptManager:storeValue( "nextSquadN", nextSquadN + 2 );
end

function spawnWave( squadId, waveStartingPoint )
	local rng = math.random( 1, 4 );
	local spawnTable = _G["enemyWave" .. rng .. waveStartingPoint ];
	local unitId;
	for i = 1, #spawnTable do
		unitId = Utils:spawnUnitFromShortTable( 1, squadId, spawnTable[i] );
	end
	
	if waveStartingPoint == "C" then
		ScriptManager:storeValue( "waveUnitC", unitId );
	end
	
	local newProgress = ScriptManager:getMissionProgress( missionIds.defeatAttackers ) + #spawnTable;
	ScriptManager:setMissionProgress( missionIds.defeatAttackers, newProgress );
	print( newProgress );
	
	addWaveOrder( squadId, waveStartingPoint );
end

function addWaveOrder( squadId, waveStartingPoint )
	local targetX, targetY;
	if waveStartingPoint == "N" then
		-- choose one of the two ways on top randomly
		local rng = math.random( 0, 1 );
		if rng == 1 then
			local orderId = ScriptManager:addOrder( squadId, 9, 19, -1, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
		targetX = 12;
		targetY = 23;
	
	else
		targetX = 11;
		targetY =  7;
		
		if waveStartingPoint == "C" then
			local bridge = Unit:getUnitById( bridgeId );
			
			if bridge:getPlayerId() == 0 then
				local orderId = ScriptManager:addOrder( squadId, -1,  -1, bridgeId, 3, AiOrder.ATTACK );
				ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
			end
		end
	end
	
	local orderId = ScriptManager:addOrder( squadId, targetX, targetY, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end

function prepareAlmostDoneCutscene()
	table.insert( queueTable, startAlmostDoneCutscene );
	Utils:cutsceneQueue();
end

function startAlmostDoneCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_PRIMARY1_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_PRIMARY1_FLAVOR2, 4 );
	
	Utils:endCutscene();
	showProgress = 1;-- show the mission progress from now on
	ScriptManager:storeValue( "showProgress", showProgress );
	
	showAttackerMissionProgress(); -- show the player how many enemies are still left
end

function onEnemyDestroyed( unit )
	local squadId = unit:getSquadId();
	
	if squadId <= enemySquadIds.wave8N or squadId == enemySquadIds.waveC then -- highest wave squad, so all previous are also wave squads
		Utils:decrementMissionProgress( missionIds.defeatAttackers );
		print( ScriptManager:getMissionProgress( missionIds.defeatAttackers ) );
		
		if showProgress == 1 then
			local progress = ScriptManager:getMissionProgress( missionIds.defeatAttackers );
			if progress % 5 == 0 or progress < 5 then -- show progress only every 5th unit / when its close to the end
				ScriptManager:runForPlayer( 0, "prepareAttackerMissionProgress" );
			end
		end
		
	elseif squadId == enemySquadIds.repairDef and unit:getTemplateId() ~= Units.L_INFANTRY_MORTAR then
		Utils:decrementMissionProgress( missionIds.bridgeDown );
	end
end

function prepareAttackerMissionProgress()
	table.insert( queueTable, showAttackerMissionProgress );
	Utils:cutsceneQueue();
end

function showAttackerMissionProgress()
	local progress = ScriptManager:getMissionProgress( missionIds.defeatAttackers );
	if progress <= 0 then
		Utils:setMissionStatus( missionIds.defeatAttackers, MissionStatus.ACCOMPLISHED );
		startVictoryCutscene();
	
	else
		Utils:showMissionProgress( progress, Text.T_CAMP_X3_3_PRIMARY_COUNTER );
	end
end

function checkForOrders( squadId, mainOrderData, allMainOrderData )
	-- checks if squads have no orders and gives them their orders again
	if ScriptManager:getSquadOrderCount( squadId ) == 0 then
		print( squadId .. " has no orders!" );
		
		if squadId <= 15 then -- north or south
			if squadId % 2 == 1 then -- north wave
				addWaveOrder( squadId, "N" );
			
			else -- south wave
				addWaveOrder( squadId, "S" );
			end
		
		elseif squadId == 16 then -- bridge repair
			bridgeRepairOrder();
		
		elseif squadId == 17 then -- repair def
			bridgeDefOrder();
		
		elseif squadId == 18 then -- center wave
			addWaveOrder( squadId, "C" );
		end
	end
end


-- END Enemy Waves
-- BEGIN Bridge Repair


function prepareBridgeCutscene()
	table.insert( queueTable, startBridgeCutscene );
	Utils:cutsceneQueue();
end

function startBridgeCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_SECONDARY1_FLAVOR1 );
	ScriptManager:moveCameraEx( 3, 15, 0.7, 4, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_SECONDARY1_FLAVOR2 );
	ScriptManager:revealFogOfWar( 3, 15, 2, true );
	ScriptManager:wait( 4 );
	ScriptManager:revealFogOfWar( 3, 15, 2, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_3_SECONDARY1_FLAVOR3 );
	
	ScriptManager:moveCameraEx( 12, 6, 0.7, 5, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.bridgeDown, MissionStatus.IN_PROGRESS );
end

function spawnNewEngineer()
	ScriptManager:removeTrigger( "spawnNewEngineer" );
	
	-- dont bother spawning engineer at this point because he wont reach the bridge before the last wave spawns
	if ScriptManager:getCurrentRound() < 13 then
		local unit = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 0, 17, enemySquadIds.bridgeRepair );
		
		bridgeRepairId = unit:getId();
		ScriptManager:storeValue( "bridgeRepairId", bridgeRepairId );
		
		ScriptManager:removeAllOrders( enemySquadIds.bridgeRepair );
		ScriptManager:addOrder( enemySquadIds.bridgeRepair, 4, 14, -1, 1, AiOrder.MOVE );
		
		ScriptManager:addOnEnterTileTrigger( 3, 15,  1, Units.L_INFANTRY_ENGINEER,	-1, true,	"startRepairing",		"startRepairing" );
		ScriptManager:addOnUnitDestroyedTrigger(	 1, Units.L_INFANTRY_ENGINEER,	-1,			"onEngineerDestroyed",	"onEngineerDestroyed" );
		
		-- spawn bridge defenders only if previous defenders were eliminated. mission progress indicates that
		for i = ScriptManager:getMissionProgress( missionIds.bridgeDown ) + 1, 2 do
			ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, bridgeDefSpawn[i][1], bridgeDefSpawn[i][2], enemySquadIds.repairDef );
		end
		ScriptManager:setMissionProgress( missionIds.bridgeDown, 2 );
		
		ScriptManager:removeAllOrders( enemySquadIds.repairDef );
		ScriptManager:addOrder( enemySquadIds.repairDef, -1, -1, bridgeRepairId, 1, AiOrder.DEFEND );
		ScriptManager:addOrder( enemySquadIds.repairDef,  4, 14, -1,			 1, AiOrder.DEFEND );
		
		-- after the first engineer has been defeated the next ones will get a mortar to use smoke on the area and an anti air
		if destroyedEngineers >= 1 then
			if mortarId == -1 then
				unit = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MORTAR, 0, 16, enemySquadIds.repairDef );
				
				mortarId = unit:getId();
				ScriptManager:storeValue( "mortarId", mortarId );
				
				ScriptManager:addOnTurnEndTrigger( 		 1, -1,						 -1,		"smokeScreenOnBridge",	"smokeScreenOnBridge" );
				ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_INFANTRY_MORTAR, mortarId,	"mortarDestroyed",		"mortarDestroyed" );
			end
			
			if aaId == -1 then
				unit = ScriptManager:spawnUnit( 1, Units.L_TRUCK_AA, 0, 18, enemySquadIds.repairAa );
				
				ScriptManager:addOrder( enemySquadIds.repairAa, 5, 16, -1, 1, AiOrder.DEFEND );
				
				aaId = unit:getId();
				ScriptManager:storeValue( "aaId", aaId );
				
				ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_TRUCK_AA, aaId,	"aaDestroyed", "aaDestroyed" );
			end
		end
	end
end

function bridgeRepairOrder()
	ScriptManager:addOrder( enemySquadIds.bridgeRepair, 4, 14, -1, 1, AiOrder.MOVE );
end

function bridgeDefOrder()
	ScriptManager:addOrder( enemySquadIds.repairDef, 2, 14, -1, 3, AiOrder.DEFEND );
end

function smokeScreenOnBridge()
	if mortarId ~= -1 then
		ScriptManager:smokeTile( mortarId, 3, 15, true );
		ScriptManager:addOnTurnEndTrigger( 1, -1, ScriptManager:getCurrentRound() + 2, "smokeScreenOnBridge", "smokeScreenOnBridge" );
	end
end

function mortarDestroyed()
	ScriptManager:removeTrigger( "mortarDestroyed" );
	ScriptManager:removeTrigger( "smokeScreenOnBridge");
	
	mortarId = -1;
	ScriptManager:storeValue( "mortarId", mortarId );
end

function aaDestroyed()
	ScriptManager:removeTrigger( "aaDestroyed" );
	
	aaId = -1;
	ScriptManager:storeValue( "aaId", aaId );
end

function startRepairing( tileX, tileY, playerId, unitTemplateId, unitId )
	ScriptManager:removeTrigger( "startRepairing" );
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "aiRepairBridge", "aiRepairBridge" );
end

function aiRepairBridge()
	local unit = Unit:getUnitAt( 3, 15 );
	
	if unit:getTemplateId() == Units.L_INFANTRY_ENGINEER then
		ScriptManager:repairBridge( unit:getId(), bridgeId, true );
	end
end

function onAiRepairedBridge( engineer, bridge )
	local bridgeHp			= bridge:getHealth();
	
	if bridgeHp >= bridgeMaxHp then
		ScriptManager:removeTrigger( "startRepairing" );
		ScriptManager:removeTrigger( "aiRepairBridge" );
		ScriptManager:removeTrigger( "onAiRepairedBridge" );
		ScriptManager:removeTrigger( "onEngineerDestroyed" );
		ScriptManager:removeTrigger( "smokeScreenOnBridge" );
		ScriptManager:removeTrigger( "mortarDestroyed" );
		
		Utils:setMissionStatus( missionIds.bridgeDown, MissionStatus.FAILED );
		
		ScriptManager:removeAllOrders( enemySquadIds.repairDef );
		ScriptManager:addOrder( enemySquadIds.repairDef, 5, 12, -1, 1, AiOrder.DEFEND );
		
		-- the enigneer builds an mg nest on a free position and ( hopefully ) enters it
		local engineerPlayer	= engineer:getPlayerId();
		if engineerPlayer == 1 then
			local unit = Unit:getUnitAt( 4, 16 );
			if unit == nil then
				unit = ScriptManager:spawnUnit( -1, Units.N_EMPLACEMENT_MG_NEST, 4, 16, enemySquadIds.bridgeRepair );
				local mgNestId = unit:getId();
				
				-- get a new engineer cause this one cant enter mgnest #cheatingAi
				ScriptManager:removeUnitEx( bridgeRepairId, true );
				unit = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 3, 15, enemySquadIds.bridgeRepair );
				
				ScriptManager:loadUnitIntoTransporterEx( mgNestId, unit:getId(), true );
				
				ScriptManager:removeAllOrders( enemySquadIds.bridgeRepair );
				ScriptManager:addOrder( enemySquadIds.bridgeRepair, 4, 16, -1, 3, AiOrder.DEFEND );
				
			else -- if there is no space for an mg nest, fleeeeeee!!!!!!
				local engineer = Unit:getUnitById( bridgeRepairId );
				engineer:setActionPoints( 4 ); -- give engineer some action points to be able to move again after the repair earlier #cheatingAi
				
				ScriptManager:moveUnitEx(	bridgeRepairId, 1, 18, true );
				ScriptManager:removeUnitEx( bridgeRepairId, true );
			end
		end
		ScriptManager:addOnTurnStartTrigger( 1, -1, -1,						"spawnWaveCenter",		"spawnWaveCenter" );
		ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.waveC,		"centerWaveDestroyed",	"centerWaveDestroyed" );
		ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_BRIDGE_L, -1,	"bridgeDestroyed", 		"bridgeDestroyed" );
	end
end

function spawnWaveCenter()
	ScriptManager:removeTrigger( "spawnWaveCenter" );
	spawnWave( enemySquadIds.waveC, "C" );
end

function centerWaveDestroyed()
	local nextSpawn = ScriptManager:getCurrentRound() + 2;
	if nextSpawn <= 14 then
		ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawn, "spawnWaveCenter", "spawnWaveCenter" );
	
	else
		ScriptManager:removeTrigger( "centerWaveDestroyed" );
		ScriptManager:removeTrigger( "bridgeDestroyed" );
	end
end

function onPlayerCapturedBridge()
	local id = ScriptManager:getValue( "waveUnitC" );
	if id ~= -1 then
		local unit = Unit:getUnitById( id );
		local unitX	= unit:getX();
		local unitY = unit:getY();
		
		-- if player captured the bridge and the ai unit is still on the small island, capture it back!
		-- otherwise continue with the attack
		if unitY > 12 then
			ScriptManager:removeAllOrders( enemySquadIds.waveC );
			addWaveOrder( enemySquadIds.waveC, "C" )
		end
	end
end

function bridgeDestroyed()
	ScriptManager:removeTrigger( "spawnWaveCenter" );
	ScriptManager:removeTrigger( "centerWaveDestroyed" );
	ScriptManager:removeTrigger( "bridgeDestroyed" );
end

function onEngineerDestroyed()
	destroyedEngineers = destroyedEngineers + 1;
	ScriptManager:storeValue( "destroyedEngineers", destroyedEngineers );
	
	ScriptManager:removeTrigger( "startRepairing" );
	ScriptManager:removeTrigger( "aiRepairBridge" );
	ScriptManager:removeTrigger( "onAiRepairedBridge" );
	ScriptManager:removeTrigger( "onEngineerDestroyed" );
	
	ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 2, "spawnNewEngineer", "spawnNewEngineer" );
end


-- END Bridge Repair
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_VICTORY_FLAVOR2, 7 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_3_VICTORY_FLAVOR3, 5 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:setMissionStatus( missionIds.keepDepot,	MissionStatus.ACCOMPLISHED );
	ScriptManager:setMissionStatus( missionIds.keepFactory,	MissionStatus.ACCOMPLISHED );
	
	Utils:missionCheckerAccomplish( missionIds.bridgeDown );
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Victory
-- BEGIN Defeated


function showAttackedWarning1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ );
end

function showAttackedWarning2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.N_BUILDING_TANKFACTORY );
end

function showAttackedWarning3( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_AIRFIELD );
end

function transitionToFail()
	queueTable = {};
	ScriptManager:runForPlayer( 0, "missionFailed" );
end

function missionFailed()
	queueTable = {};
	Utils:disablePlayerInteraction();
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle( Text.T_MISSION_FAILED );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Defeated