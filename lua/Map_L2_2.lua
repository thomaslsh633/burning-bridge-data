require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	capFactories	= 1,
	getAirfield		= 2,
	getDepot		= 3,
	destroyTanks	= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.capFactories,	true,	Text.T_CAMP_L2_2_PRIMARY,			 100 },
	{ missionIds.getAirfield,	false,	Text.T_MISSION_CAP_DESTROY_AIRFIELD,  50 },
	{ missionIds.getDepot,		false,	Text.T_MISSION_CAP_OUTPOST,			  50 },
	{ missionIds.destroyTanks,	false,	Text.T_CAMP_L2_2_SECONDARY3,		  50 },
};

enemySquadIds = {
	factory1		=  1,
	factory2		=  2,
	factory3		=  3,
	airfield		=  4,
	outpost			=  5,
	forestAmbush1	=  6, 
	forestAmbush2	=  7,
	firstAttackers	=  8,
	mines			=  9,
	planeAttackWave = 10,
	reinforcements1	= 11, -- spawn from the street north
	reinforcements2	= 12, -- spawn from the street northeast
	reinforcements3	= 13, -- spawn from the street southeast
	forestDefense	= 14,
	buildings		= 15,
	mgNest1			= 16,
	mgNest2			= 17,
	mgNest4			= 19,
	mgNest5			= 20,
	mgNest6			= 21,
	mgNest7			= 22,
	mgNest8			= 23,
};

tanksToDestroy		= 7;
outpostId			= 5;
airfieldId			= 0;
factoryIds			= { 2, 3, 4 };
factoryUnitRemove	= { Units.L_INFANTRY_MG,	 Units.L_INFANTRY_AT,		Units.L_INFANTRY_MORTAR, Units.L_INFANTRY_FLAME,
						Units.L_INFANTRY_SNIPER, Units.L_INFANTRY_ENGINEER, Units.L_TRUCK_SUPPLY,	 Units.L_TRUCK_TRANSPORT };
ambushIds			= { 33, 34, 36, 37, 38, 41, 42, 43, 44, 62, 63, 64, 65, 66 }; -- forestAbmush1 + forestAmbush2
mineIds				= { 52, 53, 54, 55, 56, 57, 58, 59, 60 };

reinforcement1Table	= { {  8, 14 }, { 14, 10 }, };
reinforcement2Table	= { { 26,  8 }, { 27, 14 }, };
reinforcement3Table	= { { 26,  8 }, { 28,  3 }, };
airplaneTable		= { { 25, 14 }, { 21,  5 }, { 15, 13 }, { 10, 10 }, { 7, 16 }, { 17, 13 }, { 26, 2 }, };

planeWaveRespawnInterval = 3; -- respawn rate after previous spawn was destroyed
planeAttackWaveUnits = {
--	templateID, 		tileX, tileY
	{ Units.X_PLANE_LIGHT,	28, 10 },
	{ Units.X_PLANE_LIGHT,	28,  9 },
};

enemyReinforcementUnits1 = {
--	templateID, 		tileX, tileY
	{ Units.X_INFANTRY_MG,	7, 18 },
	{ Units.X_INFANTRY_AT,	8, 18 },
	{ Units.X_TANK_MEDIUM,	7, 17 },
};

enemyReinforcementUnits2 = {
--	templateID, 		tileX, tileY
	{ Units.X_INFANTRY_AT,		27, 18 },
	{ Units.X_TANK_DESTROYER,	28, 18 },
	{ Units.X_INFANTRY_FLAME,	28, 17 },
};

enemyReinforcementUnits3 = {
--	templateID, 		tileX, tileY
	{ Units.X_INFANTRY_MG,	27, 1 },
	{ Units.X_TRUCK_MG,		25, 1 },
	{ Units.X_TANK_HEAVY,	26, 1 },
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	addAiOrders();
	
	for i = 1, #factoryIds do
		Utils:setIsAttackable( factoryIds[i], false );
	end
	
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:storeValue( "forestAmbushTriggered", 0 );
	ScriptManager:storeValue( "enemyReinforcements2Triggered", 0 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_BUILDING_HQ, -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_BUILDING_HQ, -1,	"transitionToFail",		"transitionToFail" );
	
	-- trigger for factories
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BUILDING_TANKFACTORY, -1, "onFactoryCaptured", "onFactoryCaptured" );
	
	-- trigger for airfields
	ScriptManager:addOnUnitCapturedTrigger(	 0, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldGotten", "onAirfieldGotten" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldGotten", "onAirfieldGotten" );
	
	-- trigger for outpost
	ScriptManager:addOnUnitCapturedTrigger(	 0, Units.X_BUILDING_HQ, -1, "onOutpostCaptured",	"onOutpostGotten" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_HQ, -1, "onOutpostDestroyed",	"onOutpostGotten" );
	
	-- trigger for secondary intro cutscene
	ScriptManager:addOnTurnStartTrigger( 0, -1, 1, "prepareSecondaryIntroCutscene", "prepareSecondaryIntroCutscene" );
	
	-- trigger for tanks
	for i = Units.X_TANK_MEDIUM, Units.X_TANK_DESTROYER do
		ScriptManager:addOnUnitHasAttackedTrigger(	-1, i, -1, "onTankHasAttacked",	"onTankHasAttacked" );
		ScriptManager:addOnUnitDestroyedTrigger(	 1, i, -1, "onTankDestroyed",	"onTankDestroyed" );
	end
	
	-- trigger for forest ambush
	Utils:addOnEnterAreaTrigger( 20, 8, 3, 0, -1, -1, false, "triggerForestAmbushTile", "triggerForestAmbush" );
	ScriptManager:addOnUnitSightedTrigger( 0, -1, -1, false, "triggerForestAmbushSeen", "triggerForestAmbush" );
	
	-- trigger for enemy reinforcements
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, "spawnEnemyReinforcements1", "spawnEnemyReinforcements1" );
	for y = 1, 18 do
		ScriptManager:addOnEnterTileTrigger( 25, y, 0, -1, -1, false, "spawnEnemyReinforcements2", "spawnEnemyReinforcements2" );
	end
	
	-- trigger for wavespawn
	ScriptManager:addOnAiCalculationTrigger(	true, 							"checkWaypoints",		"checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger(	enemySquadIds.planeAttackWave,	"waveSquadDestroyed",	"waveSquadDestroyed" );
	ScriptManager:addOnOrderDefendSupportTrigger( 								"factorySupport",		"factorySupport" );
end

function addAiOrders()
	-- give orders
	local orderId;
	orderId = ScriptManager:addOrder( enemySquadIds.factory1, -1, -1, factoryIds[1], 2, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_IS_IMPORTANT );
	ScriptManager:addOrder( enemySquadIds.factory1, 8, 15, -1, 2, AiOrder.DEFEND );
	
	orderId = ScriptManager:addOrder( enemySquadIds.factory2, -1, -1, factoryIds[2], 3, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_IS_IMPORTANT );
	ScriptManager:addOrder( enemySquadIds.factory2, 25, 14, -1, 3, AiOrder.DEFEND );
	
	orderId = ScriptManager:addOrder( enemySquadIds.factory3, -1, -1, factoryIds[3], 3, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_IS_IMPORTANT );
	ScriptManager:addOrder( enemySquadIds.factory3, 26,  2, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.airfield, -1, -1, airfieldId,	3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.airfield, 26,  8, -1,			3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.outpost, -1, -1, outpostId,	2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.outpost, 14, 11, -1,			2, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.forestDefense,	22, 16, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest1,			 7, 11, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest2,			23,  8, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest4,			22,  3, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest5,			11,  7, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest6,			 9,  1, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest7,			15,  1, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNest8,			18,  7, -1, 3, AiOrder.DEFEND );
	
	orderId = ScriptManager:addOrder( enemySquadIds.firstAttackers, 3, 3, -1, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	
	ScriptManager:addOrder( enemySquadIds.firstAttackers, 3, 3, -1, 2, AiOrder.DEFEND );
	
	-- camouflage ambush squads
	Utils:camouflageSquad( ambushIds );
	
	-- prepare first squad spawning
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval - 1;
	ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewWave", "spawnNewWave" );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_INTRO_FLAVOR1 );
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 8, 15, 0.7, 5, false );
	ScriptManager:wait( 2 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_INTRO_FLAVOR2 );
	ScriptManager:wait( 3 );
	
	Utils:markUnit( 8, 15, 1, 3, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 26, 10, 0.3, 6, true );
	
	ScriptManager:revealFogOfWar( 25, 14, 1, true );
	ScriptManager:revealFogOfWar( 26,  2, 1, true );
	
	ScriptManager:showMarkerAt( 25, 14 );
	ScriptManager:showMarkerAt( 26,  2 );
	
	ScriptManager:wait( 3 );
	
	ScriptManager:removeAllMarkers();
	
	ScriptManager:revealFogOfWar( 26,  2, 1, false );
	ScriptManager:revealFogOfWar( 25, 14, 1, false );
	
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_INTRO_FLAVOR4 );
	ScriptManager:moveCameraEx( 26, 8, 0.7, 3, true );
	Utils:antiRush();
	
	Utils:markUnit( 26, 8, 1, 3, false );
	Utils:antiRush();
	
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_INTRO_FLAVOR5 );
	ScriptManager:moveCameraEx( 16, 12, 0.7, 4, false );
	ScriptManager:wait( 4 );
	ScriptManager:moveCameraEx(  2,  3, 0.7, 4, false );
	ScriptManager:wait( 2 );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.capFactories,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.getAirfield,		MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.capFactories, 0, #factoryIds );
	Utils:setMissionProgress( missionIds.destroyTanks, 0, tanksToDestroy );
	
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
	Utils:removeSquad( mineIds );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end

function prepareSecondaryIntroCutscene()
	ScriptManager:removeTrigger( "prepareSecondaryIntroCutscene" );
	
	table.insert( queueTable, startSecondaryIntroCutscene );
	Utils:cutsceneQueue();
end

function startSecondaryIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_2_SECONDARY2_FLAVOR1 );
	ScriptManager:moveCameraEx( 14, 11, 0.7, 4, true );
	
	Utils:markUnit( 14, 11, 1, 2, false );
	
	ScriptManager:moveCameraEx( 4, 4, 0.7, 4, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.getDepot, MissionStatus.IN_PROGRESS );
end


-- END Intro Cutscene
-- BEGIN Unit / Wave Stuff


function onUnitCreated( createdUnit )
	local posX = createdUnit:getX();
	local posY = createdUnit:getY();
	
	if posX >= 18 and posX <= 22 and posY >= 6 and posY <= 10 then -- not 100 % the same as on enter area but i dont really care about it
		if ScriptManager:getValue( "forestAmbushTriggered" ) == 0 then
			triggerForestAmbushTile( posX, posY );
		end
	
	elseif posX == 25 and posY <= 18 then -- ambush
		if ScriptManager:getValue( "enemyReinforcements2Triggered" ) == 0 then
			spawnEnemyReinforcements2( 0, 0, 0, createdUnit:getTemplateId() );
		end
	end
end

function onTankHasAttacked()
	ScriptManager:removeTrigger( "onTankHasAttacked" );
	ScriptManager:runForPlayer( 0, "prepareTankMissionCutscene" );
end

function prepareTankMissionCutscene()
	table.insert( queueTable, showTankMissionCutscene );
	Utils:cutsceneQueue();
end

function showTankMissionCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_2_SECONDARY3_FLAVOR1, 3 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyTanks, MissionStatus.IN_PROGRESS );
end

function onTankDestroyed()
	Utils:incrementMissionProgress( missionIds.destroyTanks );
	ScriptManager:runForPlayer( 0, "prepareTankMissionProgress" );
end

function prepareTankMissionProgress()
	table.insert( queueTable, showTankMissionProgress );
	Utils:cutsceneQueue();
end

function showTankMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyTanks ) >= tanksToDestroy then
		ScriptManager:removeTrigger( "onTankDestroyed" );
		Utils:setMissionStatus( missionIds.destroyTanks, MissionStatus.ACCOMPLISHED );
		
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyTanks), Text.T_CAMP_L2_2_SECONDARY3_COUNTER );
	end
end

function triggerForestAmbushSeen( seeingUnit, seenUnit )
	local squadId = seeingUnit:getSquadId();
	
	if squadId == enemySquadIds.forestAmbush1 or squadId == enemySquadIds.forestAmbush2 then
		triggerForestAmbushTile( seenUnit:getX(), seenUnit:getY() );
	end
end

function triggerForestAmbushTile( tileX, tileY )
	ScriptManager:removeTrigger( "triggerForestAmbush" );
	ScriptManager:storeValue( "forestAmbushTriggered", 1 );
	
	local orderId;
	for i = enemySquadIds.forestAmbush1, enemySquadIds.forestAmbush2 do
		orderId = ScriptManager:addOrder( i, tileX, tileY, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
		
		orderId = ScriptManager:addOrder( i,  19,  9, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		ScriptManager:addOrder( i,  19,  9, -1, 2, AiOrder.DEFEND );
	end
end

function spawnEnemyReinforcements1()
	ScriptManager:removeTrigger( "spawnEnemyReinforcements1" );
	
	spawnEnemyReinforcements( enemyReinforcementUnits1, enemySquadIds.reinforcements1 );
end

function spawnEnemyReinforcements2( tileX, tileY, playerId, unitTemplateId, unitId )
	if unitTemplateId ~= Units.L_PLANE_SCOUT then
		ScriptManager:removeTrigger( "spawnEnemyReinforcements2" );
		ScriptManager:storeValue( "enemyReinforcements2Triggered", 1 );
		
		ScriptManager:runForPlayer( 1, "spawnThem" );
	end
end

function spawnThem()
	spawnEnemyReinforcements( enemyReinforcementUnits2, enemySquadIds.reinforcements2 );
	spawnEnemyReinforcements( enemyReinforcementUnits3, enemySquadIds.reinforcements3 );
end

function spawnEnemyReinforcements( reinforcementTable, squadId )
	for i = 1, #reinforcementTable do
		Utils:spawnUnitFromShortTable( 1, squadId, reinforcementTable[i] );
	end
end

function waveSquadDestroyed()
	-- old wave squad was destroyed, prepare spawn for next
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval;
	ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewWave", "spawnNewWave" );
end

function spawnNewWave()
	ScriptManager:removeTrigger( "spawnNewWave" );
	
	if ScriptManager:getMissionStatus( missionIds.getAirfield ) ~= MissionStatus.ACCOMPLISHED then
		for i = 1, #planeAttackWaveUnits do
			Utils:spawnUnitFromShortTable( 1, enemySquadIds.planeAttackWave, planeAttackWaveUnits[i] );
		end
	end
end

function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.planeAttackWave then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, airplaneTable );
	
	elseif squadId == enemySquadIds.reinforcements1 then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, reinforcement1Table );
		
	elseif squadId == enemySquadIds.reinforcements2 then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, reinforcement2Table );
	
	elseif squadId == enemySquadIds.reinforcements3 then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, reinforcement3Table );
	end
end

function factorySupport( squadId, unitId, defPosX, defPosY, radius )
	if squadId == enemySquadIds.factory1 then
		newOrder( enemySquadIds.reinforcements1, defPosX, defPosY, radius );
	
	elseif squadId == enemySquadIds.factory2 then
		newOrder( enemySquadIds.reinforcements2, defPosX, defPosY, radius );
	
	elseif squadId == enemySquadIds.factory3 then
		newOrder( enemySquadIds.reinforcements3, defPosX, defPosY, radius );
	end
end

function newOrder( squadId, posX, posY, radius )
	ScriptManager:removeAllOrders( squadId );
	ScriptManager:addOrder( squadId, posX, posY, -1, radius, AiOrder.DEFEND );
	
	ScriptManager:removeAllOrders( enemySquadIds.planeAttackWave );
	ScriptManager:addOrder( enemySquadIds.planeAttackWave, posX, posY, -1, radius, AiOrder.DEFEND );
end


-- END Unit / Wave Stuff
-- BEGIN Building Stuff


function onFactoryCaptured()
	Utils:incrementMissionProgress( missionIds.capFactories );
	
	if ScriptManager:getMissionProgress( missionIds.capFactories ) >= #factoryIds then
		ScriptManager:removeTrigger( "onFactoryCaptured" );
		Utils:setMissionStatus( missionIds.capFactories, MissionStatus.ACCOMPLISHED );
		startVictoryCutscene();
		
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.capFactories ), Text.T_CAMP_L2_2_PRIMARY_COUNTER );
	end
end

function onAirfieldGotten()
	ScriptManager:removeTrigger( "onAirfieldGotten" );
	ScriptManager:removeTrigger( "waveSquadDestroyed" );
	ScriptManager:removeTrigger( "spawnNewWave" );
	
	Utils:setMissionStatus( missionIds.getAirfield, MissionStatus.ACCOMPLISHED );
end

function onOutpostCaptured()
	outpostMissionConclusion( MissionStatus.ACCOMPLISHED );
end

function onOutpostDestroyed()
	outpostMissionConclusion( MissionStatus.FAILED );
end

function outpostMissionConclusion( missionStatus )
	ScriptManager:removeTrigger( "onOutpostGotten" );
	Utils:setMissionStatus( missionIds.getDepot, missionStatus );
end


-- END Building Stuff
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_2_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_2_VICTORY_FLAVOR2, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_2_VICTORY_FLAVOR3, 6 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_2_VICTORY_FLAVOR4, 3 );
	
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


-- END Defeated