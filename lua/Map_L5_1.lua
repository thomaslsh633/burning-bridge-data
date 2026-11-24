require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	escortEngi		= 1,
	escortSupply	= 2,
	capAirfield		= 3,
	destroyArty		= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.escortEngi,	true,	Text.T_CAMP_L5_1_PRIMARY1,		  0 }, -- xp set when escorting is done
	{ missionIds.escortSupply,	true,	Text.T_CAMP_L5_1_PRIMARY2,		  0 }, -- xp set when escorting is done
	{ missionIds.capAirfield,	true,	Text.T_MISSION_CAP_AIRFIELD,	100 },
	{ missionIds.destroyArty,	false,	Text.T_CAMP_L5_1_SECONDARY1,	 50 },
};

enemySquadIds = {
	northBridge				=  1,
	northVillage			=  2,
	centralVillage			=  3,
	supplyCrate				=  4,
	southBridge				=  5,
	airfield				=  6,
	coastBunker				=  7,
	mountainBunker			=  8,
	city					=  9,
	northVillageArty		= 10,
	crateArty				= 11,
	cityArty				= 12,
	centralVillageMortar	= 13,
	airfieldMortar			= 14,
	planeWave				= 15,
};

northBridgeId	= 0;
southBridgeId	= 1;
crateId			= 2;
airfieldId		= 4;

airfieldPos				= {  5,  8 };
playerTransporterPos	= {  3, 31 };
engiIds					= { 14, 14, 14 }; -- always transporter Id of the player;

engisToKeep		= #engiIds;
engisSaved		= 0;

trucksToKeep	= 2;
trucksSaved		= 0;

artysToDestroy	= 5;


waypointTable = { { 9, 8 }, { 11, 15 }, { 12, 21 }, { 13, 28 }, { 9, 28 }, { 5, 22 }, { 3, 6 }, };
planeWaveRespawnInterval = 3; -- defines how often waves will spawn
spawnPlaneWaves			 = 1;

planeWave1 = {
	{ Units.X_PLANE_LIGHT, 4, 7 },
	{ Units.X_PLANE_LIGHT, 4, 8 },
};

planeWave2 = {
	{ Units.X_PLANE_HEAVY, 4, 7 },
	{ Units.X_PLANE_LIGHT, 4, 8 },
};

planeWave3 = {
	{ Units.X_PLANE_BOMBER, 4, 7 },
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:gainGold( 0, 1500 );
	
	for i = 1, #engiIds do
		ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, playerTransporterPos[1], playerTransporterPos[2], 0 );
	end
	
	-- prevent additional engineers through paratroopers
	ScriptManager:disableGlobalAbilityButton(	GlobalAbility.PARATROOPER );
	ScriptManager:enableGlobalAbilityButton(	GlobalAbility.PARATROOPER_NO_ENGI );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	Utils:saveValuesIntoSavefileForExistingTable( "engiIds", engiIds );
	
	ScriptManager:storeValue( "engisSaved",	 engisSaved );
	ScriptManager:storeValue( "trucksSaved", trucksSaved );
	
	ScriptManager:storeValue( "spawnPlaneWaves", spawnPlaneWaves );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger( -1, -1, -1, "showAttackedWarning", "showAttackedWarning" );
	
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.N_EMPLACEMENT_MG_NEST,	-1, "onPlayerUnitLost", "onPlayerUnitLost" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.L_SHIP_RUBBERBOAT,		-1, "onPlayerUnitLost", "onPlayerUnitLost" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.L_INFANTRY_ENGINEER,		-1, "onPlayerUnitLost", "onPlayerUnitLost" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.L_TRUCK_TRANSPORT,		-1, "onPlayerUnitLost", "onPlayerUnitLost" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.L_TRUCK_SUPPLY,			-1, "onPlayerUnitLost", "onPlayerUnitLost" );
	
	ScriptManager:addOnUnitOccupiedTrigger( -1, Units.L_INFANTRY_ENGINEER, -1, "onEngiEntersTransporter", "onEngiEntersTransporter" );
	ScriptManager:addOnUnitUnloadedTrigger( -1, Units.L_INFANTRY_ENGINEER, -1, "onEngiLeavesTransporter", "onEngiLeavesTransporter" );
	
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.X_BUILDING_AIRFIELD, -1,	"stopAttackingHint",	"stopAttackingHint" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.X_BUILDING_AIRFIELD, -1,	"transitionToFail",		"transitionToFail" );
	ScriptManager:addOnUnitCapturedTrigger( 	 0, Units.X_BUILDING_AIRFIELD, -1,	"onAirfieldCaptured",	"onAirfieldCaptured" );
	
	-- trigger for destroying stuff
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_ARTILLERY_HOWITZER,	-1, "onArtyAttacked", "onArtyAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_ARTILLERY_MORTAR,	-1, "onArtyAttacked", "onArtyAttacked" );
	
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_HOWITZER,	-1, "onArtyDestroyed", "onArtyDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_MORTAR,	-1, "onArtyDestroyed", "onArtyDestroyed" );
	
	--trigger for airfield mission
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_PLANE_BOMBER, -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_PLANE_HEAVY,	 -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_PLANE_LIGHT,	 -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	
	-- trigger for wave spawn
	ScriptManager:addOnTurnStartTrigger( 1, -1, 1, "spawnPlaneWave", "spawnPlaneWave" );
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planeWave, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	
	-- triggers for ai
	ScriptManager:addOnAiCalculationTrigger( true, "addAiOrders", "addAiOrders" );
end

function loadValues()
	Utils:loadValuesFromSavefileIntoExistingTable( "engiIds", engiIds );
	
	engisSaved	= ScriptManager:getValue( "engisSaved" );
	trucksSaved	= ScriptManager:getValue( "trucksSaved" );
	
	spawnPlaneWaves = ScriptManager:getValue( "spawnPlaneWaves" );
end

function addAiOrders()
	
end

function addAiOrders( squadId, mainOrderData, allMainOrderData )
	if allMainOrderData:count() <= 0 then
		print( "squad #" .. squadId .. " needs new orders" );
		
		if squadId == enemySquadIds.northBridge then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.northBridge, -1, -1, northBridgeId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.northBridge, 10, 29, -1,				3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.southBridge then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.southBridge, -1, -1, southBridgeId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.southBridge,  9, 10, -1,				3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.supplyCrate then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.supplyCrate, -1, -1, crateId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.supplyCrate, 11, 15, -1,		3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.airfield then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.airfield, -1, -1, airfieldId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.airfield,  5,  8, -1,			3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.northVillage then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.northVillage, 13, 29, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.centralVillage then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.centralVillage, 12, 19, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.city then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.city, 3,  3, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.coastBunker then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.coastBunker, 4, 12, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.mountainBunker then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.mountainBunker, 2,  9, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.northVillageArty then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.northVillageArty,	13, 30, -1, 6, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.crateArty then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.crateArty, 10, 14, -1, 6, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.cityArty then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.cityArty, 3,  3, -1, 6, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.centralVillageMortar then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.centralVillageMortar,	12, 19, -1, 4, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.airfieldMortar then
			print( "received");
		ScriptManager:addOrder( enemySquadIds.airfieldMortar, 6,  8, -1, 4, AiOrder.DEFEND );
		end
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_INTRO_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_INTRO_FLAVOR2, 3 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_1_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 5, 8, 0.7, 6, true );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_1_INTRO_FLAVOR4 );
	Utils:markUnit( 5, 8, 2, 3, 0 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_1_INTRO_FLAVOR5 );
	ScriptManager:moveCameraEx( 13, 29, 0.7, 6, true );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_SUBTITLE_INTRO_END_1 );
	ScriptManager:moveCameraEx( 4, 30, 0.7, 3, true );
	Utils:hideDialogue();
	Utils:antiRush();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.escortEngi,	 MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.escortSupply, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.capAirfield,	 MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.escortEngi,	engisToKeep,	engisToKeep );
	Utils:setMissionProgress( missionIds.escortSupply,	trucksToKeep,	trucksToKeep );
	Utils:setMissionProgress( missionIds.destroyArty,	0,				artysToDestroy );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.L_TRUCK_SUPPLY, 6, 10, 0 );
	ScriptManager:spawnUnit( 0, Units.L_TRUCK_SUPPLY, 5, 10, 0 );
	
	ScriptManager:spawnUnit( 0, Units.L_TRUCK_TRANSPORT, 4, 10, 0 );
	ScriptManager:wait( 0.25 );
	
	local unit = Unit:getUnitAt( 4, 10 );
	local id = unit:getId();
	for i = 1, #engiIds do
		ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, playerTransporterPos[1], playerTransporterPos[2], 0 );
		engiIds[i] = id;
	end
	
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		5, 14, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	5, 13, 42 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Wave Spawn


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


-- END Wave Spawn
-- BEGIN Destroying Stuff


function onArtyAttacked()
	ScriptManager:removeTrigger( "onArtyAttacked" );
	ScriptManager:runForPlayer( 0, "prepareArtyMissionCutscene" );
end

function prepareArtyMissionCutscene()
	table.insert( queueTable, showArtyMissionCutscene );
	Utils:cutsceneQueue();
end

function showArtyMissionCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_SECONDARY1_FLAVOR1, 5 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.destroyArty, MissionStatus.IN_PROGRESS );
end

function onArtyDestroyed()
	Utils:incrementMissionProgress( missionIds.destroyArty );
	ScriptManager:runForPlayer( 0, "prepareArtyMissionProgress" );
end

function prepareArtyMissionProgress()
	table.insert( queueTable, showArtyMissionProgress );
	Utils:cutsceneQueue();
end

function showArtyMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyArty ) >= artysToDestroy then
		ScriptManager:removeTrigger( "onArtyDestroyed" );
		Utils:setMissionStatus( missionIds.destroyArty, MissionStatus.ACCOMPLISHED );
		
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyArty ), Text.T_CAMP_L5_1_SECONDARY1_COUNTER );
	end
end


-- END Destroying Stuff
-- BEGIN Escort Engi / Supply Trucks


function changeIdInEngiTable( newId, oldId )
	for i = 1, #engiIds do
		if engiIds[i] == oldId then
			engiIds[i] = newId;
			Utils:saveValuesIntoSavefileForExistingTable( "engiIds", engiIds );
			break;
		end
	end
	
	for i = 1, #engiIds do
		print( engiIds[i] );
	end
end

function onEngiEntersTransporter( transporterUnit, transportedUnit )
	changeIdInEngiTable( transporterUnit:getId(), transportedUnit:getId() )
end

function onEngiLeavesTransporter( transporterUnit, transportedUnit )
	changeIdInEngiTable( transportedUnit:getId(), transporterUnit:getId() )
end

function onPlayerUnitLost( unit )
	if unit:getTemplateId() == Units.L_TRUCK_SUPPLY then
		Utils:decrementMissionProgress( missionIds.escortSupply );
		ScriptManager:runForPlayer( 0, "prepareSupplyMissionProgress" );
	
	else
		local unitId = unit:getId();
		local engineersLost = 0;
		
		--check if engis got killed
		for i = 1, #engiIds do
			--[[ it is possible that multiple engineers got killed ( if they are in the same transporter )
			so no break in the loop and the adjustment to the progress follows afterwards]]
			if engiIds[i] == unitId then
				engiIds[i] = -1;
				engineersLost = engineersLost + 1;
			end
		end
		
		-- update mission
		if engineersLost > 0 then
			local newProgress = ScriptManager:getMissionProgress( missionIds.escortEngi ) - engineersLost;
			ScriptManager:setMissionProgress( missionIds.escortEngi, newProgress );
			
			ScriptManager:runForPlayer( 0, "prepareEngiMissionProgress" );
		end
	end
end

function showEscortMissionProgress( unitsSaved, missionId, counterText )
	-- check if secure mission is accomplished because maximum just got reduced
	if unitsSaved >= ScriptManager:getMissionProgress( missionId ) and unitsSaved > 0 then
		ScriptManager:setMissionStatus( missionId, MissionStatus.ACCOMPLISHED );
		checkForVictory();
	
	else
		local progress = ScriptManager:getMissionProgress( missionId );
		
		if progress <= 0 then
			Utils:setMissionStatus( missionId, MissionStatus.FAILED );
			missionFailed();
			
		else
			Utils:showMissionProgress( progress, counterText );
		end
	end
end

function prepareSupplyMissionProgress()
	table.insert( queueTable, showSupplyMissionProgress );
	Utils:cutsceneQueue();
end

function showSupplyMissionProgress()
	showEscortMissionProgress( trucksSaved, missionIds.escortSupply, Text.T_CAMP_L5_1_PRIMARY2_COUNTER1 );
end

function prepareEngiMissionProgress()
	table.insert( queueTable, showEngiMissionProgress );
	Utils:cutsceneQueue();
end

function showEngiMissionProgress()
	showEscortMissionProgress( engisSaved, missionIds.escortEngi, Text.T_CAMP_L5_1_PRIMARY1_COUNTER1 );
end

function customCounter( saveName, counter, unitId, missionId, textKey )
	counter = counter + 1;
	ScriptManager:storeValue( saveName, counter );
	ScriptManager:setMissionXp( missionId, 50 * counter ); -- simulate partial mission xp by giving increasing xp value to mission as it progresses
	
	ScriptManager:removeUnitEx( unitId, true );
	
	if counter >= ScriptManager:getMissionProgress( missionId ) then
		Utils:setMissionStatus( missionId, MissionStatus.ACCOMPLISHED );
		checkForVictory();
	
	else
		Utils:showMissionProgressTwoVar( counter, ScriptManager:getMissionProgress( missionId ), textKey );
	end
	
	return counter;
end

function onAirfieldReached( tileX, tileY, playerId, templateId, unitId )
	if templateId == Units.L_TRUCK_SUPPLY then
		trucksSaved = customCounter( "trucksSaved", trucksSaved, unitId, missionIds.escortSupply, Text.T_CAMP_L5_1_PRIMARY2_COUNTER2 );
	
	elseif templateId == Units.L_TRUCK_TRANSPORT then
		for i = 1, #engiIds do
			if unitId == engiIds[i] then
				Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_PRIMARY1_FLAVOR1, 3 );
			end
			break;
		end
	
	elseif templateId == Units.L_INFANTRY_ENGINEER then
		engisSaved = customCounter( "engisSaved", engisSaved, unitId, missionIds.escortEngi, Text.T_CAMP_L5_1_PRIMARY1_COUNTER2 );
	end
end


-- END Escort Engi / Supply Trucks
-- BEGIN Airfield Stuff


function onAirfieldCaptured()
	ScriptManager:removeTrigger( "onAirfieldCaptured" );
	ScriptManager:removeTrigger( "spawnPlaneWave" )
	ScriptManager:removeTrigger( "waveSquadPlaneDestroyed" )
	ScriptManager:removeTrigger( "checkWaypoints" )
	
	spawnPlaneWaves = 0;
	ScriptManager:storeValue( "spawnPlaneWaves", spawnPlaneWaves );
	
	Utils:addOnEnterAreaTrigger( 5, 8, 1, 0, Units.L_INFANTRY_ENGINEER,	-1, true, "onAirfieldReached", "onAirfieldReached" );
	Utils:addOnEnterAreaTrigger( 5, 8, 1, 0, Units.L_TRUCK_TRANSPORT,	-1, true, "onAirfieldReached", "onAirfieldReached" );
	Utils:addOnEnterAreaTrigger( 5, 8, 1, 0, Units.L_TRUCK_SUPPLY,		-1, true, "onAirfieldReached", "onAirfieldReached" );
	
	Utils:setMissionStatus( missionIds.capAirfield, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_PRIMARY3_FLAVOR1, 6 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	local airfieldX = airfieldPos[1];
	local airfieldY = airfieldPos[2];
	
	for x = airfieldX - 1, airfieldX + 1, 2 do
		checkAirfieldTile( x, airfieldY );
	end
	
	local xDiff = airfieldY % 2;
	local x = airfieldX + xDiff
	checkAirfieldTile( x - 1, airfieldY + 1 );
	checkAirfieldTile( x, airfieldY + 1 );
	checkAirfieldTile( x - 1, airfieldY - 1 );
	checkAirfieldTile( x, airfieldY - 1 );
	
	Utils:enablePlayerInteraction();
end

function checkAirfieldTile( tileX, tileY )
	local unit = Unit:getUnitAt( tileX, tileY );
	if unit ~= nil then
		onAirfieldReached( tileX, tileY, 0, unit:getTemplateId(), unit:getId() )
	end
end


-- END Airfield Stuff
-- BEGIN Victory


function checkForVictory()
	local engiStatus		= ScriptManager:getMissionStatus( missionIds.escortEngi );
	local supplyStatus		= ScriptManager:getMissionStatus( missionIds.escortSupply );
	
	if engiStatus		== MissionStatus.ACCOMPLISHED and
	   supplyStatus		== MissionStatus.ACCOMPLISHED then
		startVictoryCutscene();
	end
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_1_VICTORY_FLAVOR2, 5 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	Utils:missionCheckerAccomplish( missionIds.escortEngi );
	Utils:missionCheckerAccomplish( missionIds.escortSupply );
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Victory
-- BEGIN Defeated


function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	local defenderTemplate = defender:getTemplateId();
	if defenderTemplate == Units.L_TRUCK_SUPPLY then
		Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_TRUCK_SUPPLY );
	
	elseif defenderTemplate == Units.L_BUILDING_AIRFIELD then
		Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_BUILDING_AIRFIELD );
	
	else
		-- check if one of the engis was hit
		for i = 1, #engiIds do
			if defender:getId() == engiIds[i] then
				-- check if engi is in transporter or not
				if defenderTemplate == Units.L_TRUCK_TRANSPORT then
					Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_TRUCK_TRANSPORT );
				
				else
					Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_INFANTRY_ENGINEER );
				end
				break;
			end
		end
	end
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
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