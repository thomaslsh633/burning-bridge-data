require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	capBridge	= 1,
	defBridge	= 2, -- on enemy reinforcement / attackers spawn
	capHq		= 3,
	getFactory	= 4,
	getOutpost	= 5,
	destroyArty	= 6,
	useScout	= 7,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.capBridge,		true,	Text.T_CAMP_L2_3_PRIMARY1,			100 },
	{ missionIds.defBridge,		true,	Text.T_CAMP_L2_3_PRIMARY2,			100 },
	{ missionIds.capHq,			true,	Text.T_MISSION_CAP_BASE,			100 },
	{ missionIds.destroyArty,	true,	Text.T_CAMP_L2_3_PRIMARY4,			100 },
	{ missionIds.getFactory,	false,	Text.T_MISSION_CAP_DESTROY_FACTORY,	 50 },
	{ missionIds.getOutpost,	false,	Text.T_MISSION_CAP_DESTROY_OUTPOST,	 50 },
	{ missionIds.useScout,		false,	Text.T_CAMP_L2_3_SECONDARY3,		 50 },
};

enemySquadIds = {
	firstAttackers	=  1;
	bridge			=  2;
	bridgeVanguard	=  3,
	outpost			=  4,
	factory			=  5,
	hq				=  6,
	eastVillage		=  7,
	seVillage		=  8,
	eastForest		=  9,
	arty1			= 10, -- howitzer1
	arty2			= 11, -- howitzer2
	arty3			= 12, -- aa
	arty4			= 13, -- mortar
	mg1				= 14,
	mg2				= 15,
	mg3				= 16,
	mg4				= 17,
	attackWave		= 19, -- spawn on left / bottom side to attack player's bridge
};

bridgeId	= 16;
hqId		= 12;
outpostId	=  2;
factoryId	= 13;

artyIds		= {  6,  5,  4,  3, }; -- first two will be camouflaged
bridgeIds	= { 32, 33, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44 };
villageIds	= { 14, 15, 34, 45, 46 };
factoryIds	= { 54, 55, 56, 57, 58 };
firstIds	= { 47, 48, 49 };
playerIds	= { 18, 17, 19, 20, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31 }

scoutArea = { 28, 33, 3, 9 };

spawnAttackers				= 0;
lastAttackersSpawnedInRound	= 0;
attackWaveRespawnInterval	= 4;
numberOfWavesSpawned		= 0;

bridgeAttackers1 =  {
	{ Units.X_INFANTRY_MG,		4, 0 },	
	{ Units.X_INFANTRY_AT,		6, 0 },
	{ Units.X_TANK_MEDIUM,		5, 0 },
};

bridgeAttackers2 =  {
	{ Units.X_INFANTRY_MG,		4, 0 },	
	{ Units.X_TANK_DESTROYER,	6, 0 },
	{ Units.X_INFANTRY_FLAME,	5, 0 },
	{ Units.X_TRUCK_MG,			7, 0 },
};

bridgeAttackers3 =  {
	{ Units.X_INFANTRY_MG,		4, 0 },
	{ Units.X_TANK_HEAVY,		5, 0 },
};

bridgeAttackers4 =  {
	{ Units.X_INFANTRY_MG,		4, 0 },	
	{ Units.X_INFANTRY_AT,		5, 0 },
	{ Units.X_INFANTRY_AT,		6, 0 },
	{ Units.X_INFANTRY_SNIPER,	7, 0 },
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:disableInteractionButton( InteractionButton.TRANSFORM );
	ScriptManager:disableInteractionButton( InteractionButton.DETONATE_BRIDGE );
	Utils:setIsAttackable( bridgeId, false );
	Utils:setIsAttackable( hqId, false );
	
	ScriptManager:gainGold( 0, 1500 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "spawnAttackers",					spawnAttackers );
	ScriptManager:storeValue( "lastAttackersSpawnedInRound",	lastAttackersSpawnedInRound );
	ScriptManager:storeValue( "numberOfWavesSpawned",			numberOfWavesSpawned );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.N_BRIDGE_L, -1, "showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.N_BRIDGE_L, -1, "transitionToFail",	"transitionToFail" );
	ScriptManager:addOnUnitCapturedTrigger(		0, Units.N_BRIDGE_L, -1, "onBridgeCaptured",	"onBridgeCaptured" );
	ScriptManager:addOnUnitCapturedTrigger(		1, Units.N_BRIDGE_L, -1, "enemyCapturedBridge", "enemyCapturedBridge" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, -1,				 -1, "checkForEnd",			"checkForEnd" );
	
	-- trigger for headquarter
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_HQ, hqId, "onHqCaptured", "onHqCaptured" );
	
	-- trigger for outpost
	ScriptManager:addOnUnitCapturedTrigger(  0, Units.X_BUILDING_HQ, outpostId, "onOutpostGotten", "onOutpostGotten" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_HQ, outpostId, "onOutpostGotten", "onOutpostGotten" );
	
	-- trigger for factory
	ScriptManager:addOnUnitCapturedTrigger(  0, Units.N_BUILDING_TANKFACTORY, -1, "onFactoryGotten", "onFactoryGotten" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_BUILDING_TANKFACTORY, -1, "onFactoryGotten", "onFactoryGotten" );
	
	-- trigger for artillery
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_MORTAR,		-1, "onArtyAttacked", "onArtyAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_EXTRARANGE,	-1, "onArtyAttacked", "onArtyAttacked" );
	
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_MORTAR,		-1, "onArtyDestroyed", "onArtyDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_EXTRARANGE,	-1, "onArtyDestroyed", "onArtyDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_AA,			-1, "onArtyDestroyed", "onArtyDestroyed" );
	
	-- enemy wave spawn
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart", false );
	
	--trigger for ai support
	ScriptManager:addOnOrderDefendRetreatTrigger( "callForSupport", "callForSupport" );
end

function loadValues()
	spawnAttackers				= ScriptManager:getValue( "spawnAttackers" );
	lastAttackersSpawnedInRound	= ScriptManager:getValue( "lastAttackersSpawnedInRound" );
	numberOfWavesSpawned		= ScriptManager:getValue( "numberOfWavesSpawned" );
end

function addAiOrders()
	local orderId;
	orderId = ScriptManager:addOrder( enemySquadIds.hq, -1, -1, hqId, 3, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_IS_IMPORTANT );
	ScriptManager:addOrder( enemySquadIds.hq, 17,  3, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.outpost, -1, -1, outpostId,	3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.outpost, 11, 23, -1,			3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.factory, -1, -1, factoryId,	3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.factory, 16, 31, -1,			3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.bridge,			 5, 15, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bridgeVanguard,	 4, 12, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.eastVillage,		16, 17, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.seVillage,		18, 10, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.eastForest,		18, 13, -1, 1, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.mg1,  6, 13, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mg2, 14, 13, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mg3, 12, 31, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mg4, 13, 28, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.firstAttackers, 4, 3, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	
	ScriptManager:addOrder( enemySquadIds.firstAttackers, 4, 3, -1, 3, AiOrder.DEFEND );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx( 17, 3, 0.7, 5, true );
	Utils:markUnit( 17, 3, 1, 3, false );	
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx( 8, 18, 0.7, 5, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_INTRO_FLAVOR3 );
	Utils:antiRush();
	
	ScriptManager:revealFogOfWar( 8, 18, 2, true );
	ScriptManager:wait( 3 );
	ScriptManager:revealFogOfWar( 8, 18, 2, false );
	Utils:antiRush();
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( 4, 3, 0.7, 4, false );
	Utils:antiRush();
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.capBridge,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.capHq,		MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.destroyArty, 0, #artyIds );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		 6, 20, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	10, 24, 42 );
	
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_FLAME, 9, 20, 42 );
end

function removeSquads()
	Utils:removeSquad( bridgeIds );
	Utils:removeSquad( villageIds );
	Utils:removeSquad( factoryIds );
	Utils:removeSquad( firstIds );
	Utils:removeSquad( playerIds );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Unit Stuff


function onArtyAttacked( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	if	attacker:getSquadId() >= enemySquadIds.arty1 and
		attacker:getSquadId() <= enemySquadIds.arty4 then
		ScriptManager:removeTrigger( "onArtyAttacked" );
		
		ScriptManager:storeValue( "defenderX", defender:getX() );
		ScriptManager:storeValue( "defenderY", defender:getY() );
		
		ScriptManager:runForPlayer( 0, "prepareArtyCutscene" );
	end
end

function prepareArtyCutscene()
	table.insert( queueTable, startArtyCutscene );
	Utils:cutsceneQueue();
end

function startArtyCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR2, 4 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR3 );
	ScriptManager:moveCameraEx( 6, 31, 0.8, 4, true );
	Utils:hideDialogue();
	
	ScriptManager:showScaledMarkerAt( 6, 31, 1.75 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR4, 4 );
	ScriptManager:removeAllMarkers();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR5 );
	ScriptManager:moveCameraEx( ScriptManager:getValue( "defenderX" ), ScriptManager:getValue( "defenderY" ), 0.7, 4, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionIds.destroyArty, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.useScout,	MissionStatus.IN_PROGRESS );
	
	-- trigger for scout plane destruction
	ScriptManager:addOnSpawnUnitTrigger( GlobalAbility.BLIMB, 0, -1, -1, "onScoutCalled", "onScoutCalled" );
		
	ScriptManager:deleteValue( "defenderX" );
	ScriptManager:deleteValue( "defenderY" );
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

function onScoutCalled( targetTileX, targetTileY, spawnedTileX, spawnedTileY, spawnedUnit )
	-- only trigger the mission when it is inside the target area
	if	spawnedTileY >= scoutArea[1] and spawnedTileY <= scoutArea[2] and
		spawnedTileX >= scoutArea[3] and spawnedTileX <= scoutArea[4] then
		
		ScriptManager:removeTrigger( "onScoutCalled" );
		Utils:setMissionStatus( missionIds.useScout, MissionStatus.ACCOMPLISHED );
		
		ScriptManager:addOnUnitDestroyedTrigger( 0, Units.L_PLANE_SCOUT, spawnedUnit:getId(), "onScoutDestroyed", "onScoutDestroyed")
	end
end

function onScoutDestroyed()
	ScriptManager:removeTrigger( "onScoutDestroyed" );
	
	ScriptManager:runForPlayer( 0, "prepareScoutDestroyedCutscene" );
end

function prepareScoutDestroyedCutscene()
	table.insert( queueTable, startScoutDestroyedCutscene );
	Utils:cutsceneQueue();
end

function startScoutDestroyedCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_SECONDARY3_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_SECONDARY3_FLAVOR2, 4 );
	
	Utils:endCutscene();
end

function onArtyDestroyed( arty )
	if	arty:getSquadId() >= enemySquadIds.arty1 and
		arty:getSquadId() <= enemySquadIds.arty4 then
		Utils:incrementMissionProgress( missionIds.destroyArty );
		
		ScriptManager:runForPlayer( 0, "prepareArtyMissionProgress" );
	end
end

function prepareArtyMissionProgress()
	table.insert( queueTable, showArtyMissionProgress );
	Utils:cutsceneQueue();
end

function showArtyMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyArty ) >= #artyIds then
		ScriptManager:removeTrigger( "onArtyDestroyed" );
		
		Utils:setMissionStatus( missionIds.destroyArty, MissionStatus.ACCOMPLISHED );
		checkForVictory();
		
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyArty ), Text.T_CAMP_L2_3_PRIMARY4_COUNTER );
	end
end


-- END Unit Stuff
-- BEGIN Wave & AI stuff


function onEnemyTurnStart( playerId, turnId, roundId )
	if roundId == 1 then
		-- reveals the village area for the ai so it can shoot there
		ScriptManager:revealFogOfWar( 11, 24, 3, true );
	end
	
	if spawnAttackers == 1 then
		--check if a wave spawns this round
		if lastAttackersSpawnedInRound + attackWaveRespawnInterval <= ScriptManager:getCurrentRound() then
			
			--define which wave will spawn
			local indicator = numberOfWavesSpawned % 4;
			local waveTable;
			
			if indicator == 1 then
				waveTable = bridgeAttackers1;
				
			elseif indicator == 2 then
				waveTable = bridgeAttackers2;
				
			elseif indicator == 3 then
				waveTable = bridgeAttackers3;
				
			else
				waveTable = bridgeAttackers4;
			end
			
			local squadId = enemySquadIds.attackWave + numberOfWavesSpawned;
			
			for i = 1, #waveTable do
				Utils:spawnUnitFromShortTable( 1, squadId, waveTable[i] );
			end
			
			local orderId = ScriptManager:addOrder( squadId, -1, -1, bridgeId, 2, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CONTINUE_TO_ATTACK );
			
			-- show cutscene to initiate def bridge mission
			if numberOfWavesSpawned == 0 then
				ScriptManager:runForPlayer( 0, "enemyReinforcements" );
			end
			
			numberOfWavesSpawned = numberOfWavesSpawned + 1;
			ScriptManager:storeValue( "numberOfWavesSpawned", numberOfWavesSpawned );
			
			lastAttackersSpawnedInRound = ScriptManager:getCurrentRound();
			ScriptManager:storeValue( "lastAttackersSpawnedInRound", lastAttackersSpawnedInRound );
		end
	end
end

function enemyReinforcements()
	table.insert( queueTable, startReinforcementCutscene );
	Utils:cutsceneQueue();
end

function startReinforcementCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_MISSION_REINFORCEMENTS_ENEMY );
	ScriptManager:moveCameraEx( 5, 4, 0.7, 5, true );
	
	ScriptManager:revealFogOfWar( 5, 4, 2, true );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY2_FLAVOR1, 5 );
	ScriptManager:revealFogOfWar( 5, 4, 2, false );
	
	ScriptManager:moveCameraEx( 8, 18, 0.7, 5, true );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.defBridge, MissionStatus.IN_PROGRESS );
end

function callForSupport( squadId, unitId, defPosX, defPosY, radius )
	if squadId == enemySquadIds.eastForest then
		ScriptManager:removeAllOrders( enemySquadIds.eastForest );
		ScriptManager:addOrder( enemySquadIds.eastForest, defPosX, defPosY, -1, 2, AiOrder.DEFEND );
	end
end


-- END Wave & AI Stuff
-- BEGIN Building Stuff


function onBridgeCaptured( capturer, bridge )
	ScriptManager:removeTrigger( "onBridgeCaptured" );
	
	-- disable movement for mortar and aa
	ScriptManager:disableComponent( artyIds[#artyIds], ComponentType.MOVEMENT, 0 );
	
	local orderId;
	for i = enemySquadIds.arty1, enemySquadIds.arty2 do
		orderId = ScriptManager:addOrder( i, 11, 24, -1, 4, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_ONLY_ATTACK_IN_AREA );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CONTINUE_TO_ATTACK );
	end
	
	ScriptManager:addOrder( enemySquadIds.arty3,  6, 31, -1, 4, AiOrder.DEFEND );-- aa
	ScriptManager:addOrder( enemySquadIds.arty4,  7, 30, -1, 5, AiOrder.DEFEND );-- mortar
		
	Utils:setMissionStatus( missionIds.capBridge, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 3 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY1_FLAVOR1 );
	ScriptManager:moveCameraEx( 11, 23, 0.7, 4, true );
	Utils:markUnit( 11, 23, 1, 2, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY1_FLAVOR2 );
	ScriptManager:moveCameraEx( 16, 31, 0.7, 6, true );
	Utils:markUnit( 16, 31, 1, 2, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY1_FLAVOR3 );
	ScriptManager:moveCameraEx( capturer:getX(), capturer:getY(), 0.7, 5, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();

	ScriptManager:setMissionStatus( missionIds.getOutpost, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.getFactory, MissionStatus.IN_PROGRESS );
	
	spawnAttackers = 1;
	ScriptManager:storeValue( "spawnAttackers", spawnAttackers );
	
	-- first wave should spawn sooner
	lastAttackersSpawnedInRound = ScriptManager:getCurrentRound() - 2
	ScriptManager:storeValue( "lastAttackersSpawnedInRound", lastAttackersSpawnedInRound );
	
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

function enemyCapturedBridge( capturingUnit, bridge )
	ScriptManager:removeTrigger( "enemyCapturedBridge" );
	
	-- give capturing squad and all other already spawned attackers a def order
	local squadId = capturingUnit:getSquadId();
	ScriptManager:storeValue( "bridgeCapturer", squadId );
	
	spawnAttackers = 0;
	ScriptManager:storeValue( "spawnAttackers", spawnAttackers );
	
	ScriptManager:runForPlayer( 0, "prepareEnemyBridgeCapturedCutscene" );
end

function prepareEnemyBridgeCapturedCutscene()
	table.insert( queueTable, startEnemyBridgeCapturedCutscene );
	Utils:cutsceneQueue();
end

function startEnemyBridgeCapturedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_PRIMARY1_FLAVOR5 );
	ScriptManager:moveCameraEx( 8, 18, 0.7, 4, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.capBridge, MissionStatus.IN_PROGRESS );
	
	-- see line 527, i save the squad id as mission progress
	local bridgeCaptureSquad = ScriptManager:getValue( "bridgeCapturer" );
	for i = bridgeCaptureSquad, enemySquadIds.attackWave + numberOfWavesSpawned do
		ScriptManager:removeAllOrders( i );
		
		ScriptManager:addOrder( i, -1, -1, bridgeId, 2, AiOrder.DEFEND );
	end
	
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BRIDGE_L, -1, "onBridgeRecaptured", "onBridgeRecaptured" );
end

function onBridgeRecaptured()
	Utils:setMissionStatus( missionIds.capBridge, MissionStatus.ACCOMPLISHED );
	
	if	ScriptManager:getMissionStatus( missionIds.destroyArty ) == MissionStatus.ACCOMPLISHED and 
		ScriptManager:getMissionStatus( missionIds.capHq )		 == MissionStatus.ACCOMPLISHED then
		startVictoryCutscene();
	
	else
		ScriptManager:removeTrigger( "onBridgeRecaptured" );
		
		local squadId = ScriptManager:getValue( "bridgeCapturer" );
		for i = squadId, enemySquadIds.attackWave + numberOfWavesSpawned do
			ScriptManager:removeAllOrders( i );
			
			local orderId = ScriptManager:addOrder( squadId, -1, -1, bridgeId, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CONTINUE_TO_ATTACK );
		end
		
		spawnAttackers = 1;
		ScriptManager:storeValue( "spawnAttackers", spawnAttackers );
		
		ScriptManager:addOnUnitCapturedTrigger(	1, Units.N_BRIDGE_L, -1, "enemyCapturedBridge", "enemyCapturedBridge" );
	end
end

function onOutpostGotten()
	ScriptManager:removeTrigger( "onOutpostGotten" );
	
	Utils:setMissionStatus( missionIds.getOutpost, MissionStatus.ACCOMPLISHED );
end

function onFactoryGotten()
	ScriptManager:removeTrigger( "onFactoryGotten" );
	
	Utils:setMissionStatus( missionIds.getFactory, MissionStatus.ACCOMPLISHED );
end

function onHqCaptured()
	ScriptManager:removeTrigger( "onHqCaptrued" );
	
	Utils:setMissionStatus( missionIds.capHq, MissionStatus.ACCOMPLISHED );
	checkForVictory();
end


-- END Building Stuff
-- BEGIN Victory


function checkForVictory()
	local artyStatus = ScriptManager:getMissionStatus( missionIds.destroyArty );
	local hqStatus	 = ScriptManager:getMissionStatus( missionIds.capHq );
	
	if artyStatus == MissionStatus.ACCOMPLISHED and hqStatus == MissionStatus.ACCOMPLISHED then
		if ScriptManager:getMissionStatus( missionIds.capBridge ) == MissionStatus.ACCOMPLISHED then
			startVictoryCutscene();
			
		else
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY1_FLAVOR4, 4 );
		end
	
	elseif artyStatus == MissionStatus.ACCOMPLISHED and hqStatus ~= MissionStatus.ACCOMPLISHED then
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY4_FLAVOR6, 5 );
	
	elseif artyStatus ~= MissionStatus.ACCOMPLISHED and hqStatus == MissionStatus.ACCOMPLISHED then
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY3_FLAVOR1, 3 );
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_PRIMARY3_FLAVOR2, 6 );
		
		Utils:endCutscene();
	end
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_3_VICTORY_FLAVOR2, 5 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	Utils:missionCheckerAccomplish( missionIds.defBridge );
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Victory
-- BEGIN Defeated


function checkForEnd()
	if ScriptManager:noUnitsLeftExt( { 0, Units.N_BRIDGE_L, Units.N_MINE_LAND } ) then
		ScriptManager:runForPlayer( 0, "missionFailed" );
	end
end

function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.N_BRIDGE_L );
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