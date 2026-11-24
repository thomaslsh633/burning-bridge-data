require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	recaptureOutpost	= 1,
	recaptureIsland		= 2,
	destroyAC			= 3,
	recaptureBunkers	= 4,
	destroyBS			= 5,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.recaptureOutpost,	true,	Text.T_MISSION_CAP_OUTPOST,		100 },
	{ missionIds.recaptureIsland,	true,	Text.T_CAMP_X1_3_PRIMARY2,		150 },
	{ missionIds.destroyAC,			true,	Text.T_CAMP_X1_3_PRIMARY3,		125 },
	{ missionIds.recaptureBunkers,	false,	Text.T_CAMP_X1_3_SECONDARY1,	100 },
	{ missionIds.destroyBS,			false,	Text.T_CAMP_X1_3_SECONDARY2, 	 75 },
};

enemySquadIds = {
	firstEncounter					=  1,
	southernVillageDefenders1		=  2,
	southernVillageDefenders2 		=  3,
	lonelyAA						=  4,
	outpostDefenders				=  5,
	northernVillageDefenders		=  6,
	northernDefenders				=  7,
	centralArtillery				=  8,
	islandDefender					=  9,
	easternArtillerybunker			= 10,
	easternVillageArtilleryBunker	= 11,
	easternVillageBunker			= 12,
	northernBS						= 13,
	southernBS						= 14,
	easternRoadDefenders			= 15,
	plane							= 16,
	outpostGuard					= 17,
	ac								= 18,
	-- lctSquad in save file starts @19
};

depotId			=  7;
ACId			=  3;
northernBSId	=  4;
southernBSId	=  0;
engineerId		= 22;
bridgeId		= 12;


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1000 );
	
	local AC = Unit:getUnitById( ACId );
	AC:setIsAttackable( false );
	
	Utils:setIsAttackable( depotId, false );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "remainingIslandBunkers",	 3 );
	ScriptManager:storeValue( "remainingBunkers",		 5 );
	ScriptManager:storeValue( "bridgeDestroyTrigger",	 0 );
	ScriptManager:storeValue( "lctSquad",				19 );
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	 1, Units.X_BUILDING_HQ,			 -1, "showAttackedWarning",		"showAttackedWarning" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.X_BUILDING_HQ,			 -1, "stopAttackingHint",		"stopAttackingHint" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.N_EMPLACEMENT_BUNKER,		 -1, "stopAttackingBunkerHint",	"stopAttackingBunkerHint" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "stopAttackingBunkerHint",	"stopAttackingBunkerHint" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.X_ARTILLERY_COAST_SE,		 -1, "stopAttackingBunkerHint",	"stopAttackingBunkerHint" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.X_ARTILLERY_COAST_SW,		 -1, "stopAttackingBunkerHint",	"stopAttackingBunkerHint" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.X_BUILDING_HQ,			 -1, "transitionToFail",		"transitionToFail" );
	
	--capturing outposts accomplishes missionIds.capturOutpost
	ScriptManager:addOnUnitCapturedTrigger( -1, Units.X_BUILDING_HQ, -1, "outpostCaptured", "outpostCaptured" );
	
	--manning all remaining bunkers on the island accomplishes missionIds.recaptureIsland
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_ARTILLERY_COAST_SW,		16, "islandBunkerDestroyed", "islandBunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_EMPLACEMENT_BUNKERTOWER,	13, "islandBunkerDestroyed", "islandBunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_EMPLACEMENT_BUNKER,		 8, "islandBunkerDestroyed", "islandBunkerDestroyed" );
	
	-- trigger for going near the island
	for i = 1, 25 do
		if i <= 18 then -- prevents double trigger on 18 | 24
			ScriptManager:addOnEnterTileTrigger( i, 25, 0, -1, -1, true, "nearIsland", "nearIsland" );
		end
		ScriptManager:addOnEnterTileTrigger( 19, i, 0, -1, -1, true, "nearIsland", "nearIsland" );
	end
	ScriptManager:addOnDropUnitTrigger( GlobalAbility.PARATROOPER, 0, -1, -1, -1, "onParatrooperDropped", "onParatrooperDropped" );
	
	--spawn enemy Units each round at AC if island has yet been reconquered and prevent artillery from moving
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	
	--trigger for ac plane
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, 					"spawnAcPlane",		"spawnAcPlane" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.plane,	"acPlaneDestroyed", "acPlaneDestroyed" );
	
	--destroying the AC accomplishes missionIds.destroyAC
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_SHIP_AC, -1, "ACDestroyed", "ACDestroyed" );
	
	--when the battleships attacks or is being attacked missionIds.destroyBS will be activated
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.L_SHIP_BS, -1, "BShasAttacked", "BShasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 0, Units.L_SHIP_BS, -1, "BSwasAttacked", "BSwasAttacked" );
	
	--destroying both battleships accomplishes missionIds.destroyBS
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_SHIP_BS, -1, "BSdestroyed", "BSdestroyed" );
	
	--check for number of occupied bunkers
	ScriptManager:addOnUnitOccupiedTrigger( -1, -1, -1, "unitEnterdTransporter",	"unitEnterdTransporter" );
	ScriptManager:addOnUnitUnloadedTrigger( -1, -1, -1, "unitLeftTransporter",		"unitLeftTransporter" );
	
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_EMPLACEMENT_BUNKER,		-1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_EMPLACEMENT_BUNKERTOWER,	-1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_ARTILLERY_COAST_SE,		-1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_ARTILLERY_COAST_SW,		-1, "bunkerDestroyed", "bunkerDestroyed" );
	
	--destroy northern bridge if player attempts to cross it
	Utils:addOnEnterAreaTrigger( 17, 23, 1, 0, -1, -1, true, "destroyBridge", "destroyBridge" );
	
	-- trigger for paratrooper and on enter tile triggers
	ScriptManager:addOnUnitCreatedTrigger( 0, -1, "onUnitCreated", "onUnitCreated" );
end

function addAiOrders()
	ScriptManager:addOrder( enemySquadIds.firstEncounter,				 29, 17, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernVillageDefenders1,	 27, 11, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernVillageDefenders2,	 23, 12, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.lonelyAA,						 21, 17, -1, 5, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.outpostDefenders,				 20, 26, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.northernVillageDefenders,		 12, 29, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.northernDefenders,			  6, 30, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.centralArtillery,				 14, 19, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.islandDefender,				 10, 16, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternArtillerybunker,		 32, 14, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternVillageArtilleryBunker, 25,  7, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternVillageBunker,			 21,  8, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.northernBS,					  4, 20, -1, 9, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernBS,					 13,  5, -1, 9, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternRoadDefenders,			 22, 20, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.outpostGuard,					 21, 29, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.ac,							  4,  5, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:camouflageUnit( 51 );
	ScriptManager:camouflageUnit( 64 );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 24, 10, 0.5, 5, false );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_INTRO_FLAVOR1 );
	ScriptManager:wait( 7 );
	
	ScriptManager:moveCameraEx( 21, 29, 0.7, 5, true );
	Utils:hideDialogue();
	
	ScriptManager:revealFogOfWar(	21, 29, 1, true );
	ScriptManager:showMarkerAt(		21, 29 );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_INTRO_FLAVOR2 );
	ScriptManager:wait( 5 );
	ScriptManager:hideMarkerAt(		21, 29 );
	ScriptManager:revealFogOfWar(	21, 29, 1, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 30, 27, 0.7, 3, false );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.recaptureOutpost, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.recaptureBunkers, MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.recaptureBunkers,	0, 10 );
	Utils:setMissionProgress( missionIds.recaptureIsland,	0,  3 );
	Utils:setMissionProgress( missionIds.destroyBS,			0,  2 );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 21, 32, 0 );
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD,  1,  1, 0 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN


function outpostCaptured()
	ScriptManager:removeTrigger( "outpostCaptured" );
	
	Utils:setIsAttackable( depotId, true ); -- for ai to attack it
	
	table.insert( queueTable, outpostCapturedCutscene );
	Utils:cutsceneQueue();
end

function outpostCapturedCutscene()
	Utils:setMissionStatus( missionIds.recaptureOutpost, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY1_FLAVOUR1 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	if	ScriptManager:getMissionStatus(missionIds.recaptureIsland) ~= MissionStatus.IN_PROGRESS then
		ScriptManager:moveCameraEx( 10, 15, 0.5, 3, false );
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY1_FLAVOUR2 );
		ScriptManager:wait( 3 );
		Utils:hideDialogue();
		
		islandCutscene( 21, 28 );
	
	else
		Utils:endCutscene();
	end
end

function onParatrooperDropped( targetTileX, targetTileY, spawnedTileX, spawnedTileY, dropedUnit )
	if spawnedTileX <= 25 and spawnedTileY <= 19 then
		nearIsland( spawnedTileX, spawnedTileY );
	end
end

function nearIsland( tileX, tileY, playerId, unitTemplateId, unitId )
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 10, 15, 0.5, 5, true );
	islandCutscene( tileX, tileY );
end

function islandCutscene( returnPosX, returnPosY )
	ScriptManager:revealFogOfWar( 10, 15, 3, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY1_FLAVOUR3 );
	ScriptManager:wait( 5 );
	ScriptManager:revealFogOfWar( 10, 15, 3, false );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( returnPosX, returnPosY, 0.7, 5, false );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY1_FLAVOUR4 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.recaptureIsland, MissionStatus.IN_PROGRESS );
	ScriptManager:removeTrigger( "nearIsland" );
	ScriptManager:removeTrigger( "onParatrooperDropped" );
end

function unitEnterdTransporter( transporter )
	adjustUnitsInBunker( transporter, 1 );
end

function unitLeftTransporter( transporter )
	adjustUnitsInBunker( transporter, -1 );
end

function adjustUnitsInBunker( transporter, value )
	local transporterTemplateId = transporter:getTemplateId();
	
	if transporterTemplateId == Units.X_ARTILLERY_COAST_SE
	or transporterTemplateId == Units.X_ARTILLERY_COAST_SW
	or transporterTemplateId == Units.N_EMPLACEMENT_BUNKER
	or transporterTemplateId == Units.N_EMPLACEMENT_BUNKERTOWER then
		--ScriptManager:setMissionProgress( missionIds.recaptureBunkers, ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) + value );
		
		local bunkerId = transporter:getId();
		if bunkerId == 16 or bunkerId == 13 or bunkerId == 8 then
			if value == 1 then
				enteredIslandBunker();
			
			else
				leftIslandBunker();
				--unitLeftBunker(); -- for secondary mission
			end
		
		else
			ScriptManager:setMissionProgress( missionIds.recaptureBunkers, ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) + value );
			
			if value == 1 then
				unitEnterdBunker();
			
			else
				unitLeftBunker();
			end
		end
	end
end

function enteredIslandBunker()
	--[[if ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) >= ScriptManager:getValue( "remainingBunkers" ) then
		ScriptManager:setMissionStatus( missionIds.recaptureBunkers, MissionStatus.ACCOMPLISHED );
	end]]
	
	--TODO: atm when done with mission and leave bunker after the mission still is done. mb reset mission then
	if ScriptManager:getMissionStatus( missionIds.recaptureIsland ) ~= MissionStatus.ACCOMPLISHED then
		--print( "enteredIslandBunker" )
		Utils:incrementMissionProgress( missionIds.recaptureIsland );
		--print("captured bunkers on island:" );
		--print( ScriptManager:getMissionProgress( missionIds.recaptureIsland ) );
		
		if ScriptManager:getMissionProgress( missionIds.recaptureIsland ) == ScriptManager:getMaxMissionProgress( missionIds.recaptureIsland ) then
			ScriptManager:setMissionStatus( missionIds.recaptureIsland, MissionStatus.ACCOMPLISHED );
			table.insert( queueTable, islandRecapturedCutscene );
			Utils:cutsceneQueue();
		
		else
		 	table.insert( queueTable, islandRecaptureProgressPopup );
			Utils:cutsceneQueue();
		end
	end
end

function islandRecapturedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR1 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx(		4, 5, 1, 1, false );
	ScriptManager:revealFogOfWar(	4, 5, 2, true );
	ScriptManager:showMarkerAt(		4, 5 );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR2 );
	ScriptManager:wait( 5 );
	
	local AC = Unit:getUnitById( ACId );
	AC:setIsAttackable( true );
	
	ScriptManager:hideMarkerAt(		4, 5 );
	ScriptManager:revealFogOfWar(	4, 5, 2, false );
	Utils:hideDialogue();
	
	if ScriptManager:getMissionStatus( missionIds.destroyBS ) == MissionStatus.NOT_STARTED then
		ScriptManager:moveCameraEx( 	 8, 13, 0.3, 2, true );
		ScriptManager:revealFogOfWar(	 4, 20, 2, true );
		ScriptManager:revealFogOfWar(	13,  5, 2, true );
		ScriptManager:showMarkerAt(		 4, 20 );
		ScriptManager:showMarkerAt(		13,  5 );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR3 );
		ScriptManager:wait( 5 );
		Utils:hideDialogue();
		
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR4 );
		ScriptManager:wait( 5 );
		ScriptManager:setMissionStatus( missionIds.destroyBS, MissionStatus.IN_PROGRESS );
		ScriptManager:removeAllMarkers();
		ScriptManager:revealFogOfWar(  4, 20, 2, false );
		ScriptManager:revealFogOfWar( 13,  5, 2, false );
		Utils:hideDialogue();
	end
	
	ScriptManager:moveCameraEx( 11, 15, 0.7, 2, true );
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionIds.destroyAC, MissionStatus.IN_PROGRESS );
	
	if	ScriptManager:getMissionStatus( missionIds.destroyBS ) == MissionStatus.NOT_STARTED then
		ScriptManager:setMissionStatus( missionIds.destroyBS, MissionStatus.IN_PROGRESS );
	end
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

function leftIslandBunker()
	if ScriptManager:getMissionStatus( missionIds.recaptureIsland ) ~= MissionStatus.ACCOMPLISHED then
		--print( "leftIslandBunker" );
		ScriptManager:setMissionProgress( missionIds.recaptureIsland, ScriptManager:getMissionProgress( missionIds.recaptureIsland ) - 1 );
		--print( "mission progress recap island:" );
		--print( ScriptManager:getMissionProgress( missionIds.recaptureIsland ) );
		table.insert( queueTable, islandRecaptureProgressPopup );
		Utils:cutsceneQueue();
	end
end

function islandRecaptureProgressPopup()
	Utils:disablePlayerInteraction();
	
	ScriptManager:preparePopupText();
	ScriptManager:addPopupTextParameter( "mannedBunkers",			ScriptManager:getMissionProgress( missionIds.recaptureIsland ) );
	ScriptManager:addPopupTextParameter( "remainingIslandBunkers",	ScriptManager:getValue( "remainingIslandBunkers" ) );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_COUNTER );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:enablePlayerInteraction();
end

function islandBunkerDestroyed( bunker )
	local bunkerX = bunker:getX();
	local bunkerY = bunker:getY();
	
	ScriptManager:storeValue( "bunkerX", bunkerX );
	ScriptManager:storeValue( "bunkerY", bunkerY );
	ScriptManager:storeValue( "remainingIslandBunkers", ScriptManager:getValue( "remainingIslandBunkers" ) - 1 );
	ScriptManager:setMaxMissionProgress( missionIds.recaptureIsland, ScriptManager:getMaxMissionProgress( missionIds.recaptureIsland ) - 1 );
	
	local loadedUnit = bunker:getLoadedUnitAt( 0 );
	local loadedUnitFaction = loadedUnit:getPlayerId();
	if loadedUnitFaction == 0 then
		ScriptManager:setMissionProgress( missionIds.recaptureIsland, ScriptManager:getMissionProgress( missionIds.recaptureIsland ) - 1 );
		--print( "remaining island bunkers:" );
		--print(ScriptManager:getValue( "remainingIslandBunkers" ) );
		--print( "mission progress recap island:" );
		--print( ScriptManager:getMissionProgress( missionIds.recaptureIsland ) );
	end
	
	if ScriptManager:getValue( "remainingIslandBunkers" ) <= 0 then
		Utils:setMissionStatus( missionIds.recaptureIsland, MissionStatus.FAILED );
		transitionToFail();
		
	else
		ScriptManager:runForPlayer( 0, "prepareislandBunkerDestroyedCutscene" );
	end
end

function  prepareislandBunkerDestroyedCutscene()
	table.insert( queueTable, islandBunkerDestroyedCutscene );
	Utils:cutsceneQueue();
end

function islandBunkerDestroyedCutscene()
	local bunkerX = ScriptManager:getValue( "bunkerX" );
	local bunkerY = ScriptManager:getValue( "bunkerY" );
	
	Utils:startCutscene()
	
	ScriptManager:moveCameraEx( bunkerX, bunkerY, 1, 1, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR5 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_PRIMARY2_FLAVOR6 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
end

function onEnemyTurnStart()
	local artillery = Unit:getUnitById( 44 );
	if artillery ~= nil then
		artillery:setActionPoints( 0 );
	end
	
	if ScriptManager:getMissionStatus( missionIds.recaptureIsland ) == MissionStatus.ACCOMPLISHED then
		local templateId;
		local rng = math.random( 1, 3 );
		
		if rng == 1 then
			templateId = Units.L_INFANTRY_AT;
		elseif rng == 2 then
			templateId = Units.L_TANK_LIGHT;
		elseif rng == 3 then
			templateId = Units.L_INFANTRY_MG;
		end
		
		local moveX, moveY;
		local rng = math.random( 1, 2 );
		
		if rng == 1 then
			moveX =  9;
			moveY = 10;
			
		else
			moveX =  6;
			moveY = 15;
		end
		
		local squadId	= ScriptManager:getValue( "lctSquad" );
		ScriptManager:storeValue( "lctSquad", ScriptManager:getValue( "lctSquad" ) );
		
		local unit		= ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, templateId, 6, 8, squadId );
		local orderId	= ScriptManager:addOrder( squadId, moveX, moveY, -1, 1, AiOrder.MOVE );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
		ScriptManager:addOrder( squadId, 10, 16, -1, 2, AiOrder.DEFEND );
	end
end

function spawnAcPlane()
	ScriptManager:removeTrigger( "spawnAcPlane" );
	ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 5, 7, enemySquadIds.plane );
	
	local orderId;
	if ScriptManager:getMissionStatus(missionIds.recaptureOutpost) ~= MissionStatus.ACCOMPLISHED then
		orderId = ScriptManager:addOrder( enemySquadIds.plane, 24, 10, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( enemySquadIds.plane, 24, 10, -1, 5, AiOrder.DEFEND );
	
	else
		orderId = ScriptManager:addOrder( enemySquadIds.plane, 21, 29, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( enemySquadIds.plane, 21, 29, -1, 5, AiOrder.DEFEND );
	end
end

function acPlaneDestroyed()
	ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "spawnAcPlane", "spawnAcPlane" );
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
	startVictoryCutscene();
end

function BShasAttacked( attackerUnit, isAoe , defenderUnit, defenderUnits, unitsHit )
	ScriptManager:removeTrigger( "BShasAttacked" );
	ScriptManager:removeTrigger( "BSwasAttacked" );
	
	local BSX			= attackerUnit:getX();
	local BSY			= attackerUnit:getY();
	local defenderUnitX	= defenderUnit:getX();
	local defenderUnitY	= defenderUnit:getY();
	
	ScriptManager:storeValue( "BSX", BSX );
	ScriptManager:storeValue( "BSY", BSY );
	ScriptManager:storeValue( "defenderUnitX", defenderUnitX );
	ScriptManager:storeValue( "defenderUnitY", defenderUnitY );
	
	ScriptManager:runForPlayer( 0, "prepareBShasAttackedCutscene" );
end

function prepareBShasAttackedCutscene()
	table.insert( queueTable, BShasAttackedCutscene );
	Utils:cutsceneQueue();
end

function BShasAttackedCutscene()
	local BSX			= ScriptManager:getValue( "BSX" );
	local BSY			= ScriptManager:getValue( "BSY" );
	local defenderUnitX	= ScriptManager:getValue( "defenderUnitX" );
	local defenderUnitY	= ScriptManager:getValue( "defenderUnitY" );
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( BSX, BSY, 0.7, 1, true );
	
	ScriptManager:revealFogOfWar(	BSX, BSY, 2, true );
	ScriptManager:showMarkerAt(		BSX, BSY );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY2_FLAVOR1 );
	ScriptManager:wait( 3 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY2_FLAVOR2 );
	ScriptManager:wait( 3 );
	
	ScriptManager:hideMarkerAt(		BSX, BSY );
	ScriptManager:revealFogOfWar(	BSX, BSY, 2, false );
	
	ScriptManager:moveCameraEx( defenderUnitX, defenderUnitY, 0.7, 2, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyBS, MissionStatus.IN_PROGRESS );
end

function BSwasAttacked( attackerUnit, isAoe , defenderUnit, defenderUnits, unitsHit )
	ScriptManager:removeTrigger( "BShasAttacked" );
	ScriptManager:removeTrigger( "BSwasAttacked" );
	
	local BSX = defenderUnit:getX();
	local BSY = defenderUnit:getY();
	local attackerUnitX = attackerUnit:getX();
	local attackerUnitY = attackerUnit:getY();
	
	ScriptManager:storeValue( "BSX", BSX );
	ScriptManager:storeValue( "BSY", BSY );
	ScriptManager:storeValue( "attackerUnitX", attackerUnitX );
	ScriptManager:storeValue( "attackerUnitY", attackerUnitY );
	
	table.insert( queueTable, BSwasAttackedCutscene );
	
	Utils:cutsceneQueue();
end

function BSwasAttackedCutscene()
	local BSX = ScriptManager:getValue( "BSX" );
	local BSY = ScriptManager:getValue( "BSY" );
	local attackerUnitX = ScriptManager:getValue( "attackerUnitX" );
	local attackerUnitY = ScriptManager:getValue( "attackerUnitY" );
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY2_FLAVOR3 );
	ScriptManager:moveCameraEx(		BSX, BSY, 1, 1, true );
	ScriptManager:revealFogOfWar(	BSX, BSY, 2, true );
	ScriptManager:wait( 3 );
	
	ScriptManager:showMarkerAt( BSX, BSY );
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY2_FLAVOR4 );
	ScriptManager:wait( 3 );
	
	ScriptManager:hideMarkerAt(		BSX, BSY );
	ScriptManager:revealFogOfWar(	BSX, BSY, 2, false );
	ScriptManager:moveCameraEx( attackerUnitX, attackerUnitY, 0.7, 1, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyBS, MissionStatus.IN_PROGRESS );
end

function BSdestroyed()
	ScriptManager:setMissionProgress( missionIds.destroyBS, ScriptManager:getMissionProgress( missionIds.destroyBS ) + 1 );
	ScriptManager:runForPlayer( 0, "prepareBSprogressPopup" );
end

function prepareBSprogressPopup()
	table.insert( queueTable, BSprogressPopup );
	Utils:cutsceneQueue();
end

function BSprogressPopup()
	if ScriptManager:getMissionProgress( missionIds.destroyBS ) == 2 then
		Utils:setMissionStatus( missionIds.destroyBS, MissionStatus.ACCOMPLISHED );
		
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyBS ), Text.T_CAMP_X1_3_SECONDARY2_COUNTER );
	end
end


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_VICTORY_FLAVOR1 );
	local northernBS = Unit:getUnitById( northernBSId );
	if northernBS ~= nil then
		local northernBSX = northernBS:getX();
		local northernBSY = northernBS:getY();
		
		ScriptManager:moveCameraEx( northernBSX, northernBSY, 1, 1, true );
		
		ScriptManager:revealFogOfWar( northernBSX, northernBSY, 3, true );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_VICTORY_FLAVOR2 );
		ScriptManager:moveUnitEx( northernBSId, 0, 12, false );
		ScriptManager:wait( 1 );
		
		ScriptManager:revealFogOfWar( northernBSX, northernBSY, 3, false );
	end
	
	local southernBS = Unit:getUnitById( southernBSId )
	if southernBS ~= nil then
		local southernBSX = southernBS:getX();
		local southernBSY = southernBS:getY();
		
		ScriptManager:moveCameraEx( southernBSX, southernBSY, 1, 1, true );
		
		ScriptManager:revealFogOfWar( southernBSX, southernBSY, 3, true );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_VICTORY_FLAVOR3 );
		ScriptManager:moveUnitEx( southernBSId, 11, 0, false );
		ScriptManager:wait( 1 );
		
		ScriptManager:revealFogOfWar( southernBSX, southernBSY, 3, false );
	end
	
	ScriptManager:moveCameraEx( 12, 15, 0.7, 2, false );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_VICTORY_FLAVOR4 );
	ScriptManager:wait( 3 );
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

function unitEnterdBunker()
	--print("unitEnterdBunker")
	--print(ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) )
	
	if ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) >= ScriptManager:getValue( "remainingBunkers" ) then
		if ScriptManager:getMissionStatus( missionIds.recaptureBunkers ) ~= MissionStatus.ACCOMPLISHED then
			Utils:setMissionStatus( missionIds.recaptureBunkers, MissionStatus.ACCOMPLISHED );
		end
	
	else
		table.insert( queueTable, recaptureBunkerProgressPopup );
		Utils:cutsceneQueue();
	end
end

function unitLeftBunker()
	--print("unitLeftBunker")
	--print(ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) )
	
	if ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) < ScriptManager:getValue( "remainingBunkers" ) then
		if ScriptManager:getMissionStatus( missionIds.recaptureBunkers ) ~= MissionStatus.IN_PROGRESS then
			Utils:setMissionStatus( missionIds.recaptureBunkers, MissionStatus.IN_PROGRESS );
		end
		
		table.insert( queueTable, recaptureBunkerProgressPopup );
		Utils:cutsceneQueue();
	end
end	

function recaptureBunkerProgressPopup()
	local occupiedBunkers = ScriptManager:getMissionProgress( missionIds.recaptureBunkers );
	local remainingBunkers = ScriptManager:getValue( "remainingBunkers" );
	
	Utils:disablePlayerInteraction();
	
	ScriptManager:preparePopupText();
	ScriptManager:addPopupTextParameter( "occupiedBunkers",	 occupiedBunkers );
	ScriptManager:addPopupTextParameter( "remainingBunkers", remainingBunkers );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY1_COUNTER )
	ScriptManager:wait( 2 );
	Utils:hideDialogue();
	
	Utils:enablePlayerInteraction();
end

function bunkerDestroyed(unit)
	--ScriptManager:storeValue( "remainingBunkers", ScriptManager:getValue( "remainingBunkers" ) - 1 );
	--ScriptManager:setMaxMissionProgress( missionIds.recaptureBunkers, ScriptManager:getMaxMissionProgress( missionIds.recaptureBunkers ) - 1 );
	
	local loadedUnit = unit:getLoadedUnitAt( 0 );
	local loadedUnitFaction = loadedUnit:getPlayerId();
	
	if loadedUnitFaction == 0 then
		ScriptManager:setMissionProgress( missionIds.recaptureBunkers, ScriptManager:getMissionProgress( missionIds.recaptureBunkers ) - 1 );
		ScriptManager:runForPlayer( 0, "prepareRecaptureBunkerProgressPopup" );
	end
end

function prepareRecaptureBunkerProgressPopup()
	table.insert( queueTable, recaptureBunkerProgressPopup );
	Utils:cutsceneQueue();
end

function destroyBridge( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	if	unitTemplateId ~= Units.X_PLANE_BOMBER	and unitTemplateId ~= Units.X_PLANE_HEAVY and
		unitTemplateId ~= Units.X_PLANE_LIGHT	and unitTemplateId ~= Units.X_PLANE_SCOUT and
		unitTemplateId ~= Units.X_PLANE_TRANSPORT then
		ScriptManager:removeTrigger( "destroyBridge" );
		ScriptManager:storeValue( "bridgeDestroyTrigger", 1 );
		
		local engineer = Unit:getUnitById( engineerId );
		
		if engineer ~= nil then
			ScriptManager:runForPlayer( 0, "prepareDestroyBridgeCutscene" );
		end
	end
end

function onUnitCreated( createdUnit )
	local posX = createdUnit:getX();
	local posY = createdUnit:getY();
	
	if  ( posX >= 16 and posX <= 18 and posY >= 22 and posY <= 24 ) or	-- not 100 % the same as on enter area but i dont really care about it
		( posX >= 14 and posX <= 15 and posY == 18 ) then				-- other side of the bridge
		if ScriptManager:getValue( "bridgeDestroyTrigger" ) == 0 then
			destroyBridge( 0, 0, 0, createdUnit:getTemplateId() );
		end
	end
end

function prepareDestroyBridgeCutscene()
	table.insert( queueTable, destroyBridgeCutscene );
	Utils:cutsceneQueue();
end

function destroyBridgeCutscene()
	ScriptManager:wait( 0.5 )	--short break to prevent that the capture icon is displayed on the bridge during and after the cutscene.
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 16, 20, 0.7, 1, true );
	
	ScriptManager:revealFogOfWar( 16, 20, 1, true );
	
	ScriptManager:detonateBridge( engineerId, bridgeId );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_INTRO_FLAVOR5 );
	ScriptManager:wait( 3 );
	
	ScriptManager:revealFogOfWar( 16, 20, 1, false );
	
	ScriptManager:moveCameraEx( 17, 23, 0.7, 1, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
end


-- END Victory
-- BEGIN Defeated


function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ );
end

function stopAttackingBunkerHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	local attackerTemplateId = attacker:getTemplateId()
	
	if	attackerTemplateId ~= Units.X_INFANTRY_FLAME		and attackerTemplateId ~= Units.X_ARTILLERY_COAST_SE and
		attackerTemplateId ~= Units.X_ARTILLERY_COAST_SW	and attackerTemplateId ~= Units.N_EMPLACEMENT_BUNKER and
		attackerTemplateId ~= Units.N_EMPLACEMENT_BUNKERTOWER then
		if Unit:getUnitAt( defender:getX(), defender:getY() ) ~= nil then
			Utils:disablePlayerInteraction();
			
			ScriptManager:displaySubtitle( Text.T_CAMP_X1_3_SECONDARY1_FLAVOR1 );
			ScriptManager:wait( 2 )
			Utils:hideDialogue();
			
			Utils:enablePlayerInteraction();
		end
	end
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_HQ );
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