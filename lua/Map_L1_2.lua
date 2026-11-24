require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	clearBeach	= 1,
	breakOneBarricade = 2,
	captureAirfield = 4,
	RecaptureSupplies = 5,
	breakTwoBarricades = 3,
};


-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.clearBeach,	true,	Text.T_CAMP_L1_2_PRIMARY1,	100 },
	{ missionIds.breakOneBarricade,	true,	Text.T_CAMP_L1_2_PRIMARY2,	 50 },
	{ missionIds.captureAirfield,	true,	Text.T_MISSION_CAP_DESTROY_AIRFIELD,	 75 },
	{ missionIds.RecaptureSupplies,	false,	Text.T_CAMP_L1_2_SECONDARY1,	 50 },
	{ missionIds.breakTwoBarricades,	false,	Text.T_CAMP_L1_2_SECONDARY2,	 50 },

};

enemySquadIds = {

defendersLeft = 1,
defendersMiddle = 2,
defendersRight = 3,
defendersRightUp = 4,

defendersAirfield = 5,

defendersDepot = 6,

defendersLeftBreach = 7,
defendersRightBreach = 8,

mgNestLeft = 9,

mgNestRight = 10,

barricadesLeft = 15,
barricadesRight = 16,

planewave = 17,
bomber = 18,

mines = 19,

tankAtCrossingSupplies = 20,


-- bunkers on coast from left to right
bunker1 = 21,
bunker2 = 22,
bunker3 = 23,
bunker4 = 24,
bunker5 = 25,
bunker6 = 26,
bunker7 = 27,
bunker8 = 28,

-- bunkers on beach from left to right
bunker9 = 29,
bunker10 = 30,
bunker11 = 31,
bunker12 = 32,
bunker13 = 33,
bunker14 = 34,
bunker15 = 35,
bunker16 = 36,

defenseSquad = 37,


AA1 = 40,
AA2 = 41,
AA3 = 42,
AA4 = 43,
AA5 = 44,
AA6 = 45,
AA7 = 46,
AA8 = 47,


artilleryRightBreach = 50,
};


defenseSquad = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.X_TANK_HEAVY, 4, 37, enemySquadIds.defenseSquad };
	{ 1, Units.X_INFANTRY_MG, 5, 36, enemySquadIds.defenseSquad };
	{ 1, Units.X_INFANTRY_AT, 6, 36, enemySquadIds.defenseSquad };
};


planeWaveRespawnInterval = 2; -- defines how often waves will spawn
spawnPlaneWaves = 0;

planeWaveUnits1 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_LIGHT, 22, 39, enemySquadIds.planewave };
};

planeWaveUnits2 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_HEAVY, 22, 39, enemySquadIds.planewave };
};

planeWaveUnits3 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_BOMBER, 22, 39, enemySquadIds.bomber };
};

 waypointTablePlane = { { 18, 29 }, { 6, 27 }, { 3, 21 }, { 12, 18 }, { 20, 14 }, { 12, 5 }  };
 

enemyAirfield = 13;

enemyHQId = 98;

artilleryBeachLeft = 73;
artilleryBeachRight = 72;

playerAC = 63;
playerBalloonOne = 128;
playerBalloonTwo = 129;
playerBalloonThree = 133;
playerBalloonFour = 134;
playerBalloonFive = 135;


defendersToKill = 10;
sixDefendersKilled = 6;
eightDefendersKilled = 8;

suppliesToRecapture = 2;
barricadesToDestroyLeft = 3;
barricadesToDestroyRight = 3;

BarricadesLeftIds = { 60, 5, 2  };
BarricadesRightIds = { 51, 87, 8 };

barricadesLeftTotal = #BarricadesLeftIds;
barricadesRightTotal = #BarricadesRightIds; 

leftBarricades = 3;
rightBarricades = 3;


barricade1 = 60; 	-- metal
barricade2 = 5;		-- wire
barricade3 = 2;		-- metal
barricade4 = 51;	-- metal
barricade5 = 87;	-- metal
barricade6 = 8;		-- wire



-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 7, 4, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 4, 3, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MORTAR, 18, 3, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_AT, 13, 5, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TRUCK_SUPPLY, 11, 6, -1) 
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 22, 2, -1)
	ScriptManager:spawnUnit( 0, Units.L_PLANE_LIGHT, 10, 3, -1 );	
	ScriptManager:spawnUnit( 0, Units.L_PLANE_HEAVY, 11, 3, -1 );	
	
	ScriptManager:fortifyUnit( 131, true );
	ScriptManager:fortifyUnit( 72, true );
	ScriptManager:fortifyUnit( 73, true );
	
	Unit:getUnitById( playerBalloonOne ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonOne ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonOne ):setIsAttackable(false);
	
	Unit:getUnitById( playerBalloonTwo ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonTwo ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonTwo ):setIsAttackable(false);
	
	Unit:getUnitById( playerBalloonThree ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonThree ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonThree ):setIsAttackable(false);
	
	Unit:getUnitById( playerBalloonFour ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFour ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFour ):setIsAttackable(false);
	
	Unit:getUnitById( playerBalloonFive ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFive ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFive ):setIsAttackable(false);
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	
	leftBarricades = ScriptManager:storeValue( "leftBarricades",leftBarricades );
	rightBarricades = ScriptManager:storeValue( "rightBarricades", rightBarricades );
	
	barricadesLeftTotal = ScriptManager:storeValue( "barricadesLeftTotal", barricadesLeftTotal );
	barricadesRightTotal = ScriptManager:storeValue( "barricadesRightTotal", barricadesRightTotal );
	
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, playerAC , -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, playerAC , -1,	"transitionToFail",		"transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, -1,				 -1, "checkForEnd",			"checkForEnd" );

	-- when the beach defenders are defeated
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onDefenderKilled", "onDefenderKilled" );
	
	-- when the supply crates are recaptured
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BUILDING_CRATES, -1, "onCratesRecaptured", "onCratesRecaptured" );
	
	-- when the enemy airfield gets spotted
	ScriptManager:addOnUnitSightedTrigger( 1, Units.X_BUILDING_AIRFIELD, enemyAirfield, true, "playAirfieldCutscene", "playAirfieldCutscene" );
	
	-- when one of the barriers of the breaches get spotted
	ScriptManager:addOnUnitSightedTrigger( 1, Units.N_EMPLACEMENT_METAL, -1, true, "onBreachBarricadeSighted", "onBreachBarricadeSighted" );
	ScriptManager:addOnUnitSightedTrigger( 1, Units.N_EMPLACEMENT_WIRE, -1, true, "onBreachBarricadeSighted", "onBreachBarricadeSighted" );

--[[
barricade1 = 60; -- metal
barricade2 = 5;	-- wire
barricade3 = 2; -- metal
barricade4 = 51; -- metal
barricade5 = 87; -- metal
barricade6 = 8; -- wire
]]
	
	-- when the airfield gets captured or destroyed
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldCapturedDestroyed", "onAirfieldCapturedDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_AIRFIELD, -1, "onAirfieldCapturedDestroyed", "onAirfieldCapturedDestroyed" );
		
	-- trigger for wavespawn
	ScriptManager:addOnTurnStartTrigger( 1, -1, 2, "spawnPlaneWave", "spawnPlaneWave" );
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planewave,  "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.bomber, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	
	-- when one of the last barricades in one of the breaches is destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, 51, "onLastBarrierDestroyed", "onLastBarrierDestroyed" ); -- right Barricade
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, 60, "onLastBarrierDestroyed", "onLastBarrierDestroyed" ); -- left Barricade
	
	-- reduces the action points of the beach artilleries
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "reduceAAactionPoints", "reduceAAactionPoints" );
	
	ScriptManager:addOnGameResumeTrigger( "setBalloonTurns", "setBalloonTurns" );
	
end


function loadValues()
	
	local balloon1 = Unit:getUnitById( playerBalloonOne );
	if balloon1 ~= nil then
	balloon1:setMaxPlaneTurns( -1 );
	balloon1:setPlaneTurns( -1 );
	balloon1:setIsAttackable(false);
	end
	
	local balloon2 = Unit:getUnitById( playerBalloonTwo );
	if balloon2 ~= nil then
	balloon2:setMaxPlaneTurns( -1 );
	balloon2:setPlaneTurns( -1 );	
	balloon2:setIsAttackable(false);
	end

	local balloon3 = Unit:getUnitById( playerBalloonThree );
	if balloon3 ~= nil then
	balloon3:setMaxPlaneTurns( -1 );
	balloon3:setPlaneTurns( -1 );	
	balloon3:setIsAttackable(false);
	end
	
	local balloon4 = Unit:getUnitById( playerBalloonFour );
	if balloon4 ~= nil then
	balloon4:setMaxPlaneTurns( -1 );
	balloon4:setPlaneTurns( -1 );	
	balloon4:setIsAttackable(false);
	end
	
	local balloon5 = Unit:getUnitById( playerBalloonFive );
	if balloon5 ~= nil then
	balloon5:setMaxPlaneTurns( -1 );
	balloon5:setPlaneTurns( -1 );	
	balloon5:setIsAttackable(false);
	end



	leftBarricades = ScriptManager:getValue( "leftBarricades" );
	print( string.format( "leftBarricades: %i", leftBarricades ) );
	
	rightBarricades = ScriptManager:getValue( "rightBarricades" );
	print( string.format( "rightBarricades: %i", rightBarricades ) );

	
	barricadesLeftTotal  = ScriptManager:getValue( "barricadesLeftTotal" );
	barricadesRightTotal = ScriptManager:getValue( "barricadesRightTotal" );

	BarricadesLeftIds = Utils:loadValuesFromSavefileIntoExistingTable( "BarricadesLeftIds", BarricadesLeftIds );
	BarricadesRightIds = Utils:loadValuesFromSavefileIntoExistingTable( "BarricadesRightIds", BarricadesRightIds );

end


function addAiOrders()

	ScriptManager:addOrder( enemySquadIds.defendersLeft, 3, 23, -1, 4, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.defendersMiddle, 10, 25, -1, 4, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.defendersRight, 18, 23, -1, 4, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.defendersRightUp, 23, 27, -1, 4, AiOrder.DEFEND );

	ScriptManager:addOrder( enemySquadIds.defendersAirfield, 22, 38, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.defendersDepot, 6, 38, -1, 2, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.defendersLeftBreach, 7, 31, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.defendersRightBreach, 17, 33, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.mgNestLeft, 3, 26, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNestRight, 21, 26, -1, 3, AiOrder.DEFEND );

	ScriptManager:addOrder(enemySquadIds.tankAtCrossingSupplies, 10, 37, -1, 3, AiOrder.DEFEND );

	ScriptManager:addOrder( enemySquadIds.artilleryRightBreach, 17, 35, -1, 5, AiOrder.DEFEND );

-- from left to right
	ScriptManager:addOrder( enemySquadIds.AA1, 4, 17, -1, 4, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.AA2, 3, 29, -1, 4, AiOrder.DEFEND );	
	ScriptManager:addOrder( enemySquadIds.AA3, 7, 35, -1, 4, AiOrder.DEFEND );		
	ScriptManager:addOrder( enemySquadIds.AA4, 11, 25, -1, 4, AiOrder.DEFEND );		
	ScriptManager:addOrder( enemySquadIds.AA5, 16, 33, -1, 4, AiOrder.DEFEND );	
	ScriptManager:addOrder( enemySquadIds.AA6, 19, 17, -1, 4, AiOrder.DEFEND );	
	ScriptManager:addOrder( enemySquadIds.AA7, 21, 38, -1, 4, AiOrder.DEFEND );	
	ScriptManager:addOrder( enemySquadIds.AA8, 24, 38, -1, 4, AiOrder.DEFEND );	
	

	-- bunkers on the coast from left to right
	ScriptManager:addOrder( enemySquadIds.bunker1, 4, 29, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker2, 8, 29, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker3, 10, 31, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker4, 13, 29, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker5, 16, 28, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker6, 16, 32, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker7, 20, 32, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker8, 21, 29, -1, 6, AiOrder.DEFEND );
	
	-- bunkers on the beach from left to right
	ScriptManager:addOrder( enemySquadIds.bunker9, 3, 18, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker10, 5, 16, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker11, 5, 17, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker12, 12, 14, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker13, 12, 19, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker14, 18, 17, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker15, 19, 15, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bunker16, 24, 17, -1, 6, AiOrder.DEFEND );
end



-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR1, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR2, 7 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR3, 7 );
	
	ScriptManager:moveCameraEx( 12, 15, 0.5, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR4, 7 );

	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR5, 5 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_2_INTRO_FLAVOR6 );

	ScriptManager:moveCameraEx( 3, 23, 0.7, 2, true );
		
	ScriptManager:wait( 2 );

	ScriptManager:moveCameraEx( 10, 27, 0.7, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 24, 26, 0.7, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:moveCameraEx( 12, 3, 0.7, 3, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR7, 6 );
	
	ScriptManager:moveCameraEx( 4, 6, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR8, 6 );
	
	ScriptManager:moveCameraEx( 4, 12, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_INTRO_FLAVOR9, 8 );
	
	ScriptManager:moveCameraEx( 12, 3, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.clearBeach, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.RecaptureSupplies, MissionStatus.IN_PROGRESS );
	Utils:enablePlayerInteraction();
	
	
	-- player can't capture the enemy HQ
	local HQ = Unit:getUnitById( enemyHQId );
	HQ:setIsAttackable( false );
	


	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end


function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN


-- insert missionstuff here


function spawnPlaneWave()
 
   spawnPlaneWaves = 1;
   ScriptManager:removeTrigger( "spawnPlaneWave" );
  
   -- find a wave to spawn by random number
    local rnd = math.random ( 0, 2 );
    local spawnTable = 0;
  
   if rnd == 0 then
    spawnTable = planeWaveUnits1
   
    elseif rnd == 1 then
    spawnTable = planeWaveUnits2
   
    elseif rnd == 2 then
    spawnTable = planeWaveUnits3
   end
  
  for i = 1, #spawnTable do
    Utils:spawnUnitFromTable( spawnTable[i] );
  end  
	
	local orderId = ScriptManager:addOrder( enemySquadIds.planewave, -1, -1, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.bomber, -1, -1, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end


function checkWaypoints( squadId, mainOrderData, allMainOrderData )
  if squadId == enemySquadIds.planewave then
    Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTablePlane );
  end
    
  if squadId == enemySquadIds.bomber then
  Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTablePlane  );
  end
end


function waveSquadPlaneDestroyed()
  if spawnPlaneWaves == 1 then
    -- old wave squad was destroyed, prepare spawn for the next round
    local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval
    ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );  
   end
end


function onDefenderKilled( unit )
	if unit:getSquadId() == enemySquadIds.defendersLeft or
		unit:getSquadId() == enemySquadIds.defendersMiddle or
		unit:getSquadId() == enemySquadIds.defendersRight or
		unit:getSquadId() == enemySquadIds.defendersRightUp then
		
		Utils:incrementMissionProgress( missionIds.clearBeach );
		
		ScriptManager:runForPlayer( 0, "prepareDefenderMissionProgress" );
	end
end


function prepareDefenderMissionProgress()
	table.insert( queueTable, showDefenderMissionProgress );
	Utils:cutsceneQueue();
end


function showDefenderMissionProgress()
	
	if ScriptManager:getMissionProgress( missionIds.clearBeach ) == sixDefendersKilled then
			
	ScriptManager:runForPlayer( 0, "prepareTankCutscene" );
	end

	if ScriptManager:getMissionProgress( missionIds.clearBeach ) == eightDefendersKilled then
		
	ScriptManager:runForPlayer( 0, "prepareReinforcementCutscene" );
	end
	
	if ScriptManager:getMissionProgress( missionIds.clearBeach ) >= defendersToKill then
	ScriptManager:removeTrigger( "onDefenderKilled" );
	Utils:setMissionStatus( missionIds.clearBeach, MissionStatus.ACCOMPLISHED );
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 3 );
	
	checkForVictory()
	else 
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress( missionIds.clearBeach), defendersToKill, Text.T_CAMP_L1_2_PRIMARY1_COUNTER );
	end
end


function onBreachBarricadeSighted( discoveringUnit, discoveredUnit )
	
	if 
	discoveredUnit:getId() == barricade3 or --id 2
	discoveredUnit:getId() == barricade6 then -- id 8

--[[

barricade1 = 60; 	-- metal
barricade2 = 5;		-- wire
barricade3 = 2;		-- metal
barricade4 = 51;	-- metal
barricade5 = 87;	-- metal
barricade6 = 8;		-- wire
]]

		if
		ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.IN_PROGRESS and
		ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.ACCOMPLISHED then
		
		ScriptManager:removeTrigger( "onBreachBarricadeSighted" );
		
		ScriptManager:runForPlayer( 0, "prepareBreachBarricadeCutscene" );
		end
	end
end


function prepareTankCutscene()
	table.insert( queueTable, playTankCutscene );
	Utils:cutsceneQueue();
end

function playTankCutscene()

	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR2 );
	
	ScriptManager:moveCameraEx( 8, 3, 0.7, 3, true );
	
	ScriptManager:wait( 1 )
	
	local tank1 =	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_LIGHT, 8, 1, -1 ):getId();
	local tank2 = ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_MEDIUM, 7, 1, -1 ):getId();
	ScriptManager:moveUnitEx( tank1, 8, 4, true );
	ScriptManager:moveUnitEx( tank2, 9, 4, true );
	
	local tank3 = ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_LIGHT, 8, 1, -1 ):getId();
	local tank4 = ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_HEAVY, 7, 1, -1 ):getId();	
	ScriptManager:moveUnitEx( tank3, 8, 3, true );
	ScriptManager:moveUnitEx( tank4, 8, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:dismissSubtitle();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR3, 5 );
	
	Utils:endCutscene();
	
	if 
	ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.IN_PROGRESS and
	ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.ACCOMPLISHED then
	ScriptManager:runForPlayer( 0, "prepareBreachBarricadeCutscene" );
	end
end


function prepareBreachBarricadeCutscene()
	table.insert( queueTable, playBreachBarricadeCutscene );
	Utils:cutsceneQueue();
end



function playBreachBarricadeCutscene()	
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 7, 28, 0.7, 2, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR4 );
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 19, 30, 0.7, 2, true );
	ScriptManager:wait( 2 ); 
	
	ScriptManager:dismissSubtitle();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR5, 4 );

	-- break barricades mission
	
	Utils:endCutscene();
	
	ScriptManager:setMissionStatus( missionIds.breakOneBarricade, MissionStatus.IN_PROGRESS );
	
	-- when the barricades get destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, barricade1, "onBarricadeDestroyed", "onBarricadeDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_WIRE, barricade2, "onBarricadeDestroyed", "onBarricadeDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, barricade3, "onBarricadeDestroyed", "onBarricadeDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, barricade4, "onBarricadeDestroyed", "onBarricadeDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_METAL, barricade5, "onBarricadeDestroyed", "onBarricadeDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_WIRE, barricade6, "onBarricadeDestroyed", "onBarricadeDestroyed" );

--[[
barricade1 = 60; -- metal
barricade2 = 5;	-- wire
barricade3 = 2; -- metal
barricade4 = 51; -- metal
barricade5 = 87; -- metal
barricade6 = 8; -- wire
]]

end


function onBarricadeDestroyed( unit )

-- barricadesLeftTotal = #BarricadesLeftIds;
-- barricadesRightTotal = #BarricadesRightIds; 

	local barricadeId = unit:getId();
	local alreadyFound = false;
	
	for i = 1, #BarricadesLeftIds do
		if BarricadesLeftIds[i] == barricadeId then
			alreadyFound = true;
			barricadesLeftTotal = barricadesLeftTotal - 1;
			
			print( string.format( "barricadesLeftTotal: %i", barricadesLeftTotal ) );
			
			ScriptManager:storeValue( "leftBarricades" , leftBarricades -1 );
			ScriptManager:storeValue( "barricadesLeftTotal", barricadesLeftTotal );
			Utils:saveValuesIntoSavefileForExistingTable( "BarricadesLeftIds", BarricadesLeftIds );
			break;
		end
	end
	
	if alreadyFound == false then
		for i = 1, #BarricadesRightIds do
			if BarricadesRightIds[i] == barricadeId then
				barricadesRightTotal = barricadesRightTotal - 1;
				
				print( string.format( "barricadesRightTotal: %i", barricadesRightTotal ) );
				
				ScriptManager:storeValue( "rightBarricades", rightBarricades -1 );
				ScriptManager:storeValue( "barricadesRightTotal", barricadesRightTotal );
				Utils:saveValuesIntoSavefileForExistingTable( "BarricadesRightIds", BarricadesRightIds );
				break;
			end
		end
	end
	

--leftBarricades
--rightBarricades
	
	if alreadyFound == true then	
		if barricadesLeftTotal <= 0 then
			-- is primary done? -> accomplish secondary
				if ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) == MissionStatus.ACCOMPLISHED then
				   ScriptManager:setMissionStatus( missionIds.breakTwoBarricades, MissionStatus.ACCOMPLISHED );
				else
					ScriptManager:setMissionStatus( missionIds.breakOneBarricade, MissionStatus.ACCOMPLISHED );
					
					checkForVictory() --TODO
					
					
					Utils:disablePlayerInteraction();
					Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_SECONDARY2_FLAVOR1, 6 );
					ScriptManager:setMissionStatus( missionIds.breakTwoBarricades, MissionStatus.IN_PROGRESS );
						ScriptManager:wait( 2 );
							Utils:enablePlayerInteraction();
						
						if ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.IN_PROGRESS and
							 ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.ACCOMPLISHED then
	
						playAirfieldCutscene()
						end
				end
		else

				if ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.ACCOMPLISHED then
				Utils:incrementMissionProgress( missionIds.breakOneBarricade );
				Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.breakOneBarricade), Text.T_CAMP_L1_2_PRIMARY2_COUNTER );
				end
		end
	end
	
	if alreadyFound == false then
		if barricadesRightTotal <= 0 then
			-- is primary done? -> accomplish secondary
			if ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) == MissionStatus.ACCOMPLISHED then
				ScriptManager:setMissionStatus( missionIds.breakTwoBarricades, MissionStatus.ACCOMPLISHED );
				
			else
				ScriptManager:setMissionStatus( missionIds.breakOneBarricade, MissionStatus.ACCOMPLISHED );
				
				checkForVictory() --TODO
				
				Utils:disablePlayerInteraction();
				Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_SECONDARY2_FLAVOR1, 6 );
				ScriptManager:setMissionStatus( missionIds.breakTwoBarricades, MissionStatus.IN_PROGRESS );
				ScriptManager:wait( 2 );
				Utils:enablePlayerInteraction();
				
				if ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.IN_PROGRESS  and 
					 ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.ACCOMPLISHED then
				playAirfieldCutscene()
				end
			end
		else

			if ScriptManager:getMissionStatus( missionIds.breakOneBarricade ) ~= MissionStatus.ACCOMPLISHED then
			Utils:incrementMissionProgress( missionIds.breakOneBarricade );
			Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.breakOneBarricade), Text.T_CAMP_L1_2_PRIMARY2_COUNTER );
			end
		end
	end
end


function prepareReinforcementCutscene()
	table.insert( queueTable, playReinforcementCutscene );
	Utils:cutsceneQueue();
end


function playReinforcementCutscene()

	Utils:startCutscene();
-- some infantry troops come in from the left side (Map 1)
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR6, 4 );
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L1_2_PRIMARY2_FLAVOR7, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_PRIMARY2_FLAVOR8, 4 ); 
	
	ScriptManager:moveCameraEx( 3, 18, 0.7, 3, true );
	
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MORTAR, 1, 16, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MG, 1, 17, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_SNIPER, 1, 18, -1 );	
	
	ScriptManager:wait( 2 );
	
	Utils:endCutscene();

end


function playAirfieldCutscene()

	if 	ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.IN_PROGRESS  and
 			ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.ACCOMPLISHED then

	ScriptManager:removeTrigger( "playAirfieldCutscene" );

	Utils:startCutscene();

	ScriptManager:moveCameraEx( 22, 37, 0.7, 3, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_PRIMARY4_FLAVOR1, 3 );
	
	Utils:endCutscene();
	ScriptManager:setMissionStatus( missionIds.captureAirfield, MissionStatus.IN_PROGRESS );
	Utils:enablePlayerInteraction();
	end
end


function onAirfieldCapturedDestroyed()
	
	ScriptManager:removeTrigger( "onAirfieldCapturedDestroyed" );
	spawnPlaneWaves = 0;
	ScriptManager:setMissionStatus( missionIds.captureAirfield, MissionStatus.ACCOMPLISHED );
	checkForVictory()
end


function onLastBarrierDestroyed( unit )

	ScriptManager:removeTrigger( "onLastBarrierDestroyed" );

	for i = 1, #defenseSquad do
	Utils:spawnUnitFromTable( defenseSquad[i] );
	end
	
	local orderId = ScriptManager:addOrder( enemySquadIds.defenseSquad, unit:getX(), unit:getY(), -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
end


function onCratesRecaptured()
	Utils:incrementMissionProgress( missionIds.RecaptureSupplies );
	ScriptManager:runForPlayer( 0, "prepareSuppliesRecapturedProgress" );
end


function prepareSuppliesRecapturedProgress()
	table.insert( queueTable, showSuppliesRecapturedProgress );
	Utils:cutsceneQueue();
end


function showSuppliesRecapturedProgress()
	if ScriptManager:getMissionProgress( missionIds.RecaptureSupplies ) >= suppliesToRecapture then
	ScriptManager:removeTrigger( "onCratesRecaptured" );
	Utils:setMissionStatus( missionIds.RecaptureSupplies, MissionStatus.ACCOMPLISHED );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_SECONDARY1_FLAVOR1, 4 );
	
	else
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress( missionIds.RecaptureSupplies), suppliesToRecapture, Text.T_CAMP_L1_2_SECONDARY1_COUNTER );
	end
end



function reduceAAactionPoints()

	local artilleryBeachLeft = Unit:getUnitById( artilleryBeachLeft ):getId();
	if artilleryBeachLeft ~= nil then
	Unit:getUnitById( artilleryBeachLeft ):setActionPoints( 0 );
	end
	
	local artilleryBeachRight = Unit:getUnitById( artilleryBeachRight ):getId();
	if artilleryBeachRight ~= nil then
	Unit:getUnitById( artilleryBeachRight ):setActionPoints( 0 );
	end

--	Unit:getUnitById( artilleryBeachLeft ):setActionPoints( 0 );
--	Unit:getUnitById( artilleryBeachRight ):setActionPoints( 0 );
end



-- prevents the playerballoons form crashing
function setBalloonTurns()

	if playerBalloonOne ~= nil then
	Unit:getUnitById( playerBalloonOne ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonOne ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonOne ):setIsAttackable(false);
	end
	
	if playerBalloonTwo ~= nil then
	Unit:getUnitById( playerBalloonTwo ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonTwo ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonTwo ):setIsAttackable(false);
	end
	
	if playerBalloonThree ~= nil then
	Unit:getUnitById( playerBalloonThree ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonThree ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonThree ):setIsAttackable(false);
	end
	
	if playerBalloonFour ~= nil then
	Unit:getUnitById( playerBalloonFour ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFour ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFour ):setIsAttackable(false);
	end
	
	if playerBalloonFive ~= nil then
	Unit:getUnitById( playerBalloonFive ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFive ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFive ):setIsAttackable(false);
	end
end



-- END
-- BEGIN Victory


function checkForVictory()

	if 	ScriptManager:getMissionStatus( missionIds.clearBeach ) 				 == MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.breakOneBarricade )	 == MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.captureAirfield ) 		 == MissionStatus.ACCOMPLISHED then
			
			startVictoryCutscene()
	end
end


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_VICTORY_FLAVOR1 , 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_2_VICTORY_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 3 );
	
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

function checkForEnd()
	if ScriptManager:noUnitsLeftExt( { 0, Units.N_MINE_LAND, Units.L_PLANE_SCOUT, Units.L_SHIP_BS } ) then
		ScriptManager:runForPlayer( 0, "missionFailed" );
	end
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