require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	destroyBridges		= 1,
	hijackGustav		= 2,
	evacGustav			= 3,
	remainUndetected 	= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.destroyBridges,	true,	Text.T_CAMP_L3_2_PRIMARY1,	100 },
	{ missionIds.hijackGustav,		true,	Text.T_CAMP_L3_2_PRIMARY2,	 50 },
	{ missionIds.evacGustav,		true,	Text.T_CAMP_L3_2_PRIMARY3,	 50 },
	{ missionIds.remainUndetected,	false,	Text.T_CAMP_L3_2_SECONDARY1, 50 },
};

enemySquadIds = {
	westernPatrol			= 1,
	easternPatrol			= 2,
	gustavGuards			= 3,
	gustav					= 4,
	reinforcements			= 5,
	gustavAttackers			= 6,
	gustavAttackers2		= 7,
	gustavReinforcements	= 8,
};

gustavId		=    9;
gustavX			=    7; -- pos he is at beginning
gustavY			=   19;
HQId			=    2;
westernBridgeId	=    3;
easternBridgeId	=    1;
gustavDefenders	=    4;
bridgeMaxHP 	= 1200; -- TODO: if hp change, change here!
evacCounter		= 0;

-- used for enemy sight range ( unitSpotted )
topSightBorder = { { 6, 23 }, { 7, 23 }, { 7, 21 }, { 8, 21 }, { 9, 20 }, };

-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	ScriptManager:gainGold( 0, 1000 );
	
	local gustav = Unit:getUnitById( gustavId );
	gustav:setAllowCounterAttack( false );
	gustav:setCanBeCaptured( false );
	
	local bridge = Unit:getUnitById( westernBridgeId );
	bridge:setCanBeCaptured( false );
	
	bridge = Unit:getUnitById( easternBridgeId );
	bridge:setCanBeCaptured( false );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "gustavAttacked",			 0 );
	ScriptManager:storeValue( "westernPatrol",			 0 );
	ScriptManager:storeValue( "easternPatrol",			 0 );
	ScriptManager:storeValue( "freeSquadId",			 7 );
	ScriptManager:storeValue( "reinforcementsRequested", 0 );
	ScriptManager:storeValue( "reinforcements",			 0 );
	ScriptManager:storeValue( "gustavDefenders",		gustavDefenders );
	ScriptManager:storeValue( "evacCounter",					evacCounter );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	 1, Units.X_ARTILLERY_GUSTAF, -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.X_ARTILLERY_GUSTAF, -1,	"stopAttackingHint",	"stopAttackingHint" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.X_ARTILLERY_GUSTAF,	-1,	"transitionToFail",		"transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(	 0, -1,							-1,	"checkForEnd",			"checkForEnd" );
	
	-- destroying both bridges accomplishes missionIds.destroyBridges
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_BRIDGE_RAIL, westernBridgeId, "bridgeDestroyedW", "bridgeDestroyedW" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_BRIDGE_RAIL, easternBridgeId, "bridgeDestroyedE", "bridgeDestroyedE" );
	
	-- capturing Schwerer Gustav accomplishes missionIds.hijackGustav
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1,							-1, "gustavGuardDestroyed",	"gustavGuardDestroyed" );
	ScriptManager:addOnUnitCapturedTrigger( -1, Units.X_ARTILLERY_GUSTAF,	-1, "gustavCaptured",		"gustavCaptured" );
	
	-- moving SchwererGustav to the east accomplishes missionIds.evacGustav if Schwerer Gustaf was already captured.
	ScriptManager:addOnEnterTileTrigger( 12, 19, 0, Units.X_ARTILLERY_GUSTAF, -1, true, "gustavEvacuated", "gustavEvacuated", false );
	
	-- Check if Gustav is ready to fire and if new patrol should be spawned
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	
	-- patrol gets removed when it reaches the map boarder
	ScriptManager:addOnEnterTileTrigger( 11, 2, 1, Units.X_INFANTRY_MG, -1, true, "easternPatrolReachedTarget", "easternPatrolReachedTarget" )
	ScriptManager:addOnEnterTileTrigger( 12, 2, 1, Units.X_INFANTRY_MG, -1, true, "easternPatrolReachedTarget", "easternPatrolReachedTarget" )
	ScriptManager:addOnEnterTileTrigger( 13, 2, 1, Units.X_INFANTRY_MG, -1, true, "easternPatrolReachedTarget", "easternPatrolReachedTarget" )
	
	ScriptManager:addOnEnterTileTrigger( 3, 2, 1, Units.X_TRUCK_MG, -1, true, "reinforcementReachedTarget", "reinforcementReachedTarget" );
	ScriptManager:addOnEnterTileTrigger( 4, 2, 1, Units.X_TRUCK_MG, -1, true, "reinforcementReachedTarget", "reinforcementReachedTarget" );
	ScriptManager:addOnEnterTileTrigger( 5, 2, 1, Units.X_TRUCK_MG, -1, true, "reinforcementReachedTarget", "reinforcementReachedTarget" );
	
	ScriptManager:addOnEnterTileTrigger( 3, 2, 1, Units.X_INFANTRY_MG, -1, true, "westernPatrolReachedTarget", "westernPatrolReachedTarget" );
	ScriptManager:addOnEnterTileTrigger( 4, 2, 1, Units.X_INFANTRY_MG, -1, true, "westernPatrolReachedTarget", "westernPatrolReachedTarget" );
	ScriptManager:addOnEnterTileTrigger( 5, 2, 1, Units.X_INFANTRY_MG, -1, true, "westernPatrolReachedTarget", "westernPatrolReachedTarget" );
	
	-- when a patrol is being killed a new one will be spawned in the next round
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_INFANTRY_MG, -1, "patrolDied", "partrolDied" );
		
	-- if an enemy MG truck gets destroyed, new reinforcements can be called
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_TRUCK_MG, -1, "reinforcementsGotDestroyed","reinforcementsGotDestroyed" );
	
	ScriptManager:addOnUnitHasAttackedTrigger( 0, -1, -1, "onPlayerHasAttacked", "onPlayerHasAttacked" );
	newSpottedTrigger();
end

function newSpottedTrigger()
	-- if a unit is spotted reinforcements will be spawned at the outpost or in the south east corner of the map.
	ScriptManager:addOnUnitSightedTrigger( 0, -1, -1, true, "patrolSpottedPlayer", "unitSpotted" );
	
	for y = 16, 21 do
		-- right border
		if y <= 20 then
			ScriptManager:addOnEnterTileTrigger( 10, y, 0, -1, -1, true, "unitSpotted", "unitSpotted" );
		end
		
		-- left border
		ScriptManager:addOnEnterTileTrigger( 4, y, 0, -1, -1, true, "unitSpotted", "unitSpotted" );
	end
	
	for x = 4, 9 do
		-- bottom border
		ScriptManager:addOnEnterTileTrigger( x, 15, 0, -1, -1, true, "unitSpotted", "unitSpotted" );
		
		-- top border
		if  x <= 7 then
			ScriptManager:addOnEnterTileTrigger( x, 22, 0, -1, -1, true, "unitSpotted", "unitSpotted" );
		end
	end
	
	-- top border
	for i = 1, #topSightBorder do
		ScriptManager:addOnEnterTileTrigger( topSightBorder[i][1], topSightBorder[i][2], 0, -1, -1, true, "unitSpotted", "unitSpotted" );
	end
end

function loadValues()
	gustavDefenders = ScriptManager:getValue( "gustavDefenders" );
	evacCounter		= ScriptManager:getValue( "evacCounter" );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx( 7, 19, 1, 3, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR2 );
	ScriptManager:revealFogOfWar(		7, 19, 1, true );
	ScriptManager:showScaledMarkerAt(	7, 19, 1.5, true, true );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR3 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( 7, 19, 0.5, 3, false );
	Utils:hideAllMarkers();
	
	ScriptManager:revealFogOfWar( 7, 19, 1, false );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR4 );
	
	ScriptManager:revealFogOfWar(  3, 19, 1,true );
	ScriptManager:revealFogOfWar( 11, 19, 1,true );
	
	ScriptManager:showScaledMarkerAt(  3, 19, 1.5, true, true );
	ScriptManager:showScaledMarkerAt( 11, 19, 1.5, true, true );
	ScriptManager:wait( 5 )
	
	ScriptManager:moveCameraEx( 2, 2, 0.7, 5, false );
	Utils:hideAllMarkers();
	
	ScriptManager:revealFogOfWar(  3, 19, 1, false );
	ScriptManager:revealFogOfWar( 11, 19, 1, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR5 );
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_SNIPER, 0,7, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId = transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 3, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 3, 2, true );
	ScriptManager:moveUnitEx( 	unitId, 4, 0, true );
	ScriptManager:removeUnitEx( unitId, true );
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_MORTAR, 0, 5, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId = transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 2, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 3, 1, true );
	ScriptManager:moveUnitEx(	unitId, 3, 0, true );
	ScriptManager:removeUnitEx( unitId, true );
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_ENGINEER, 0, 7, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId	= transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 3, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 2, 1, true );
	ScriptManager:moveUnitEx(	unitId, 4, 0, true );
	ScriptManager:removeUnitEx( unitId, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_INTRO_FLAVOR6 );
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_MORTAR, 0, 5, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId	= transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 2, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 2, 2, true );
	ScriptManager:moveUnitEx(	unitId, 3, 0, true );
	ScriptManager:removeUnitEx( unitId, true );
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_SNIPER, 0, 3, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId	= transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 1, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 1, 2, true );
	ScriptManager:moveUnitEx(	unitId, 2, 0, true );
	ScriptManager:removeUnitEx(	unitId, true);
	
	local unit				= ScriptManager:spawnUnitWithTransporter( 0, Units.L_PLANE_TRANSPORT, Units.L_INFANTRY_ENGINEER, 0, 5, -1 );
	local unitId			= unit:getId();
	local transportedUnit	= unit:getLoadedUnitAt( 0 );
	local transportedUnitId = transportedUnit:getId();
	
	ScriptManager:moveUnitEx( unitId, 2, 1, true );
	ScriptManager:unloadUnitFromTransporterEx( unitId, transportedUnitId, 1, 1, true );
	ScriptManager:moveUnitEx(	unitId, 3, 0, true );
	ScriptManager:removeUnitEx(	unitId, true);
	Utils:hideDialogue();
	
	
	ScriptManager:displaySubtitle( Text.T_SUBTITLE_INTRO_END_1 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();

	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.destroyBridges,	 MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.remainUndetected, MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.destroyBridges,	0, 2 );
	Utils:setMissionProgress( missionIds.hijackGustav, 0, gustavDefenders );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		4, 18, 42 );
	--ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		10, 19, 42 );
	--ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		9, 19, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER,	12, 19, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER,	7, 13, 42 );
	--ScriptManager:removeUnitEx( 8, true );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Game Stuff


function bridgeDestroyedW( bridge )
	ScriptManager:removeTrigger( "bridgeDestroyedW" );
	bridgeDestroyed( bridge )
end

function bridgeDestroyedE( bridge )
	ScriptManager:removeTrigger( "bridgeDestroyedE" );
	bridgeDestroyed( bridge )
end

function bridgeDestroyed( bridge )
	ScriptManager:storeValue( "bridgeX",	bridge:getX() );
	ScriptManager:storeValue( "bridgeY",	bridge:getY() );
	ScriptManager:storeValue( "bridgeId",	bridge:getId() );
	
	--print( "destroyed bridges:" );
	--print( ScriptManager:getMissionProgress( missionIds.destroyBridges ) );
	
	Utils:incrementMissionProgress( missionIds.destroyBridges );
	ckeckMissionProgress();
end

function ckeckMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyBridges ) == MissionStatus.IN_PROGRESS then
		table.insert( queueTable, bridgeDestroyedCutscene );
		Utils:cutsceneQueue();
		
	else
		Utils:setMissionStatus( missionIds.destroyBridges, MissionStatus.ACCOMPLISHED )
		
		if ScriptManager:getMissionStatus( missionIds.remainUndetected ) ~= MissionStatus.FAILED then
			Utils:setMissionStatus( missionIds.remainUndetected, MissionStatus.ACCOMPLISHED );
		end 
		
		table.insert( queueTable, bridgesDestroyedCutscene );
		Utils:cutsceneQueue();
	end
end

function bridgeDestroyedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY1_FLAVOR1 );
	
	local targetX, targetY, returnX, returnY;
	if ScriptManager:getValue( "bridgeId" ) == westernBridgeId then
		targetX = 10;
		targetY = 19;
		returnX =  3;
		returnY = 19;
		
	else
		targetX =  3;
		targetY = 19;
		returnX = 10;
		returnY = 19;
	end
	
	ScriptManager:moveCameraEx( 7, 18, 0.5, 3, true );
	
	ScriptManager:moveCameraEx(			targetX, targetY, 0.7, 3, true );
	ScriptManager:revealFogOfWar(		targetX, targetY, 1, true );
	ScriptManager:showScaledMarkerAt(	targetX, targetY, 1.5, true, true );
	ScriptManager:wait( 3 );
	
	Utils:hideAllMarkers();
	
	ScriptManager:revealFogOfWar( targetX, targetY, 1, false );
	
	ScriptManager:moveCameraEx(  7, 18, 0.5, 3, true );
	ScriptManager:moveCameraEx( returnX, returnY, 0.7, 3, true );
	
	Utils:hideDialogue();
	Utils:endCutscene();
end

function bridgesDestroyedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY1_FLAVOR2 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	local gustav = Unit:getUnitById( gustavId );
	ScriptManager:moveCameraEx(			gustav:getX(), gustav:getY(), 1, 1,	false );
	ScriptManager:revealFogOfWar(		gustav:getX(), gustav:getY(), 1,	true );
	ScriptManager:showScaledMarkerAt(	gustav:getX(), gustav:getY(), 1.5,	true, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY1_FLAVOR3 );
	ScriptManager:wait( 3 );
	
	ScriptManager:hideMarkerAt(		gustav:getX(), gustav:getY() );
	ScriptManager:revealFogOfWar(	gustav:getX(), gustav:getY(), 1, false );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "bridgeX" ), ScriptManager:getValue( "bridgeY" ), 0.7, 1, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.hijackGustav, MissionStatus.IN_PROGRESS );
	
	ScriptManager:gainGold( 0, 500 );
end

function onPlayerHasAttacked( attackerUnit, isAoe, defenderUnit, defenderUnits, unitsHit )
	local defenderTemplate = defenderUnit:getTemplateId()
	
	if defenderTemplate ~= nil then
		if ScriptManager:getMissionStatus( missionIds.destroyBridges ) ~= MissionStatus.ACCOMPLISHED then
			if defenderTemplate == Units.X_ARTILLERY_GUSTAF then
				evacCounter = evacCounter + 1;
				ScriptManager:storeValue( "evacCounter", evacCounter );
				
				-- if gustav is attacked twice or two guards are already destroyed, he will escape
				if evacCounter >= 2 or ScriptManager:getMissionProgress( missionIds.hijackGustav ) >= 2 then
					ScriptManager:removeTrigger( "stopAttackingHint" );
					ScriptManager:runForPlayer( 0, "prepareGustavEscaping" );
				end
			end
			
			if defenderUnit:getSquadId() == enemySquadIds.gustavGuards then
				-- if two guards are already destroyed, escape on next player attack
				if ScriptManager:getMissionProgress( missionIds.hijackGustav ) >= 2 then
					ScriptManager:removeTrigger( "stopAttackingHint" );
					ScriptManager:runForPlayer( 0, "prepareGustavEscaping" );
				end
			end
		end
	end
end

function gustavGuardDestroyed( unit )
	local squadId = unit:getSquadId();
	if squadId == enemySquadIds.gustavGuards or squadId == enemySquadIds.gustavReinforcements then
		Utils:incrementMissionProgress( missionIds.hijackGustav );
		
		ScriptManager:runForPlayer( 0, "prepareGustavProgress" );
	end
end

function prepareGustavProgress()
	table.insert( queueTable, showGustavProgress );
	Utils:cutsceneQueue();
end

function showGustavProgress()
	-- if bridges are not destroyed, gustav will escape after 2 units are destroyed
	if ScriptManager:getMissionStatus( missionIds.destroyBridges ) ~= MissionStatus.ACCOMPLISHED then
		if ScriptManager:getMissionProgress( missionIds.hijackGustav ) >= 2 then
			--ScriptManager:runForPlayer( 0, "prepareGustavEscaping" );
			gustavEscapes();
		end
	
	else
		if ScriptManager:getMissionProgress( missionIds.hijackGustav ) >= gustavDefenders then
			ScriptManager:removeTrigger( "gustavGuardDestroyed" );
			
			local gustav = Unit:getUnitById( gustavId );
			gustav:setCanBeCaptured( true );
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L3_2_PRIMARY2_FLAVOR4, 3 );
		
		else
			Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress( missionIds.hijackGustav ), gustavDefenders, Text.T_CAMP_L3_2_PRIMARY2_COUNTER );
		end
	end
end

function prepareGustavEscaping()
	table.insert( queueTable, gustavEscapes );
	Utils:cutsceneQueue();
end

function gustavEscapes()
	-- possible to destroy units and the second bridge and that triggers fleeing, so to avoid it i check again bevor that happens
	if ScriptManager:getMissionStatus( missionIds.destroyBridges ) ~= MissionStatus.ACCOMPLISHED then
		-- preferred escape path: west
		local bridge = Unit:getUnitById( westernBridgeId );
		local escapeX, direction, lengthAdjust; -- adjust for not searching directly on gustav tile but 2 tiles in front / behind him depending on escape path
		
		if bridge:getPlayerId() == 1 then
			escapeX = 0;
			direction = -1;
		else
			escapeX = 14;
			direction = 1;
		end
		
		Utils:startCutscene();
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_VICTORY_FLAVOR1 );
		
		calculateEscapeRoute( gustavX, escapeX, direction );
	end
end

function calculateEscapeRoute( gustavX, escapeX, direction )
	local unitFound = false;
	
	for i = gustavX + ( direction * 2 ), escapeX, direction do
		local unit = Unit:getUnitAt( i, gustavY );
		
		-- blocking unit was found!
		if unit ~= nil then
			unitFound = true;
			
			-- move gustav if the found unit is not directly in front of it
			if i ~= gustavX + ( direction * 2 ) then
				local moveX = i - ( direction * 2 );
				ScriptManager:moveCameraEx(			moveX, gustavY, 0.7, 1, false );
				ScriptManager:moveUnitEx( gustavId, moveX, gustavY,			true );
			end
			
			-- remove the blocking unit and save current gustav pos for next search
			ScriptManager:removeUnitEx( unit:getId(), true );
		end
	end
	
	-- all obstacles in front of gustav are gone move the final bit towards the escape
	ScriptManager:moveCameraEx(			escapeX, gustavY, 0.7, 2,	false );
	ScriptManager:moveUnitEx( gustavId, escapeX, gustavY,			true );
	
	ScriptManager:removeUnitEx( gustavId, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	missionFailed();
end

function gustavCaptured()
	ScriptManager:removeTrigger( "gustavCaptured" );
	ScriptManager:removeTrigger( "onPlayerHasAttacked" );
	
	Utils:setMissionStatus( missionIds.hijackGustav, MissionStatus.ACCOMPLISHED );
	ScriptManager:gainGold( 0, 500 );
	
	table.insert( queueTable, gustavCapturedCutscene );
	Utils:cutsceneQueue();
end

function gustavCapturedCutscene()
	Utils:startCutscene();
	
	-- display text depending on current east bridge status
	local bridge = Unit:getUnitById( easternBridgeId );
	local bridgePlayer = bridge:getPlayerId();
	
	if bridgePlayer == 0 then
		ScriptManager:displaySubtitle( Text.T_SUBTITLE_PRAISE_1 );
	
	else
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY2_FLAVOR1 );
	end
	
	ScriptManager:moveCameraEx(		11, 19, 0.7, 3, true );
	ScriptManager:revealFogOfWar(	11, 19, 1, true );
	ScriptManager:wait( 1 );
	Utils:hideDialogue();
	
	if bridgePlayer == 0 then
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY2_FLAVOR5 );
	
	else
		ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY2_FLAVOR2 );
	end
	ScriptManager:wait( 3 );
	
	ScriptManager:showMarkerAt( 13, 19 );
	ScriptManager:wait( 3 );
	ScriptManager:hideMarkerAt( 13, 19 );
	ScriptManager:moveCameraEx(  7, 19, 0.7, 3, false );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_PRIMARY2_FLAVOR3 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.evacGustav, MissionStatus.IN_PROGRESS );
	
	local gustav = Unit:getUnitById( gustavId );
	gustav:setAllowCounterAttack( false );
	
	-- trigger for gustav to only shoot every second turn
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.X_ARTILLERY_GUSTAF, -1, "gustafAttacked",	"gustafAttacked" );
	ScriptManager:addOnTurnStartTrigger(		0, -1,						 -1, "reloadGustav",	"reloadGustav" );
end

function gustafAttacked()
	ScriptManager:storeValue( "gustavAttacked", 1 );
end

function reloadGustav()
	local gustav = Unit:getUnitById( gustavId );
	
	if ScriptManager:getValue( "gustavAttacked" ) == 1 then 
		gustav:setAttacksPerTurn( 0 );
		ScriptManager:storeValue( "gustavAttacked", 0 );
	
	else
		gustav:setAttacksPerTurn( 1 );
	end
end

function gustavEvacuated( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	ScriptManager:setMissionStatus( missionIds.evacGustav, MissionStatus.ACCOMPLISHED );
	startVictoryCutscene();
end

function onEnemyTurnStart( playerId, turnId, roundId )
	local gustav = Unit:getUnitById( gustavId );
	gustav:setAttacksPerTurn( 0 );
	local orderId;
	if ScriptManager:getMissionStatus( missionIds.remainUndetected ) ~= MissionStatus.FAILED then -- stop spawning patrol if already found
		
		if ScriptManager:getValue( "westernPatrol" ) == 0 then
			ScriptManager:spawnUnit( 1, Units.X_INFANTRY_MG, 1, 16, enemySquadIds.westernPatrol );
			
			orderId = ScriptManager:addOrder( enemySquadIds.westernPatrol, 2, 11, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag(orderId,AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.westernPatrol, 4, 8, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag(orderId,AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.westernPatrol, 6, 6, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.westernPatrol, 4, 1, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag(orderId,AiOrderFlag.FLAG_HOLD_FIRE);
			
			ScriptManager:storeValue( "westernPatrol", -1 );
			
		else
			ScriptManager:storeValue( "westernPatrol", ScriptManager:getValue( "westernPatrol" ) - 1 );	
		end
		
		if ScriptManager:getValue( "easternPatrol" ) == 0 then
			ScriptManager:spawnUnit( 1, Units.X_INFANTRY_MG, 13, 15, enemySquadIds.easternPatrol );
			
			orderId = ScriptManager:addOrder( enemySquadIds.easternPatrol, 12, 10, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.easternPatrol, 9, 7, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.easternPatrol, 10, 3, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
			
			orderId = ScriptManager:addOrder( enemySquadIds.easternPatrol, 12, 1, -1, 1, AiOrder.MOVE );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
			
			ScriptManager:storeValue( "easternPatrol", -1 )
		
		else
			ScriptManager:storeValue( "easternPatrol", ScriptManager:getValue( "easternPatrol" ) - 1 );
		end
	end
	
	if ScriptManager:getValue("reinforcementsRequested") == 1 then
		ScriptManager:spawnUnit( 1, Units.X_TRUCK_MG, 4, 1, enemySquadIds.reinforcements );
		
		ScriptManager:storeValue( "reinforcements",			 1 );
		ScriptManager:storeValue( "reinforcementsRequested", 0 );
		ScriptManager:storeValue( "freeSquadId",			 ScriptManager:getValue( "freeSquadId" ) + 1 );
		
		ScriptManager:addOrder( enemySquadIds.reinforcements, -1, -1, ScriptManager:getValue( "spottedUnitId" ), 1, AiOrder.ATTACK );
		
		orderId = ScriptManager:addOrder( enemySquadIds.reinforcements, 12, 1, -1, 1, AiOrder.MOVE );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
	end
	
	if ScriptManager:getMissionStatus( missionIds.hijackGustav ) == MissionStatus.ACCOMPLISHED then
		local rng = math.random ( 1, 2 );
		local infantry, tank;
		
		if rng == 1 then
			infantry = Units.X_INFANTRY_MG;
			tank	 = Units.X_TANK_HEAVY;
		
		else
			infantry = Units.X_INFANTRY_AT;
			tank	 = Units.X_TANK_MEDIUM;
		end
		
		ScriptManager:spawnUnit( 1, infantry, 6, 23, enemySquadIds.gustavAttackers );
		
		-- spawn a tank every second round, otherwise the map will be flooded with tanks
		if roundId % 2 == 1 then
			ScriptManager:spawnUnit( 1, tank, 4,  1, enemySquadIds.gustavAttackers2 );
		end
		
		if ScriptManager:getSquadOrderCount( enemySquadIds.gustavAttackers ) == 0 then
			orderId = ScriptManager:addOrder( enemySquadIds.gustavAttackers, -1, -1, gustavId, 2, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag(	orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
		
		if ScriptManager:getSquadOrderCount( enemySquadIds.gustavAttackers2 ) == 0 then
			orderId = ScriptManager:addOrder( enemySquadIds.gustavAttackers2, 12, 19, -1, 3, AiOrder.DEFEND );
			ScriptManager:enableOrderFlag(	orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		end
	end
end

function easternPatrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	patrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, "easternPatrol" )
end

function reinforcementReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	patrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, "reinforcements" )
end

function westernPatrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, hasSmoke )
	patrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, "westernPatrol" )
end

function patrolReachedTarget( tileX, tileY, playerId, unitTemplateId, unitId, saveValue )
	local unit = Unit:getUnitById( unitId );
	local squadId = unit:getSquadId();
	if unitTemplateId == Units.X_TRUCK_MG or squadId == enemySquadIds.westernPatrol or squadId == enemySquadIds.easternPatrol then
		ScriptManager:moveUnitEx( unitId, tileX, 0, true );
		ScriptManager:storeValue( saveValue, 2 );
		ScriptManager:removeUnitEx( unitId, true );
	end
end

function patrolDied( unit )
	if unit:getSquadId() == enemySquadIds.easternPatrol then
		ScriptManager:storeValue( "easternPatrol", 2 );
	
	elseif unit:getSquadId() == enemySquadIds.westernPatrol then
		ScriptManager:storeValue( "westernPatrol", 2 );
	end
end

function patrolSpottedPlayer( patrolUnit, playerUnit )
	-- spotted function for the two patrolling units
	local discoveringSquadId = patrolUnit:getSquadId();
	if discoveringSquadId == enemySquadIds.easternPatrol or discoveringSquadId == enemySquadIds.westernPatrol then
		spottedFunction( playerUnit:getId() );
	end
end

function unitSpotted( tileX, tileY, playerId, templateId, unitId )
	-- spotted function for the units on the centre island
	spottedFunction( unitId );
end

function spottedFunction( spottedUnitId )
	ScriptManager:storeValue( "spottedUnitId", spottedUnitId );
	ScriptManager:removeTrigger( "unitSpotted" );
	ScriptManager:runForPlayer( 0, "newSpottedTrigger" );
	ScriptManager:removeTrigger( "unitSpotted" );
	
	local targetId = spottedUnitId;
	patrolAttackOrder( enemySquadIds.westernPatrol, targetId,  4 );
	patrolAttackOrder( enemySquadIds.easternPatrol, targetId, 12 );
	
	if ScriptManager:getMissionStatus(missionIds.remainUndetected) == MissionStatus.IN_PROGRESS then
		ScriptManager:setMissionStatus( missionIds.remainUndetected, MissionStatus.FAILED );
		ScriptManager:runForPlayer( 0, "prepareUnitspottedCutscene" );
		
		-- additional gustav defenders
		ScriptManager:spawnUnit( 1, Units.X_TANK_MEDIUM, 6, 23, enemySquadIds.gustavReinforcements );
		ScriptManager:spawnUnit( 1, Units.X_INFANTRY_AT, 5, 23, enemySquadIds.gustavReinforcements );
		
		gustavDefenders = gustavDefenders + 2;
		ScriptManager:storeValue( "gustavDefenders", gustavDefenders );
		ScriptManager:setMaxMissionProgress( missionIds.hijackGustav, gustavDefenders );
		
		ScriptManager:addOrder( enemySquadIds.gustavGuards,			7, 19, -1, 2, AiOrder.DEFEND );
		ScriptManager:addOrder( enemySquadIds.gustavReinforcements, 7, 19, -1, 3, AiOrder.DEFEND );
		
		local outpost = Unit:getUnitById( HQId )
		if outpost:getPlayerId() == 1 and ScriptManager:getValue( "reinforcements" ) == 0 then
			ScriptManager:spawnUnit( 1, Units.X_TRUCK_MG, 10, 6, enemySquadIds.reinforcements );
			ScriptManager:storeValue( "reinforcements", 1 );
			
			--TODO: let it patrol too? do something with it!
			patrolAttackOrder( enemySquadIds.reinforcements, targetId, 12 );
		
		elseif ScriptManager:getValue( "reinforcements" ) == 0 then
			ScriptManager:storeValue( "reinforcementsRequested", 1 );
		end
	end
end

function patrolAttackOrder( squadId, targetId, afterMoveX )
	ScriptManager:removeAllOrders( squadId );
	
	local orderId = ScriptManager:addOrder( squadId, -1, -1, targetId, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	
	orderId = ScriptManager:addOrder( squadId, afterMoveX, 1, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
end

function prepareUnitspottedCutscene()
	table.insert( queueTable, unitSpottedCutscene );
	Utils:cutsceneQueue();
end

function unitSpottedCutscene()
	local spottedUnit = Unit:getUnitById( ScriptManager:getValue( "spottedUnitId" ) );
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_SECONDARY1_FLAVOR1 );
		
	if spottedUnit ~= nil then
		ScriptManager:moveCameraEx( spottedUnit:getX(), spottedUnit:getY(), 0.7, 1, true );
	
	else
		Utils:antiRush();
	end
	
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_SECONDARY1_FLAVOR2 );
	ScriptManager:moveCameraEx( 11, 6, 0.7, 3, true );
	Utils:markUnit( 11, 6, 1, 2, 0 );
	
	if spottedUnit ~= nil then
		ScriptManager:moveCameraEx( spottedUnit:getX(), spottedUnit:getY(), 0.7, 3, true );
	
	else
		ScriptManager:wait( 3 );
	end
	
	Utils:hideDialogue();
	Utils:endCutscene();
end

function reinforcementsGotDestroyed()
	ScriptManager:storeValue( "reinforcements", 0 );
end


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_VICTORY_FLAVOR1 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_2_VICTORY_FLAVOR2 );
	ScriptManager:wait( 4 );
	ScriptManager:moveUnitEx(	gustavId, 14, 19, true );
	ScriptManager:removeUnitEx(	gustavId, true );
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


function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_ARTILLERY_GUSTAF );
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_ARTILLERY_GUSTAF );
end

function checkForEnd()
	if ScriptManager:noUnitsLeftExt( { 0, Units.N_MINE_LAND, Units.L_PLANE_SCOUT, Units.N_EMPLACEMENT_WIRE, Units.N_EMPLACEMENT_METAL } ) then
		ScriptManager:runForPlayer( 0, "missionFailed" );
	end
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