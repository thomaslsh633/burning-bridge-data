require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	captureDestroyBuildings	= 1,
	reachEastBorder			= 2,
	captureBridge			= 3,
	defGustav				= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.captureDestroyBuildings,	true,	Text.T_CAMP_L3_3_PRIMARY1,	125 },
	{ missionIds.reachEastBorder,			true,	Text.T_CAMP_L3_3_PRIMARY2,	100 },
	{ missionIds.defGustav,					true,	Text.T_CAMP_L3_3_PRIMARY3,	 75 },
	{ missionIds.captureBridge,				false,	Text.T_CAMP_L3_3_SECONDARY1, 50 },
};

enemySquadIds = {
	firstAmbush					=  1,
	engineer					=  2,
	firstPlaneAttack			=  3,-- dont change order of first - fourth plane attack
	secondPlaneAttack			=  4,
	thirdPlaneAttack			=  5,
	fourthPlaneAttack			=  6,
	airAttacker					=  7,
	northernOutpostDefenders	=  8,
	southernAirfieldDefenders	=  9,
	northernFactoryDefenders	= 10,
	northernMortar				= 11,
	cityDefenders				= 12,
	southernMGSquad				= 13,
	southernFactoryDefenders	= 14,
	southernOutpostDefenders	= 15,
	southernSniperSquad			= 16,
	northernAirfieldDefenders	= 17,
	northernArtillerySquad		= 18,
	finalBlock					= 19,
	forestAmbush				= 20,
	MGNest						= 21,
	brideArtillery				= 22,
	repairAttackers				= 23,
};

camoflagedUnits	= { 14, 31, 19, 22, 16, 17, 18, 20, 21, 23, 24, 25, 26, 29, 30, 31, 32, 33, 37, 39, 51, 40, 41, 44, 45, 48, 49, 50, 52, 58, 59 }
fortifiedUnits	= {  8,  9, 10, 11, 12, 13, 38 };

firstPlaneId		= 42
thirdPlaneId		= 46
fourthPlaneId		= 47
airfieldId			=  6
northernOutpostId	=  2
southernAirfieldId	=  3
northernFactoryId	=  5
southernFactoryId	=  4
southernOutpostId	=  7
northernAirfieldId	=  6
enemyTransporterId	= 53
railBridgeId		=  0;
brideArtilleryId	= 41;

-- if any global ability comes close to the rail bridge it also triggers the destroy cutscene
southernBridgeArea = { 10, 16, 1, 6 };

planeWaveRespawnInterval = 3;
airfieldTile			 = { { 27, 18 }, { 27, 19 }, };
waypointTablePlane 		 = { { 26,  4 }, { 18,  3 }, { 16, 18 }, {  8, 11 }, { 10, 3 }, { 22, 1 }, { 25,  8 }, };

-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	
	setTriggers();
	storeValues();
	addAiOrders();
	prepareUnits()
	
	ScriptManager:setInstantDestroyed( railBridgeId, true );
	
	ScriptManager:disableComponent( brideArtilleryId, ComponentType.MOVEMENT, 0 );
	
	ScriptManager:gainGold( 0, 1500 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "blimp",			0 );
	ScriptManager:storeValue( "gustavAttacked",	0 );
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.X_ARTILLERY_GUSTAF, -1, "showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger( 	0, Units.X_ARTILLERY_GUSTAF, -1, "transitionToFail", 	"transitionToFail" );
	
	-- air attacks
	ScriptManager:addOnAiCalculationTrigger( true,	"checkWaypoints",		"checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger( -1,	"planeSquadDestroyed",	"planeSquadDestroyed" );
	for y = 1, 21 do
		ScriptManager:addOnEnterTileTrigger( 13, y, 0, -1, -1, false, "triggerPlaneWaves", "triggerPlaneWaves" );
	end
	
	-- capturing or destroying all six enemy buildings accomplishes missionIds.captureDestroyBuildings
	ScriptManager:addOnUnitCapturedTrigger(	 0,Units.X_BUILDING_HQ,			 -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1,Units.X_BUILDING_HQ,			 -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	ScriptManager:addOnUnitCapturedTrigger(	 0,Units.X_BUILDING_AIRFIELD,	 -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1,Units.X_BUILDING_AIRFIELD,	 -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	ScriptManager:addOnUnitCapturedTrigger(	 0,Units.N_BUILDING_TANKFACTORY, -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1,Units.N_BUILDING_TANKFACTORY, -1, "buildingCapturedDestroyed", "buildingCapturedDestroyed" );
	
	-- if Gustav reaches the east border of the map missionIds.reachEastBorder is accomplished
	ScriptManager:addOnEnterTileTrigger( 11, 11, -1, Units.X_ARTILLERY_GUSTAF, -1, true, "startBuildingsMissionCutscene",	"startBuildingsMissionCutscene",	-1 );
	ScriptManager:addOnEnterTileTrigger( 27, 11, -1, Units.X_ARTILLERY_GUSTAF, -1, true, "gustavReachedEastBorder",			"gustavReachedEastBorder",			-1 );
	
	--spawn blimp 
	ScriptManager:addOnTurnStartTrigger(	 1, -1,					 -1, "onEnmeyTurnStart", "onEnmeyTurnStart" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_PLANE_SCOUT, -1, "onBlimpDestroyed", "onBlimpDestroyed" );
	
	-- trigger for seeing the bridges
	ScriptManager:addOnUnitSightedTrigger( -1, Units.N_BRIDGE_RAIL, -1, true, "destroyedBridgeSighted", "destroyedBridgeSighted" );
	
	for y = 1, 5 do
		ScriptManager:addOnEnterTileTrigger(  9, y, 0, -1, -1, true, "nearSouthernBridge", "nearSouthernBridge" );
		ScriptManager:addOnEnterTileTrigger( 16, y, 0, -1, -1, true, "nearSouthernBridge", "nearSouthernBridge" );
	end
	
	for x = 10, 16 do
		ScriptManager:addOnEnterTileTrigger( x, 6, 0, -1, -1, true, "nearSouthernBridge", "nearSouthernBridge" );
	end
	
	ScriptManager:addOnDropUnitTrigger( -1,						0, -1,	-1, -1, "gaNearSouthernBridge", "nearSouthernBridge" );
	ScriptManager:addOnSpawnUnitTrigger( GlobalAbility.BLIMB,	0,		-1, -1, "gaNearSouthernBridge", "nearSouthernBridge" );
	
	-- capturing the southern bridge accomplishes missionIds.captureBridge
	ScriptManager:addOnUnitCapturedTrigger( -1, Units.N_BRIDGE_M, -1, "southernBridgeCaptured", "southernBridgeCaptured" );
	ScriptManager:addOnBridgeRepairTrigger( -1, Units.N_BRIDGE_M, -1, "southernBridgeRepaired", "southernBridgeCaptured" ); -- alternate capture method: destroy -> repair
	
	-- repairing the northern bridge adds an attack order for planes
	ScriptManager:addOnBridgeRepairTrigger( -1, Units.N_BRIDGE_RAIL, -1, "railBridgeRepaired", "railBridgeRepaired" );

	
	-- enemySquadIds.forestAmbush remains silent until it has been attacked or Gustav is in range
	for i = 30, 33 do
		ScriptManager:addOnUnitHasAttackedTrigger(	0, -1, i, "forestAmbush", "forestAmbush" );
	end
	ScriptManager:addOnEnterTileTrigger( 19, 11, 0, -1, -1, false, "forestAmbush",			"forestAmbush", -1 );
	ScriptManager:addOnUnitSightedTrigger(		 0, -1, -1, false, "forestAmbushSighted",	"forestAmbush" );
end

function loadValues()
	local gustav = Unit:getUnitById( ScriptManager:getValue( "gustavId" ) );
end

function addAiOrders()
	buildingDefendSquadOrder( enemySquadIds.northernOutpostDefenders,	northernOutpostId );
	buildingDefendSquadOrder( enemySquadIds.southernAirfieldDefenders,	southernAirfieldId );
	buildingDefendSquadOrder( enemySquadIds.northernFactoryDefenders,	northernFactoryId );
	buildingDefendSquadOrder( enemySquadIds.southernFactoryDefenders,	southernFactoryId );
	buildingDefendSquadOrder( enemySquadIds.southernOutpostDefenders,	southernOutpostId );
	buildingDefendSquadOrder( enemySquadIds.northernAirfieldDefenders,	northernAirfieldId );
	
	ScriptManager:addOrder( enemySquadIds.firstPlaneAttack,			  4, 11, -1,								 2, AiOrder.ATTACK );
	ScriptManager:addOrder( enemySquadIds.firstPlaneAttack,			 -1, -1, ScriptManager:getValue("gustavId"), 1, AiOrder.ATTACK );
	ScriptManager:addOrder( enemySquadIds.firstAmbush,				 -1, -1, ScriptManager:getValue("gustavId"), 1, AiOrder.ATTACK );
	ScriptManager:addOrder( enemySquadIds.northernMortar,			 17, 17, -1,								 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.cityDefenders,			 16, 11, -1,								 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernMGSquad,			 17,  4, -1,								 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernSniperSquad,		 24,  5, -1,								 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.northernArtillerySquad,	 25, 18, -1,								 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.finalBlock,				 27, 11, -1,								 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.MGNest,					 11,  4, -1,								 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.brideArtillery,			 14, 11, -1,								 6, AiOrder.DEFEND );
end

function buildingDefendSquadOrder( squadId, buildingId )
	ScriptManager:addOrder( squadId,	 -1, -1, buildingId, 2, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( squadId, -1, -1, ScriptManager:getValue( "gustavId" ),  3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end

function prepareUnits()
	for i = 1, #camoflagedUnits do
		ScriptManager:camouflageUnit( camoflagedUnits[i] );
	end
	
	for i = 1, #fortifiedUnits do
		ScriptManager:fortifyUnit( fortifiedUnits[i], true );
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_INTRO_FLAVOR1, 5 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx( 3, 11, 1, 4, false );
	
	local transporter = ScriptManager:spawnUnitWithTransporter( 0, Units.L_TRUCK_TRANSPORT, Units.L_INFANTRY_AT, 1, 12, 0 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MG, 1, 12, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MG, 1, 12, -1 );
	local transporterId = transporter:getId();
	ScriptManager:moveUnitEx( transporterId, 2, 12, true );
	
	local unit = ScriptManager:spawnUnitWithTransporter( 0, Units.L_TRUCK_TRANSPORT, Units.L_INFANTRY_AT, 1, 10, 0 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MG, 1, 10, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MG, 1, 10, -1 );
	
	local unitId = unit:getId();
	ScriptManager:moveUnitEx( unitId, 3, 10, true );
	ScriptManager:moveUnitEx( transporterId, 3, 12, true );
	
	unit = ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 0, 12, 0 );
	ScriptManager:moveUnitEx( unit:getId(), 1, 12, true );
	
	local gustav = ScriptManager:spawnUnit( 0, Units.X_ARTILLERY_GUSTAF, 0, 11, -1 );
	local gustavId = gustav:getId();
	ScriptManager:rotateUnit( gustavId, FaceDirection.EAST );
	ScriptManager:storeValue( "gustavId", gustavId );
	gustav:setAllowCounterAttack( false );
	
	ScriptManager:moveUnitEx( gustavId, 2, 11, true );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_INTRO_FLAVOR3, 4 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_INTRO_FLAVOR4 );
	ScriptManager:moveCameraEx( 5, 11, 1, 1.5, true );
	
	ScriptManager:moveUnitEx( enemyTransporterId, 6, 11, true );
	local AT2	= ScriptManager:spawnUnit( 1, Units.X_INFANTRY_AT, 6, 12, enemySquadIds.firstAmbush );
	local AT2Id	= AT2:getId();
	ScriptManager:fortifyUnit( AT2Id, true );
	
	local enemyTransporter = Unit:getUnitById( enemyTransporterId );
	local AT1 = enemyTransporter:getLoadedUnitAt( 0 );
	local AT1Id = AT1:getId();
	
	ScriptManager:unloadUnitFromTransporterEx( enemyTransporterId, AT1Id, 6, 10, true );
	ScriptManager:fortifyUnit(AT1Id, true );
	ScriptManager:transformUnit( enemyTransporterId, 6, 11, 1, false );
	ScriptManager:addOrder( enemySquadIds.firstAmbush, 6, 11, -1, 1, AiOrder.DEFEND );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_INTRO_FLAVOR5 );
	Utils:antiRush();
	ScriptManager:moveCameraEx( 4, 11, 0.7, 4, true );
	Utils:antiRush();
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();

	setGustavTriggers();
	gustav:setAttacksPerTurn( 0 );
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.captureDestroyBuildings, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.defGustav,				MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.captureDestroyBuildings,	0,  6 );
	Utils:setMissionProgress( missionIds.reachEastBorder,			0, -1 );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
	
	local gustav = ScriptManager:spawnUnit( 0, Units.X_ARTILLERY_GUSTAF, 20, 11, -1 );
	local gustavId = gustav:getId();
	ScriptManager:rotateUnit( gustavId, FaceDirection.EAST );
	ScriptManager:storeValue( "gustavId", gustavId );
	ScriptManager:setMissionStatus( missionIds.reachEastBorder, MissionStatus.IN_PROGRESS );
end

function removeSquads()
	Utils:removeSquad( camoflagedUnits );
	Utils:removeSquad( fortifiedUnits );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end

function setGustavTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false );
	
	-- Gustav attacked
	ScriptManager:addOnUnitHasAttackedTrigger( 0, Units.X_ARTILLERY_GUSTAF, -1, "gustafAttacked", "gustafAttacked" );
	
	-- Check if Gustav is ready to fire
	ScriptManager:addOnTurnStartTrigger( 0, -1, -1, "reloadGustav", "reloadGustav" );
end


-- END Intro Cutscene
-- BEGIN


function gustafAttacked()
	ScriptManager:storeValue( "gustavAttacked", 1 );
end

function reloadGustav()
	local gustavId = ScriptManager:getValue( "gustavId" );
	local gustav = Unit:getUnitById( gustavId );
	
	if ScriptManager:getValue( "gustavAttacked" ) == 1 then 
		gustav:setAttacksPerTurn( 0 );
		ScriptManager:storeValue( "gustavAttacked", 0 );
	
	else
		gustav:setAttacksPerTurn( 1 );
	end
end

function buildingCapturedDestroyed()
	Utils:incrementMissionProgress( missionIds.captureDestroyBuildings )
	
	ScriptManager:runForPlayer( 0, "prepareBuildingMissionProgress" );
end

function prepareBuildingMissionProgress()
	table.insert( queueTable, showBuildingMissionProgress );
	Utils:cutsceneQueue();
end

function showBuildingMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.captureDestroyBuildings ) >= ScriptManager:getMaxMissionProgress( missionIds.captureDestroyBuildings ) then
		ScriptManager:removeTrigger( "buildingCapturedDestroyed" );
		
		Utils:setMissionStatus( missionIds.captureDestroyBuildings, MissionStatus.ACCOMPLISHED )
		
		if ScriptManager:getMissionStatus( missionIds.reachEastBorder ) == MissionStatus.ACCOMPLISHED then
			startVictoryCutscene();
		
		else
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_PRIMARY1_FLAVOR1, 4 );
			startBuildingsMissionCutscene();
		end
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.captureDestroyBuildings ), Text.T_CAMP_L3_3_PRIMARY1_COUNTER );
	end
end

function startBuildingsMissionCutscene()
	if ScriptManager:getMissionStatus( missionIds.reachEastBorder ) == MissionStatus.NOT_STARTED then
		ScriptManager:removeTrigger( "startBuildingsMissionCutscene" );
		Utils:startCutscene();
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_PRIMARY1_FLAVOR2 );
		ScriptManager:moveCameraEx(		27, 11, 1, 6,	true );
		Utils:markUnit( 27, 11, 1, 2, 0 );
		
		local gustav = Unit:getUnitById( ScriptManager:getValue( "gustavId" ) );
		ScriptManager:moveCameraEx( gustav:getX(), gustav:getY(), 0.7, 3, true );
		Utils:hideDialogue();
		
		Utils:endCutscene();
		Utils:setMissionStatus( missionIds.reachEastBorder, MissionStatus.IN_PROGRESS );
	end
end

function gustavReachedEastBorder()
	ScriptManager:removeTrigger( "gustavReachedEastBorder" );
	Utils:setMissionStatus( missionIds.reachEastBorder, MissionStatus.ACCOMPLISHED );
	
	if ScriptManager:getMissionStatus( missionIds.captureDestroyBuildings ) == MissionStatus.ACCOMPLISHED then
		startVictoryCutscene();
	end
end

function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.airAttacker then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTablePlane );
	end
end

function planeSquadDestroyed( squadId )
	-- plane squads are ids 3-6, no changerino
	if squadId >= enemySquadIds.firstPlaneAttack and squadId <= enemySquadIds.thirdPlaneAttack then
		-- if first is destroyed, let second attack, if second is destroyed, let third attack, etc... 
		local orderId = ScriptManager:addOrder( squadId + 1, -1, -1, ScriptManager:getValue( "gustavId" ), 1, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		-- two more waypoints just to be safe they dont get lost
		orderId = ScriptManager:addOrder( squadId + 1, 2, 11, -1, 1, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		orderId = ScriptManager:addOrder( squadId + 1, 27, 11, -1, 1, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	elseif squadId == enemySquadIds.airAttacker then
		local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval;
		ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewWave", "spawnNewWave" );
	end
end

function triggerPlaneWaves( tileX, tileY, playerId, unitTemplateId, unitId )
	-- start the plane waves after gustav or two others crossed the trigger line
	if unitTemplateId == Units.X_ARTILLERY_GUSTAF then
		planesTriggered()
	
	else
		Utils:incrementMissionProgress( missionIds.reachEastBorder );
		
		if ScriptManager:getMissionProgress( missionIds.reachEastBorder ) >= 2 then
			planesTriggered()
		end
	end
end

function planesTriggered()
	ScriptManager:removeTrigger( "triggerPlaneWaves" );
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval;
	ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewWave", "spawnNewWave" );
end

function spawnNewWave()
	ScriptManager:removeTrigger( "spawnNewWave" );
	local airfield = Unit:getUnitById( airfieldId );
	
	if airfield ~= nil then
		if airfield:getPlayerId() == 1 then
			-- depending on the current turn spawn either light fighter or bomber
			local spawnIndicator = ( ScriptManager:getCurrentRound() % 2 ) + 1; -- either 1 or 2
			local templateId = Units.X_PLANE_LIGHT;
			
			if spawnIndicator == 1 then
				templateId = Units.X_PLANE_BOMBER;
			end
			
			ScriptManager:spawnUnit( 1, templateId, airfieldTile[spawnIndicator][1], airfieldTile[spawnIndicator][2], enemySquadIds.airAttacker );
			ScriptManager:addOrder( enemySquadIds.airAttacker, -1, -1, ScriptManager:getValue( "gustavId" ), 1, AiOrder.ATTACK );
		end
	end
end

function onEnmeyTurnStart()
	local northernBridge = Unit:getUnitById( railBridgeId );
	local blimpIndicator = ScriptManager:getValue( "blimp" );
	
	-- spawn a blimp to give the enemy vision on bridge repairs. if it gets destroyed, respawn it a few turns later. stop spawning when reparis are done
	if blimpIndicator == 0 and northernBridge:getPlayerId() ~= 1 then
		ScriptManager:runAbility( 1, Units.X_PLANE_SCOUT, -1, GlobalAbility.BLIMB, 10, 13,  -1 );
		--ScriptManager:spawnUnit( 1, Units.X_PLANE_SCOUT, 10, 13, -1 );
		ScriptManager:storeValue( "blimp", -1 );
	
	elseif blimpIndicator > 0 then
		ScriptManager:storeValue( "blimp", blimpIndicator - 1 );
	end
end

function onBlimpDestroyed()
	ScriptManager:storeValue( "blimp", 2 );
end

function destroyedBridgeSighted( seeingUnit, seenUnit )
	if seeingUnit:getPlayerId() == 0 then
		ScriptManager:removeTrigger( "destroyedBridgeSighted" );
		ScriptManager:removeTrigger( "engineerDestroyed" );
		ScriptManager:removeTrigger( "nearSouthernBridge" );
		
		ScriptManager:storeValue( "tileX", seeingUnit:getX() );
		ScriptManager:storeValue( "tileY", seeingUnit:getY() );
		
		ScriptManager:runForPlayer( 0, "prepareRailBridgeCutscene" );
	end
end

function prepareRailBridgeCutscene()
	table.insert( queueTable, startRailBridgeCutscene );
	Utils:cutsceneQueue();
end

function startRailBridgeCutscene()
	Utils:startCutscene()
	
	ScriptManager:moveCameraEx(		11, 11, 1, 2, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_PRIMARY2_FLAVOR1 );
	ScriptManager:revealFogOfWar( 11, 11, 1, true );
	ScriptManager:wait( 4 );
	ScriptManager:revealFogOfWar( 11, 11, 1, false );
	Utils:hideDialogue();
	
	if ScriptManager:getMissionStatus( missionIds.captureBridge ) == MissionStatus.NOT_STARTED then
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_PRIMARY2_FLAVOR2 );
		
		ScriptManager:moveCameraEx(	12, 3, 1, 3 , true);
		Utils:markUnit( 12, 3, 1, 3, 1 );
		
		ScriptManager:moveCameraEx( ScriptManager:getValue( "tileX" ), ScriptManager:getValue( "tileY" ), 0.7, 2, true );
		Utils:hideDialogue();
	end
	
	Utils:endCutscene();
	if ScriptManager:getMissionStatus(missionIds.captureBridge) == MissionStatus.NOT_STARTED then
		Utils:setMissionStatus( missionIds.captureBridge, MissionStatus.IN_PROGRESS );
	end
end

function gaNearSouthernBridge( targetTileX, targetTileY, spawnedTileX, spawnedTileY, spawnedUnit )
	-- only trigger the mission when it is inside the target area
	if	spawnedTileX >= southernBridgeArea[1] and spawnedTileX <= southernBridgeArea[2] and
		spawnedTileY >= southernBridgeArea[3] and spawnedTileY <= southernBridgeArea[4] then
		
		nearSouthernBridge( spawnedTileX, spawnedTileY );
	end
end

function nearSouthernBridge( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	ScriptManager:removeTrigger( "nearSouthernBridge" );
	ScriptManager:storeValue( "tileX",tileX )
	ScriptManager:storeValue( "tileY",tileY )
	
	table.insert( queueTable, nearSouthernBridgeCutscene );
	Utils:cutsceneQueue();
end

function nearSouthernBridgeCutscene()
	Utils:startCutscene();

	ScriptManager:displaySubtitle( Text.T_CAMP_L3_3_SECONDARY1_FLAVOR1 );
	ScriptManager:moveCameraEx(		12, 3, 1, 1, true );
	ScriptManager:revealFogOfWar(	12, 3, 1, true );
	ScriptManager:showMarkerAt(		12, 3, true, true );
	ScriptManager:wait( 5 );
	Utils:hideAllMarkers();
	ScriptManager:revealFogOfWar( 12, 3, 1, false );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "tileX" ),ScriptManager:getValue( "tileY" ), 0.7, 1, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus(missionIds.captureBridge,MissionStatus.IN_PROGRESS);
end

function southernBridgeCaptured()
	ScriptManager:removeTrigger( "southernBridgeCaptured" );
	Utils:setMissionStatus( missionIds.captureBridge, MissionStatus.ACCOMPLISHED );
end

function southernBridgeRepaired( repairer, bridge )
	local bridgeHealth = bridge:getHealth();
	if bridgeHealth >= 1200 then
		southernBridgeCaptured();
	end
end

function railBridgeRepaired( repairer, bridge )
	local bridgeHealth = bridge:getHealth();
	if bridgeHealth >= 1200 then
		ScriptManager:removeTrigger( "railBridgeRepaired" );
		ScriptManager:removeTrigger( "onEnmeyTurnStart" );
		ScriptManager:removeTrigger( "onBlimpDestroyed" );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_PRIMARY2_FLAVOR3,  3 );
	elseif bridgeHealth <= 300 then
		ScriptManager:addOrder( enemySquadIds.repairAttackers, -1, -1, repairer:getId(), 2, AiOrder.ATTACK );
		
		local orderId = ScriptManager:addOrder( enemySquadIds.repairAttackers, -1, -1, ScriptManager:getValue( "gustavId" ),  3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	end
end

function forestAmbushSighted( activeUnit, passiveUnit )
	local squadId = activeUnit:getSquadId();
	
	if squadId == enemySquadIds.forestAmbush then
		forestAmbush();
	end
end

function forestAmbush()
	ScriptManager:removeTrigger( "forestAmbush" );
	local orderId = ScriptManager:addOrder( enemySquadIds.forestAmbush, -1, -1, ScriptManager:getValue( "gustavId" ), 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:setMissionStatus( missionIds.defGustav, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle(	Text.T_CAMP_L3_3_VICTORY_FLAVOR1 );
	--[[local gustavId = ScriptManager:getValue( "gustavId" )
	print( gustavId );
	print( Unit:getUnitById( gustavId ):getTemplateId() );
	ScriptManager:moveUnitEx(	gustavId, 29, 11, true );
	ScriptManager:removeUnitEx(	gustavId, true );
	Utils:antiRush();]]
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_VICTORY_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_3_VICTORY_FLAVOR3, 3 );
	
	Utils:endCutscene();
	
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
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_ARTILLERY_GUSTAF );
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