require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	captureBase			= 1,
	captureAirfield		= 2,
	deploySupplyCrate	= 3,
	destroyAC			= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.captureBase,		true,	Text.T_CAMP_X1_2_PRIMARY1, 		100 },
	{ missionIds.captureAirfield,	true,	Text.T_CAMP_X1_2_PRIMARY2, 		100 },
	{ missionIds.deploySupplyCrate,	false,	Text.T_CAMP_X1_2_SECONDARY1,	 50 },
	{ missionIds.destroyAC,			false,	Text.T_CAMP_X1_2_SECONDARY2,	100 },
};

enemySquadIds = {
	planeReinforcements		=  1,
	westernVillageGuards	=  2,
	easternVillageGuards	=  3,
	attackSquad1			=  4,
	easternReinforcements	=  5,
	westernReinforcements	=  6,
	plane					=  7,
	bs						=  8,
	ac						=  9,
	westernPlane			= 10,
};

playerBaseId		=  7;
outerBridgeId		=  2;
innerBridgeId		= 12;
supplyBaseId		=  8;
airfieldId			=  9;
northernBridgeId	= 10;
southernBridgeId	= 11;
ACId				=  3;
bsId				= 26;
leftBunkerId		= 19;
rightBunkerId		= 15;

freeSquadIdStart	= 11;


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1250 );
	
	local bunker = Unit:getUnitById( 4 );
	bunker:setAmmo( 2 );
	
	bunker = Unit:getUnitById( 16 );
	bunker:setAmmo( 1 );
	
	bunker = Unit:getUnitById( 20 );
	bunker:setAmmo( 2 );
	
	Utils:setIsAttackable( supplyBaseId, false );
	Utils:setIsAttackable( airfieldId,	 false );
	Utils:setIsAttackable( ACId,		 false );
	Utils:setIsAttackable( bsId,		 false );
	
	ScriptManager:spawnUnitWithTransporter( 0, Units.X_TRUCK_TRANSPORT, Units.X_INFANTRY_AT, 16, 26, -1 );
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 16, 26, -1 );
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 16, 26, -1 );
	
	ScriptManager:spawnUnitWithTransporter( 0, Units.X_TRUCK_TRANSPORT, Units.X_INFANTRY_AT, 15, 26, -1 );
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_FLAME,	 15, 26, -1 );
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_SNIPER, 15, 26, -1 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
	
	setTriggers();
end

function storeValues()
	ScriptManager:storeValue( "freeSquadId",				freeSquadIdStart );
	ScriptManager:storeValue( "bridgeDestroyTrigger",		0 );
	ScriptManager:storeValue( "southBridgeCrossedTrigger",	0 );
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_BUILDING_HQ ,			-1, "showAttackedWarning1", "showAttackedWarning1" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_BUILDING_AIRFIELD ,	-1, "showAttackedWarning2", "showAttackedWarning2" );
	
	ScriptManager:addOnUnitHasAttackedTrigger( 0, Units.X_BUILDING_HQ , 		-1, "stopAttackingHint1", "stopAttackingHint1" );
	ScriptManager:addOnUnitHasAttackedTrigger( 0, Units.X_BUILDING_AIRFIELD ,	-1, "stopAttackingHint2", "stopAttackingHint2" );
	
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_BUILDING_HQ,		-1, "transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_BUILDING_AIRFIELD,	-1, "transitionToFail", "transitionToFail" );
	
	--airfield captured accomplishes missionIds.captureAirfield
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_AIRFIELD, -1, "airfieldCaptured", "airfieldCaptured" );
	
	--aircraft carreir destroyed accomplishes missionIds.destroyAC
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_SHIP_AC, -1, "ACDestroyed", "ACDestroyed" );
	
	--enemy engineer will blow up the northern bridge if the supply base hasn't been captured yet. 
	--This way the player has an opportunity to use the transport plane in a meaningful way.
	ScriptManager:addOnEnterTileTrigger( 28, 26, 0, -1, -1, true, "destroyBridge", "destroyBridge" );
	
	--supply base captured accomplishes missionIds.captureBase and spawns warplanes at airfield, if not captured yet.
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_HQ, supplyBaseId, "supplyBaseCaptured", "supplyBaseCaptured" );
	
	--crossing the southern bridge activates missionIds.deplaoySupplyCrate, if it's not already active.
	ScriptManager:addOnEnterTileTrigger( 29, 14, 0, -1, -1, true, "southernBridgeCrossed", "southernBridgeCrossed" );
	
	-- trigger for paratrooper and on enter tile triggers
	ScriptManager:addOnUnitCreatedTrigger( 0, -1, "onUnitCreated", "onUnitCreated" );
	
	--spawn random waves each round
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	
	--trigger for planes
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, "spawnAcPlane",		"spawnAcPlane" );
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, "spawnWesternPlane", "spawnWesternPlane" );
	
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.plane,			"acPlaneDestroyed", 	 "acPlaneDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.westernPlane,	"westernPlaneDestroyed", "westernPlaneDestroyed" );
end

function addAiOrders()
	ScriptManager:addOrder( enemySquadIds.easternVillageGuards, 27, 26, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.westernVillageGuards, 35, 27, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bs,					 7,  3, -1, 9, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.ac,					35,  4, -1, 3, AiOrder.DEFEND );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
--Beach
	Utils:startCutscene();
	
	ScriptManager:revealFogOfWar( 34 ,21, 5, true );
	ScriptManager:revealFogOfWar( 35,  4, 5, true );
	ScriptManager:revealFogOfWar( 25, 25, 3, true );
	ScriptManager:revealFogOfWar( 31, 26, 2, true );
	
	local mortar = Unit:getUnitById( 53 );
	mortar:setHealth( 100 );
	local transporter = Unit:getUnitById( 55 );
	transporter:setHealth( 150 );
	local truck = Unit:getUnitById( 27 );
	truck:setHealth( 300 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx( 34, 8, 0.7, 5, false );
	
	local transporter1		 = ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 34, 5, -1 );
	local transporter1Id	 = transporter1:getId();
	local transportedUnit1	 = transporter1:getLoadedUnitAt( 0 );
	transportedUnit1:setHealth( 50 );
	local transportedUnit1Id = transportedUnit1:getId();
	ScriptManager:moveUnitEx( transporter1Id, 33, 8, true );
	
	local transporter2		= ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 36, 5, -1 );
	local transporter2Id	= transporter2:getId();
	local transportedUnit2	= transporter2:getLoadedUnitAt( 0 );
	transportedUnit2:setHealth( 50 );
	local transportedUnit2Id = transportedUnit2:getId();
	ScriptManager:moveUnitEx( transporter2Id, 37, 10, true );
	
	ScriptManager:unloadUnitFromTransporterEx( transporter1Id, transportedUnit1Id, 33,  9, true );
	ScriptManager:unloadUnitFromTransporterEx( transporter2Id, transportedUnit2Id, 36, 11, true );
	
	ScriptManager:moveCameraEx( 33, 10, 1, 2, true );
	ScriptManager:attackUnitEx( leftBunkerId, transportedUnit1Id, true );
	
	ScriptManager:moveCameraEx( 36, 12, 1, 1, true );
	ScriptManager:attackUnitEx( rightBunkerId, transportedUnit2Id, true );
	
	ScriptManager:moveCameraEx(34,14,1,1,false );
	
	local plane = ScriptManager:spawnUnit( 1, Units.L_PLANE_BOMBER, 31, 7, -1 );
	local planeId = plane:getId();
	ScriptManager:moveUnitEx( planeId, 35, 14, true );
	
	ScriptManager:attackUnitEx( planeId, 53, true );
	ScriptManager:attackUnitEx( 50, planeId, true );
	ScriptManager:moveCameraEx(		35, 25, 0.7, 9, false );
	ScriptManager:revealFogOfWar(	36, 28,		 3, true );
	
	ScriptManager:moveUnitEx(	planeId, 33, 10, true );
	ScriptManager:removeUnitEx( planeId, true );
	Utils:antiRush();
	
	local plane1 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 29, 12, -1 );
	local plane1Id = plane1:getId();
	local plane2 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 29, 11, -1 );
	local plane2Id = plane2:getId();
	local plane3 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 28, 13, -1 );
	local plane3Id = plane3:getId();
	
	ScriptManager:moveUnitEx( plane1Id, 38, 30, false );
	ScriptManager:wait( 0.5 );
	ScriptManager:moveUnitEx( plane2Id, 39, 30, false );
	ScriptManager:wait( 0.5 );
	ScriptManager:moveUnitEx( plane3Id, 37, 30, true );
	
	ScriptManager:removeUnitEx( plane1Id, true );
	ScriptManager:removeUnitEx( plane2Id, true );
	ScriptManager:removeUnitEx( plane3Id, true );
	
--Eastern Village
	ScriptManager:wait(1)
	local unit1 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MORTAR, 36, 29, enemySquadIds.easternVillageGuards );
	local unit1Id = unit1:getId();
	local unit2 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 35, 29, enemySquadIds.easternVillageGuards );
	local unit2Id = unit2:getId();
	ScriptManager:moveUnitEx( unit1Id, 36, 28, true );
	ScriptManager:moveUnitEx( unit2Id, 34, 25, true );
	
	local unit3 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_SNIPER, 35, 29, enemySquadIds.easternVillageGuards );
	local unit3Id = unit3:getId();
	ScriptManager:moveUnitEx(	unit3Id, 35, 28, true );
	ScriptManager:attackUnitEx( unit3Id, 54,	 true );
	ScriptManager:attackUnitEx( unit2Id, 54,	 true );
	
	local unit4 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT, 37, 29, enemySquadIds.easternVillageGuards );
	local unit4Id = unit4:getId();
	ScriptManager:moveUnitEx(	unit4Id, 37, 28, true );
	ScriptManager:attackUnitEx( unit4Id, 55,	 true );
	ScriptManager:moveUnitEx(	unit3Id, 35, 25, true );
	ScriptManager:moveUnitEx(	unit4Id, 35, 26, true );
	
	local unit5 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME, 37, 29, enemySquadIds.easternVillageGuards );
	local unit5Id = unit5:getId();
	ScriptManager:moveUnitEx( unit5Id, 36, 27, true );
	ScriptManager:captureUnitEx( unit5Id, supplyBaseId, true );
	
	ScriptManager:spawnUnit( 1, Units.L_ARTILLERY_AA, 37, 27, enemySquadIds.easternVillageGuards );
	ScriptManager:addOrder( enemySquadIds.easternVillageGuards, 35, 27, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:moveCameraEx( 25, 25, 0.7, 9, false );
	
	ScriptManager:revealFogOfWar( 34, 21, 5, false );
	ScriptManager:revealFogOfWar( 35,  4, 5, false );
	Utils:antiRush();
	ScriptManager:revealFogOfWar( 36, 28, 3, false );
	
	--Bridge
	local engineer = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 33, 28, -1 );
	local engineerId = engineer:getId();
	
	local plane1 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 32, 23, -1 );
	local plane1Id = plane1:getId();
	ScriptManager:moveUnitEx( plane1Id, 29, 29, true );
	
	local plane2 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 33, 24, -1 );
	local plane2Id = plane2:getId();
	ScriptManager:moveUnitEx( plane2Id, 30, 29, true );
	
	local plane3 = ScriptManager:spawnUnit( 1, Units.L_PLANE_TRANSPORT, 31, 23, -1 );
	local plane3Id = plane3:getId();
	ScriptManager:moveUnitEx( plane3Id,		29, 28, true );
	ScriptManager:moveUnitEx( engineerId,	32, 26, true );
	Utils:antiRush();
	
	ScriptManager:captureUnitEx( engineerId, northernBridgeId, true );
	ScriptManager:revealFogOfWar( 31, 26, 2, false );
	
	ScriptManager:removeUnitEx( engineerId,	true );
	ScriptManager:removeUnitEx( plane1Id,	true );
	ScriptManager:removeUnitEx( plane2Id,	true );
	ScriptManager:removeUnitEx( plane3Id,	true );
	
	--Airfield
	local flame1 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME, 24, 29,	enemySquadIds.attackSquad1 );
	local flame1Id = flame1:getId();
	local MG1 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 25, 29, enemySquadIds.westernVillageGuards );
	local MG1Id = MG1:getId();
	
	ScriptManager:moveUnitEx(	flame1Id,	23, 27,	true );
	ScriptManager:attackUnitEx( flame1Id,	21,		true );
	ScriptManager:moveUnitEx(	MG1Id,		24, 27,	true );
	ScriptManager:loadUnitIntoTransporterEx( 21, MG1Id, true );
	
	local AT1 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT, 25, 29, enemySquadIds.westernVillageGuards );
	local AT1Id = AT1:getId();
	ScriptManager:moveUnitEx( AT1Id, 24, 27, true );
	
	local MG2 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 25, 29, enemySquadIds.westernVillageGuards );
	local MG2Id = MG2:getId();
	ScriptManager:attackUnitEx(		21, 25, true );
	ScriptManager:moveUnitEx(MG2Id, 27, 26, true );
	
	local mortar = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MORTAR, 25, 29, enemySquadIds.westernVillageGuards );
	local mortarId = mortar:getId();
	ScriptManager:moveUnitEx( mortarId, 26, 27, true );
	
	local MG3 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 25, 29, enemySquadIds.westernVillageGuards );
	local MG3Id = MG3:getId();
	ScriptManager:moveUnitEx( AT1Id, 26, 26, true );
	ScriptManager:moveUnitEx( MG3Id, 25, 27, true );
	
	local MG4 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 25, 29, enemySquadIds.attackSquad1 );
	local MG4Id = MG4:getId();
	ScriptManager:attackUnitEx( MG3Id, 27,		true );
	ScriptManager:moveUnitEx(	MG4Id, 25, 26,	true );
	
	local AT2 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT, 25, 29, enemySquadIds.attackSquad1 );
	local AT2Id = AT2:getId();
	ScriptManager:moveUnitEx(	MG3Id, 26, 24,	true );
	ScriptManager:attackUnitEx(	MG4Id, 25,		true );
	ScriptManager:moveUnitEx(	MG4Id, 25, 24,	true );
	ScriptManager:moveUnitEx(	AT2Id, 25, 26,	true );
	
	local flame2 = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME, 25, 29, enemySquadIds.westernVillageGuards );
	local flame2Id	= flame2:getId();
	ScriptManager:moveUnitEx(		flame2Id,	22, 26,	true );
	ScriptManager:attackUnitEx(		AT2Id,		27,		true );
	ScriptManager:captureUnitEx(	flame1Id,	 9,		true );
	
	ScriptManager:revealFogOfWar(	25, 25,		 3, false );
	ScriptManager:moveCameraEx(		15, 25, 0.7, 3, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_INTRO_FLAVOR2 );
	Utils:antiRush();
	
	ScriptManager:removeUnitEx( flame1Id, true );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME, 25, 26, enemySquadIds.attackSquad1 );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.attackSquad1, 17, 10, -1, 1, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:addOrder( enemySquadIds.attackSquad1, 17, 10, -1, 3, AiOrder.DEFEND );
	ScriptManager:removeUnitEx( 21, true );
	
	ScriptManager:spawnUnitWithTransporter( 1, Units.N_EMPLACEMENT_MG_NEST, Units.L_INFANTRY_MG, 24, 26, enemySquadIds.westernVillageGuards );
	ScriptManager:addOrder( enemySquadIds.westernVillageGuards, 27, 26, -1, 2, AiOrder.DEFEND );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X1_2_INTRO_FLAVOR3, 5 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.captureAirfield,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.captureBase,		MissionStatus.IN_PROGRESS );
	
	-- trigger here cause in cutscene the ai captures stuff which triggers it >.<
	ScriptManager:addOnUnitCapturedTrigger(	 1, Units.X_BUILDING_HQ, -1, "playerBaseGone", "playerBaseGone" );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 19, 25, 0 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN


function airfieldCaptured()
	Utils:setMissionStatus( missionIds.captureAirfield, MissionStatus.ACCOMPLISHED );
	checkForVictory();
	
	Utils:setIsAttackable( airfieldId, true );
	
	ScriptManager:gainGold( 0, 500 );
	ScriptManager:removeTrigger( "southernBridgeCrossed" );
	ScriptManager:storeValue( "southBridgeCrossedTrigger", 1 );
	
	ScriptManager:runForPlayer( 0, "prepareAirfieldCapturedCutscene" );
end

function prepareAirfieldCapturedCutscene()
	table.insert( queueTable, airfieldCapturedCutscene );
	Utils:cutsceneQueue();
end

function airfieldCapturedCutscene()
	Utils:startCutscene()
	
	ScriptManager:revealFogOfWar( 35, 4, 2, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY1_FLAVOR1 );
	local unit = Unit:getUnitAt( 23, 25 );
	if unit == nil then
		ScriptManager:spawnUnitWithTransporter( 0, Units.X_PLANE_TRANSPORT, Units.X_INFANTRY_MG, 23, 25, -1 );
	
	else
		ScriptManager:gainGold( 0, 650 );
	end
	
	unit = Unit:getUnitAt( 22, 25 );
	if unit == nil then
		ScriptManager:spawnUnit( 0, Units.X_PLANE_BOMBER, 22, 25, -1 );
	
	else
		ScriptManager:gainGold( 0, 1250 );
	end
	
	unit = Unit:getUnitAt( 21, 25 );
	if unit == nil then
		ScriptManager:spawnUnit( 0, Units.X_PLANE_BOMBER, 21, 25, -1 );
	
	else
		ScriptManager:gainGold( 0, 1250 );
	end
	
	ScriptManager:spawnUnit( 0, Units.X_ARTILLERY_MORTAR, 23, 26, -1 );
	Utils:antiRush();
	Utils:hideDialogue()
	
	ScriptManager:moveCameraEx( 35, 4, 0.7, 5, false );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY2_FLAVOR1 );
	ScriptManager:wait( 5 );
	
	ScriptManager:showMarkerAt( 35, 4 );
	ScriptManager:wait( 2 );
	ScriptManager:hideMarkerAt( 35, 4 );
	
	ScriptManager:moveCameraEx( 23, 25, 0.7, 5, false );
	
	if ScriptManager:getMissionStatus( missionIds.deploySupplyCrate ) == MissionStatus.NOT_STARTED then
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY2_FLAVOR2 );
	end
	ScriptManager:wait( 5 );
	ScriptManager:revealFogOfWar( 35, 4, 2, false );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	Utils:setIsAttackable( ACId, true );
	ScriptManager:setMissionStatus( missionIds.destroyAC, MissionStatus.IN_PROGRESS );
	
	if ScriptManager:getMissionStatus( missionIds.deploySupplyCrate ) == MissionStatus.NOT_STARTED then
		ScriptManager:setMissionStatus( missionIds.deploySupplyCrate, MissionStatus.IN_PROGRESS );
		ScriptManager:addOnDropUnitTrigger( GlobalAbility.SUPPLY_CRATE, 0, -1, -1, -1, "supplyCrateDeployed", "supplyCrateDeployed" );
	end
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

function ACDestroyed()
	ScriptManager:removeTrigger( "ACDestroyed" );
	ScriptManager:runForPlayer( 0, "prepareAcMissionDone" );
end

function prepareAcMissionDone()
	table.insert( queueTable, startAcMissionDone );
	Utils:cutsceneQueue();
end

function startAcMissionDone()
	Utils:setMissionStatus( missionIds.destroyAC, MissionStatus.ACCOMPLISHED );
end

function onUnitCreated( createdUnit )
	local posX = createdUnit:getX();
	
	if posX == 28 then -- destroy bridge trigger
		if ScriptManager:getValue( "bridgeDestroyTrigger" ) == 0 then
			destroyBridge( 0, 0, 0, createdUnit:getTemplateId() );
		end
	
	elseif posX == 29 then -- south bridge crossed trigger
		if ScriptManager:getValue( "southBridgeCrossedTrigger" ) == 0 then
			southernBridgeCrossed();
		end
	end
end

function destroyBridge( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	if unitTemplateId ~= Units.X_PLANE_BOMBER or unitTemplateId ~= Units.X_PLANE_HEAVY
	or unitTemplateId ~= Units.X_PLANE_LIGHT  or unitTemplateId ~= Units.X_PLANE_SCOUT
	or unitTemplateId ~= Units.X_PLANE_TRANSPORT then
		ScriptManager:removeTrigger("destroyBridge");
		ScriptManager:storeValue( "bridgeDestroyTrigger", 1 ); -- for paratrooper
		
		local orderId;
		
		ScriptManager:spawnUnit( 1, Units.L_TRUCK_AA,		36, 25, enemySquadIds.easternReinforcements );
		ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG,	37, 25, enemySquadIds.easternReinforcements );
		ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME,	36, 26, enemySquadIds.easternReinforcements );
		ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT,	36, 27, enemySquadIds.easternReinforcements );
		
		orderId = ScriptManager:addOrder( enemySquadIds.easternReinforcements, 36, 15, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		local bridge = Unit:getUnitById( 11 );
		local bridgePlayerId = bridge:getPlayerId();
		if bridgePlayerId == -1 then
			ScriptManager:addOrder( enemySquadIds.easternReinforcements, 35, 16, -1, 2, AiOrder.DEFEND );
		else
			orderId = ScriptManager:addOrder( enemySquadIds.easternReinforcements, 29, 14, -1, 2, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
		end
		
		orderId = ScriptManager:addOrder( enemySquadIds.easternReinforcements, 23, 13, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		orderId = ScriptManager:addOrder( enemySquadIds.easternReinforcements, 24, 25, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( enemySquadIds.easternReinforcements, 24, 25, -1, 2, AiOrder.DEFEND );
		
		table.insert( queueTable, destroyBridgeCutscene );
		
		Utils:cutsceneQueue();
	end
end

function destroyBridgeCutscene()
	ScriptManager:wait( 0.5 );
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 31, 26, 0.7, 1, true );
	ScriptManager:revealFogOfWar( 32, 26, 1, true );
	
	local unit = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 33, 28, -1 );
	local unitId = unit:getId();
	ScriptManager:moveUnitEx( unitId, 32, 26, true );
	Utils:antiRush();
	ScriptManager:detonateBridge( unitId, northernBridgeId );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY2_FLAVOR3 );
	ScriptManager:wait( 3 );
	
	ScriptManager:revealFogOfWar( 32, 26, 1, false );
	ScriptManager:moveUnitEx( unitId, 33, 28, true );
	ScriptManager:removeUnitEx( unitId, false );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( 28, 26, 0.7, 1, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY2_FLAVOR4 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( 24, 24, 0.7, 1, false );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY2_FLAVOR5 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
end

function supplyBaseCaptured()
	ScriptManager:removeTrigger( "destroyBridge" );
	Utils:setMissionStatus( missionIds.captureBase, MissionStatus.ACCOMPLISHED );
	
	checkForVictory();
	
	Utils:setIsAttackable( supplyBaseId, true );
	
	ScriptManager:gainGold( 0, 500 );
	table.insert( queueTable, supplyBaseCapturedCutscene );
	Utils:cutsceneQueue();
end

function supplyBaseCapturedCutscene()
	local orderId;
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY1_FLAVOR1 );
	
	ScriptManager:spawnUnit( 0, Units.X_TANK_HEAVY,			37, 25, -1 );
	ScriptManager:spawnUnit( 0, Units.X_ARTILLERY_HOWITZER,	38, 26, -1 );
	ScriptManager:spawnUnit( 0, Units.X_TRUCK_AA,			37, 27, -1 );
	
	ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 21, 25, enemySquadIds.planeReinforcements );
	ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 22, 25, enemySquadIds.planeReinforcements );
	ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 23, 25, enemySquadIds.planeReinforcements );
	
	orderId = ScriptManager:addOrder( enemySquadIds.planeReinforcements, 37, 26, -1, 1, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:addOrder( enemySquadIds.planeReinforcements, 37, 26, -1, 1, AiOrder.DEFEND );
	
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG,	25, 28, enemySquadIds.westernReinforcements );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT,	24, 28, enemySquadIds.westernReinforcements );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_FLAME,	23, 28, enemySquadIds.westernReinforcements );
	
	orderId = ScriptManager:addOrder( enemySquadIds.westernReinforcements, 23, 13, -1, 1, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local bridge = Unit:getUnitById( 11 );
	local bridgePlayerId = bridge:getPlayerId();
	if bridgePlayerId == -1 then
		ScriptManager:addOrder( enemySquadIds.westernReinforcements, 23, 13, -1, 2, AiOrder.DEFEND );
		
	else
		local orderId = ScriptManager:addOrder( enemySquadIds.westernReinforcements, 29, 14, -1, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	end
	
	orderId = ScriptManager:addOrder( enemySquadIds.westernReinforcements, 36, 15, -1, 1, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	orderId = ScriptManager:addOrder( enemySquadIds.westernReinforcements, 36, 26, -1, 1, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	ScriptManager:addOrder( enemySquadIds.westernReinforcements, 36, 26, -1, 2, AiOrder.DEFEND );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx(		35, 4, 0.7,	5, false );
	ScriptManager:revealFogOfWar(	35, 4,		2, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_PRIMARY1_FLAVOR2 );
	ScriptManager:wait( 5 );
	
	ScriptManager:showMarkerAt( 35, 4 );
	ScriptManager:wait( 2 );
	ScriptManager:hideMarkerAt( 35, 4 );
	ScriptManager:moveCameraEx( 37, 26, 0.7, 3, false );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyAC, MissionStatus.IN_PROGRESS );
end

function southernBridgeCrossed( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	if unitTemplateId ~= Units.X_PLANE_BOMBER	or unitTemplateId ~= Units.X_PLANE_HEAVY
	or unitTemplateId ~= Units.X_PLANE_LIGHT	or unitTemplateId ~= Units.X_PLANE_SCOUT
	or unitTemplateId ~= Units.X_PLANE_TRANSPORT then
		ScriptManager:removeTrigger( "southernBridgeCrossed" );
		table.insert( queueTable, southernBridgeCrossedCutscene );
		Utils:cutsceneQueue();
	end
end

function southernBridgeCrossedCutscene()
	Utils:startCutscene()
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_SECONDARY1_FLAVOR1 )
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.deploySupplyCrate, MissionStatus.IN_PROGRESS );
	
	ScriptManager:addOnDropUnitTrigger( GlobalAbility.SUPPLY_CRATE, 0, -1, -1, -1, "supplyCrateDeployed", "supplyCrateDeployed" );
end

function supplyCrateDeployed()
	if ScriptManager:getMissionStatus( missionIds.deploySupplyCrate ) == MissionStatus.IN_PROGRESS then 
		Utils:setMissionStatus( missionIds.deploySupplyCrate,MissionStatus.ACCOMPLISHED );
		ScriptManager:removeTrigger( "supplyCrateDeployed" );
	end
end

function checkForVictory()
	if	ScriptManager:getMissionStatus(missionIds.captureAirfield)	== MissionStatus.ACCOMPLISHED
	and ScriptManager:getMissionStatus(missionIds.captureBase)		== MissionStatus.ACCOMPLISHED then
		startVictoryCutscene();
	end
end

function playerBaseGone()
	--[[
		when player base is gone, most squads on the map still have the order to capture it 
		so i have to change the last order to the alternative target ( all new squads will get that automatically ).
		thats why the turn after it was captured i go through all squads, remove the last order and replace it
	]]
	ScriptManager:runForPlayer( 0, "newLastOrderPreparations" );
end

function newLastOrderPreparations()
	ScriptManager:addOnAiCalculationTrigger( true, "setNewLastOrder", "setNewLastOrder" );
end

function setNewLastOrder( squadId, currentOrderMessageData, allOrderMessageData )
	local latestSquad = ScriptManager:getValue( "freeSquadId" )
	
	if squadId >= freeSquadIdStart and squadId <= latestSquad then
		local count = allOrderMessageData:count();
		if count > 0 then
			 -- get the last order ( attack player base ) remove it and replace it by new order as player base is already taken
			 local omd = tolua.cast( allOrderMessageData:objectAtIndex( count - 1 ), "OrderMessageData");
			 ScriptManager:removeOrder( squadId, omd:getOrderId() );
			 
			 local orderId = ScriptManager:addOrder( squadId, 23, 26, -1, 3, AiOrder.ATTACK );
			 ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			 ScriptManager:addOrder( squadId, 23, 26, -1, 3, AiOrder.DEFEND );
		end
	end
end

function bridgeOrder( squadId, bridgeId )
	local bridge = Unit:getUnitById( bridgeId );
	local orderId;
	if bridge:getPlayerId() == 0 then
		orderId = ScriptManager:addOrder( squadId, -1, -1, bridgeId, 2, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	end
end

function spawnLctAndOrders( spawnX, spawnY, moveX, moveY, maxRng, bridgeOnWay )
	local squadId = ScriptManager:getValue( "freeSquadId" );
	ScriptManager:storeValue( "freeSquadId", ScriptManager:getValue("freeSquadId") + 1 );
	
	local rng = math.random( 1, maxRng );
	
	local templateId;
	if rng == 1 then 
		templateId = Units.L_INFANTRY_AT;
		
	elseif rng == 2 then 
		templateId = Units.L_INFANTRY_MG;
		
	elseif rng == 3 then
		templateId = Units.L_INFANTRY_FLAME;
		
	elseif rng == 4 then
		templateId = Units.L_TANK_LIGHT;
	end
	
	-- spawn
	ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, templateId, spawnX, spawnY, squadId );
	
	-- move to coast
	local orderId = ScriptManager:addOrder( squadId, moveX, moveY, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
	
	-- capture bridges if they are in the way
	if bridgeOnWay == 1 then
		--ScriptManager:addOrder( squadId, 4, 13, -1, 3, AiOrder.ATTACK );
		bridgeOrder( squadId, outerBridgeId );
		bridgeOrder( squadId, innerBridgeId );
		
	elseif bridgeOnWay == 2 then
		bridgeOrder( squadId, southernBridgeId );
	end
	
	-- attack player depot if still alive
	local unit = Unit:getUnitById( playerBaseId );
	local unitPlayerId = unit:getPlayerId();
	if unitPlayerId == 0 then
		orderId = ScriptManager:addOrder( squadId, -1, -1, playerBaseId, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
		
	else
		local defX, defY;
		-- if enemy runs over the southern bridge, go back to the depot, otherwise go to airfield
		if bridgeOnWay == 2 then
			defX = 35;
			defY = 25;
			
			bridgeOrder( squadId, southernBridgeId ); -- give bridge order again because they have to cross again and the player may have captured it 
			
		else
			defX = 23;
			defY = 26;
		end
		
		local orderId = ScriptManager:addOrder( squadId, defX, defY, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( squadId, defX, defY, -1, 3, AiOrder.DEFEND );
	end
end

function onEnemyTurnStart()
	local currentRound = ScriptManager:getCurrentRound();
	if currentRound % 2 == 0 then
		spawnLctAndOrders( 1, 20,	3, 23,	4, 0 );
		
	else
		spawnLctAndOrders( 1, 1,	13, 9,	4, 0 );
	end
	
	local spawnX, spawnY, moveX, moveY;
	local rng = math.random( 1, 2 );
	if rng == 1 then
		spawnX	=  1;
		spawnY	= 18;
		moveX	=  2;
		moveY	= 16;
		
	elseif rng == 2 then
		spawnX	= 1;
		spawnY	= 4;
		moveX	= 3;
		moveY	= 9;
	end
	spawnLctAndOrders( spawnX, spawnY, moveX, moveY, 4, 1 );
	
	local AC = Unit:getUnitById( ACId );
	if AC ~= nil then
		if currentRound % 2 == 0 then
			spawnLctAndOrders( 35, 5,	35, 10,		2, 2 );
			
		else
			rng = math.random( 1, 2 );
			if rng == 1 then
				moveX = 25;
				moveY =  8;
			
			else
				moveX = 21;
				moveY =  3;
			end
			spawnLctAndOrders( 31, 4,	moveX, moveY,	4, 0 );
		end
	end
end

function spawnAcPlane()
	local AC = Unit:getUnitById( ACId );
	if AC ~= nil then
		ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 33, 4, enemySquadIds.plane );
		
		local orderId = ScriptManager:addOrder( enemySquadIds.plane, 15, 9, -1, 1, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		orderId = ScriptManager:addOrder( enemySquadIds.plane, 15, 27, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
		
		ScriptManager:addOrder( enemySquadIds.plane, 15, 27, -1, 3, AiOrder.ATTACK );
		
		orderId = ScriptManager:addOrder( enemySquadIds.plane, 23, 26, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( enemySquadIds.plane, 23, 26, -1, 5, AiOrder.DEFEND );
	end
end

function spawnWesternPlane()
	local templateId;
	local rng = math.random( 1, 2 );
	if rng == 1 then
		templateId = Units.L_PLANE_BOMBER;
		
	else
		templateId = Units.L_PLANE_HEAVY;
	end
	
	local spawnX, spawnY;
	rng = math.random( 1, 2 );
	if rng == 1 then
		spawnX = 1;
		spawnY = 4;
		
	else
		spawnX =  1;
		spawnY = 17;
	end
	
	local unit = ScriptManager:spawnUnit( 1, templateId, spawnX, spawnY, enemySquadIds.westernPlane );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.westernPlane, 4, 13, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	orderId = ScriptManager:addOrder( enemySquadIds.westernPlane, 15, 27, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	ScriptManager:addOrder( enemySquadIds.westernPlane, 14, 26, -1, 2, AiOrder.DEFEND );
end

function acPlaneDestroyed()
	ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "spawnAcPlane", "spawnAcPlane" );
end

function westernPlaneDestroyed()
	ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "spawnWesternPlane", "spawnWesternPlane" );
end


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_VICTORY_FLAVOR1 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_2_VICTORY_FLAVOR2 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
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


function showAttackedWarning1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ );
end

function showAttackedWarning2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_AIRFIELD );
end

function stopAttackingHint1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_HQ );
end

function stopAttackingHint2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
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