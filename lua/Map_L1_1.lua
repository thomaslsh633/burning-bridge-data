require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"



-- mission stuff
missionIds = {
	reachShore	= 1,
	takeOutFortifications = 2,
	destroyBunkers = 3,
	pushBackAdvance = 4,
	clearMines = 5,		
	callAirstrike = 6,
};



-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.reachShore,						true,	Text.T_CAMP_L1_1_PRIMARY1,	75 },
	{ missionIds.takeOutFortifications,	true,	Text.T_CAMP_L1_1_PRIMARY2, 50 },
	{ missionIds.destroyBunkers,				true,	Text.T_CAMP_L1_1_PRIMARY3,	 150 },
	{ missionIds.pushBackAdvance,				true,	Text.T_CAMP_L1_1_PRIMARY4,	 50 },
	{ missionIds.clearMines,						false,	Text.T_CAMP_L1_1_SECONDARY1,	 50 }, 
	{ missionIds.callAirstrike, 				false, Text.T_CAMP_L1_1_SECONDARY2, 25 },
};

enemySquadIds = {

attackSquadOne = 1,
attackSquadTwo = 2,

unitsBeachLeft = 3,
unitsBeachMiddle = 4,
unitsBeachRight = 5,

mines = 6,

beachCannon = 7,
beachBunker = 8,

unitsBackLeft = 9,
unitsBackMiddle = 10,
unitsBackRight = 11,

planes = 12,

-- coast/beach artillery left to right
coastArtillery1 = 15,
coastArtillery2 = 16,
coastArtillery3 = 17,
coastArtillery4 = 18,
coastArtillery5 = 19,

-- coast/beach bunkers from left to right
coastBunker1 = 20,
coastBunker2 = 21,
coastBunker3 = 22,
coastBunker4 = 23,
coastBunker5 = 24,
coastBunker6 = 25,

-- from left to right
AA1 = 30,
AA2 = 31,
AA3 = 32,
AA4 = 33,
AA5 = 34,
AA6 = 35,

beachAA1 = 40,
beachAA2 = 41,

};

attackWave1 = {-- playerId, unitTemplateId, tileX, tileY, squadId

	{ 1, Units.X_INFANTRY_MG, 5, 23, enemySquadIds.attackSquadOne };
	{ 1, Units.X_INFANTRY_AT, 5, 22, enemySquadIds.attackSquadOne };
	{ 1, Units.X_INFANTRY_MG, 4, 23, enemySquadIds.attackSquadOne };
};	
	
attackWave2 = {-- playerId, unitTemplateId, tileX, tileY, squadId	
	{ 1, Units.X_INFANTRY_MG, 2, 16, enemySquadIds.attackSquadTwo };
	{ 1, Units.X_ARTILLERY_MORTAR, 2, 17, enemySquadIds.attackSquadTwo };
	{ 1, Units.X_INFANTRY_AT, 1, 15, enemySquadIds.attackSquadTwo };
};


planeWaveRespawnInterval = 2; -- defines how often waves will spawn
spawnPlaneWaves = 1;

planeWaveUnits1 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_LIGHT, 8, 29, enemySquadIds.planes };
};

planeWaveUnits2 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_HEAVY, 8, 29, enemySquadIds.planes };
};

planeWaveUnits3 = {--  playerId, templateID, tileX, tileY, squadId
	{ 1, Units.X_PLANE_BOMBER, 8, 29, enemySquadIds.planes };
};


playerAC = 86;

playerBalloonOne = 73;
playerBalloonTwo = 81;
playerBalloonThree = 74;
playerBalloonFour = 82;
playerBalloonFive = 75;

beachCannon = 32;
beachBunker = 59;

enemyAirfield = 33;


beachTiles = { { 1, 9 }, { 2, 9 }, { 3, 8 }, { 4, 9 }, { 5, 9 }, { 6, 10 }, { 12, 8 }, { 14, 8 }, { 15, 8 }, { 15, 7 }, { 17, 7 }, { 19, 8 }, { 19, 9 }, 
							{ 20, 10 }, { 21, 10 }, { 22, 10 }  };


waypointTablePlane = { { 4, 16 }, { 11, 16 }, { 16, 15 }, { 20, 14 }, { 11, 4 } };


waypointTableAttackers = { { 9, 19 }, { 14, 16 } };

unitsOnBeach = 6;
fortificationsToDestroy = 2;
bunkersToDestroy = 7;

fourBunkersDestroyed = 4;

minesToDisarm = 6;
attackersToKill = 6;

bunkersDestroyedYet = 0;
beachIds = { 32, 59 };


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();

	
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	
		-- spawn units in LCTs in front of the AC
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 10, 4, -1 ); 
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 6, 5, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME, 4, 3, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MORTAR, 13, 6, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_ENGINEER, 14, 3, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_LIGHT, 18, 2, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_MEDIUM, 18, 6, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TANK_HEAVY, 16, 5, -1 );
	ScriptManager:spawnUnit( 0, Units.L_PLANE_BOMBER, 12, 4, -1 );
	
	Unit:getUnitById( playerBalloonOne ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonOne ):setPlaneTurns( -1 );
        Unit:getUnitById( playerBalloonOne ):setIsAttackable( false );
	
	Unit:getUnitById( playerBalloonTwo ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonTwo ):setPlaneTurns( -1 );
        Unit:getUnitById( playerBalloonTwo ):setIsAttackable( false );
	
	Unit:getUnitById( playerBalloonThree ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonThree ):setPlaneTurns( -1 );
        Unit:getUnitById( playerBalloonThree ):setIsAttackable( false );
	
	Unit:getUnitById( playerBalloonFour ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFour ):setPlaneTurns( -1 );
        Unit:getUnitById( playerBalloonFour ):setIsAttackable( false );
	
	Unit:getUnitById( playerBalloonFive ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloonFive ):setPlaneTurns( -1 );
        Unit:getUnitById( playerBalloonFive ):setIsAttackable( false );
	

	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end


function storeValues()
	bunkersDestroyedYet = ScriptManager:storeValue( "bunkersDestroyedYet", bunkersDestroyedYet );
end


function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false );
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_SHIP_AC , -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_SHIP_AC, -1,	"transitionToFail",		"transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, -1,				 -1, "checkForEnd",			"checkForEnd" );


	ScriptManager:addOnUnitUnloadedTrigger( 0, -1, -1, "onUnitUnloaded", "onUnitUnloaded" );
	ScriptManager:addOnUnitUnloadedTrigger( 0, Units.L_INFANTRY_FLAME, -1, "onFlamethrowerUnloaded", "onFlamethrowerUnloaded" );


	-- when the beach cannon and the beach bunker are destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_COAST_SE, beachCannon, 			"onBeachCannonDestroyed", "onBeachCannonDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_EMPLACEMENT_BUNKERTOWER, beachBunker, "onBeachCannonDestroyed", "onBeachCannonDestroyed" );
	
	ScriptManager:addOnBunkerClearedTrigger( 1, Units.X_ARTILLERY_COAST_SE, beachCannon, "onBeachCannonCleared", "onBeachCannonCleared" );
	ScriptManager:addOnBunkerClearedTrigger( 1, Units.N_EMPLACEMENT_BUNKERTOWER, beachBunker, "onBeachCannonCleared","onBeachCannonCleared" );		
	
	
			
	-- when one of the artilleries has attacked
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_COAST_SE, -1, "onArtilleryHasAttacked", "onArtilleryHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_COAST_SW, -1, "onArtilleryHasAttacked", "onArtilleryHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.N_EMPLACEMENT_BUNKER, -1, "onArtilleryHasAttacked", "onArtilleryHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "onArtilleryHasAttacked", "onArtilleryHasAttacked" );


	-- starts the planeSpawn from the airfield
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval
  ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );

	-- trigger for wavespawn
	 ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	 ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planes,  "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	 
	-- waypoints foor the attackers
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypointsAttackers", "checkWaypointsAttackers" );
	 
	-- when the enemy airfield gets destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_AIRFIELD, enemyAirfield, "onAirfieldDestroyed", "onAirfieldDestroyed" );
	 
	-- when a plane has attacked
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_PLANE_LIGHT, -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_PLANE_HEAVY, -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_PLANE_BOMBER, -1, "onPlaneHasAttacked", "onPlaneHasAttacked" );
	
	
	-- when a mine gets triggered
	ScriptManager:addOnMineTriggeredTrigger( 1, -1, -1, "onMineTriggered", "onMineTriggered" );
	
	-- when mines are disarmed
	ScriptManager:addOnMineDisamedTrigger( 1, "onMineDisarmed", "onMineDisarmed" );
	
	-- When a mine gets detected
	ScriptManager:addOnMineDetectedTrigger( 1, -1, -1, "onMineDetected", "onMineDetected" ); 


	-- when bunkers are destroyed
	ScriptManager:addOnUnitDestroyedTrigger( -1, -1, -1, "onBunkerDestroyedCountUp", "onBunkerDestroyedCountUp" );
	ScriptManager:addOnBunkerClearedTrigger( 1, -1, -1, "onBunkerClearedCountUp", "onBunkerClearedCountUp" );
	
end


function loadValues()
		
	local balloon1 = Unit:getUnitById( playerBalloonOne );
	if balloon1 ~= nil then
	balloon1:setMaxPlaneTurns( -1 );
	balloon1:setPlaneTurns( -1 );
        balloon1:setIsAttackable( false );
	end
	
	local balloon2 = Unit:getUnitById( playerBalloonTwo );
	if balloon2 ~= nil then
	balloon2:setMaxPlaneTurns( -1 );
	balloon2:setPlaneTurns( -1 );	
        balloon2:setIsAttackable( false );
	end

	local balloon3 = Unit:getUnitById( playerBalloonThree );
	if balloon3 ~= nil then
	balloon3:setMaxPlaneTurns( -1 );
	balloon3:setPlaneTurns( -1 );	
        balloon3:setIsAttackable( false );
	end
	
	local balloon4 = Unit:getUnitById( playerBalloonFour );
	if balloon4 ~= nil then
	balloon4:setMaxPlaneTurns( -1 );
	balloon4:setPlaneTurns( -1 );	
        balloon4:setIsAttackable( false );
	end
	
	local balloon5 = Unit:getUnitById( playerBalloonFive );
	if balloon5 ~= nil then
	balloon5:setMaxPlaneTurns( -1 );
	balloon5:setPlaneTurns( -1 );	
        balloon5:setIsAttackable( false );
	end
	
		
	bunkersDestroyedYet = ScriptManager:getValue( "bunkersDestroyedYet" );
	
	print( string.format ( "bunkersDestroyedYet: %i", bunkersDestroyedYet ) );

	beachIds = Utils:loadValuesFromSavefileIntoExistingTable( "beachIds", beachIds );	
end


function addAiOrders()

	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBackLeft, 3, 28, -1, 4, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBackMiddle, 1, 28, -1, 4, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBackRight, 20, 28, -1, 5, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBeachLeft, 4, 18, -1, 4, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBeachMiddle, 11, 18, -1, 4, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.unitsBeachRight, 20, 18, -1, 4, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.beachCannon, 9 , 15, -1, 6, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_ATTACK_ALL_IN_RANGE );

	local orderId = ScriptManager:addOrder( enemySquadIds.beachBunker, 10, 17, -1, 4, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_ATTACK_ALL_IN_RANGE );


	local orderId = ScriptManager:addOrder( enemySquadIds.coastArtillery1, 2, 22, -1, 6, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastArtillery2, 5, 26, -1, 6, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastArtillery3, 11, 23, -1, 6, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastArtillery4, 12, 23, -1, 6, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastArtillery5, 17, 25, -1, 6, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker1, 1, 17, -1, 3, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker2, 2, 23, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker3, 6, 23, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker4, 7, 23, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker5, 14, 25, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.coastBunker6, 20, 21, -1, 3, AiOrder.DEFEND );
	
	
	local orderId = ScriptManager:addOrder( enemySquadIds.AA1, 1, 23, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.AA2, 7, 24, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.AA3, 9, 29, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.AA4, 12, 25, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.AA5, 16, 26, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.AA6, 20, 24, -1, 5, AiOrder.DEFEND );
		
	local orderId = ScriptManager:addOrder( enemySquadIds.beachAA1, 7, 18, -1, 3, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.beachAA2, 13, 18, -1, 3, AiOrder.DEFEND );
		
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_INTRO_FLAVOR1 );
	
	ScriptManager:wait( 1 )

	ScriptManager:moveCameraEx( 3, 4, 0.5, 3, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 20, 4, 0.5, 5, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 10, 4, 0.7, 3, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:dismissSubtitle();

	ScriptManager:moveCameraEx( 2, 17, 0.7, 3, true ); 
	
	ScriptManager:wait( 1 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_INTRO_FLAVOR2 );
	
	ScriptManager:moveCameraEx( 3, 22, 0.7, 2, true );
		
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 6, 24, 0.7, 2, true );

	ScriptManager:wait( 1 );

	ScriptManager:moveCameraEx( 12, 22, 0.7, 3, true );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:revealFogOfWar( 11, 23, 1, true );
	ScriptManager:revealFogOfWar( 12, 23, 1, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR3, 7 );
	
	ScriptManager:revealFogOfWar( 11, 23, 1, false );
	ScriptManager:revealFogOfWar( 12, 23, 1, false );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR4, 6 );
		
	ScriptManager:moveCameraEx( 16, 24, 0.7, 2, true );
	
	ScriptManager:wait( 1 );
	
	ScriptManager:moveCameraEx( 21, 20, 0.7, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 10, 16, 0.7, 3, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR5, 6 );

	ScriptManager:revealFogOfWar( 10, 17, 1, true );
	ScriptManager:revealFogOfWar( 9, 15, 1, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR6, 7 );

	ScriptManager:wait( 1 );
	ScriptManager:revealFogOfWar( 10, 17, 1, false );
	ScriptManager:revealFogOfWar( 9, 15, 1, false );
	
	ScriptManager:moveCameraEx( 11, 6, 0.5, 3, true );
	
	ScriptManager:showScaledMarkerAt( 11, 2, 2 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR7, 5 );
	
	ScriptManager:removeAllMarkers();
	
	ScriptManager:moveCameraEx( 10, 4, 1, 2, true );
	
	ScriptManager:showMarkerAt( 10, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR8, 5 );
	
	ScriptManager:removeAllMarkers();
	
	ScriptManager:moveCameraEx( 11, 6, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_INTRO_FLAVOR9, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 3 ); -- "Good luck!"
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end


function startTheMission()
	ScriptManager:setMissionStatus( missionIds.reachShore, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.takeOutFortifications, MissionStatus.IN_PROGRESS );
	Utils:enablePlayerInteraction();

		
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
    
	local orderId = ScriptManager:addOrder( enemySquadIds.planes, -1, -1, -1, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
  end  
end
  
  
function checkWaypoints( squadId, mainOrderData, allMainOrderData )
  if squadId == enemySquadIds.planes then
    Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTablePlane );
  end
end


function waveSquadPlaneDestroyed()
	
  if spawnPlaneWaves == 1 then
    -- old wave squad was destroyed, prepare spawn for the next round
    local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval
    ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );  
   end
end


function onAirfieldDestroyed()
	spawnPlaneWaves = 0;
end


function onUnitUnloaded( transporter )
	
	if transporter:getTemplateId() == Units.L_SHIP_LCT then
	
	Utils:incrementMissionProgress( missionIds.reachShore );
	ScriptManager:runForPlayer( 0, "prepareShoreReachedProgress" );
	end
end


function onFlamethrowerUnloaded( transporter, unit )
		
		ScriptManager:storeValue( "flamethrowerX", unit:getX() );
		ScriptManager:storeValue( "flamethrowerY", unit:getY() );
		
		ScriptManager:removeTrigger( "onFlamethrowerUnloaded" );
		ScriptManager:runForPlayer( 0, "prepareFlamethrowerSubtitle" );
end

function prepareFlamethrowerSubtitle()
	table.insert( queueTable, playFlamethrowerSubtitle );
	Utils:cutsceneQueue();
end

function playFlamethrowerSubtitle()

		Utils:disablePlayerInteraction();
		ScriptManager:moveCameraEx( ScriptManager:getValue( "flamethrowerX" ), ScriptManager:getValue( "flamethrowerY" ), 0.7, 2, true );
		ScriptManager:showMarkerAt( ScriptManager:getValue( "flamethrowerX" ), ScriptManager:getValue( "flamethrowerY" ) );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY1_FLAVOR3, 5 );
		
		ScriptManager:removeAllMarkers();
		
		Utils:enablePlayerInteraction();
end


function prepareShoreReachedProgress()
	table.insert( queueTable, showShoreReachedProgress );
	Utils:cutsceneQueue();
end
	
	
function showShoreReachedProgress()
	if ScriptManager:getMissionProgress( missionIds.reachShore ) >= unitsOnBeach then
		ScriptManager:removeTrigger( "onUnitUnloaded" );
		Utils:setMissionStatus( missionIds.reachShore, MissionStatus.ACCOMPLISHED );
		
		checkForVictory()

	ScriptManager:runForPlayer( 0, "prepareUnitsLandedCutscene" );

	else
	
	ScriptManager:wait( 0.5 );
	Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress(missionIds.reachShore), unitsOnBeach, Text.T_CAMP_L1_1_PRIMARY1_COUNTER );
	end
end		

function prepareUnitsLandedCutscene()
	table.insert( queueTable, playUnitsLandedCutscene );
	Utils:cutsceneQueue();
end

function playUnitsLandedCutscene()

		Utils:startCutscene();
	
		ScriptManager:moveCameraEx( 11, 4, 0.7, 2, true );
		ScriptManager:wait( 1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 10, 4, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_AT, 12, 4, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME, 13, 4, -1 );	
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 18, 2, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TRUCK_MG, 15, 1, -1 );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY1_FLAVOR1, 4 );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY1_FLAVOR2, 3 );
		
		Utils:endCutscene();
	
	  -- start the plane wave from the airfield 
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "spawnPlaneWave", "spawnPlaneWave" );
end



function onBeachCannonCleared( flamethrower, bunker )
	if bunker:getId() == beachCannon or
		 bunker:getId() == beachBunker then
		onBeachCannonDestroyed()
	end
end

function onBeachCannonDestroyed()

	Utils:incrementMissionProgress( missionIds.takeOutFortifications );
	ScriptManager:runForPlayer( 0, "prepareFortificationsProgress")
end


function prepareFortificationsProgress()
	table.insert( queueTable, showFortificationsProgress );
	Utils:cutsceneQueue();
end


function showFortificationsProgress()



	if ScriptManager:getMissionProgress( missionIds.takeOutFortifications ) >= fortificationsToDestroy then
		
	ScriptManager:removeTrigger( "onBeachCannonCleared" );
	Utils:setMissionStatus( missionIds.takeOutFortifications, MissionStatus.ACCOMPLISHED );
		
	checkForVictory()
	
	
		if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.IN_PROGRESS and
				ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.ACCOMPLISHED then
			 ScriptManager:runForPlayer( 0, "prepareBunkerCutscene" );
		end

	else
	
	Utils:showMissionProgress(ScriptManager:getMissionProgress( missionIds.takeOutFortifications), Text.T_CAMP_L1_1_PRIMARY2_COUNTER );
	end
end
		
function prepareBunkerCutscene()
	table.insert( queueTable, startBunkerCutscene );
	Utils:cutsceneQueue();
end
		
function startBunkerCutscene()		

	Utils:startCutscene();

	ScriptManager:moveCameraEx( 10, 16, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY2_FLAVOR1, 6 );
		
		if 
		ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.ACCOMPLISHED then
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY2_FLAVOR2, 6 );
		end

	Utils:endCutscene();
		
		if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.IN_PROGRESS then
		ScriptManager:setMissionStatus( missionIds.destroyBunkers, MissionStatus.IN_PROGRESS );		
		end
end


function onBunkerDestroyedCountUp( unit )

	ScriptManager:storeValue( "bunkerX", unit:getX() );
	ScriptManager:storeValue( "bunkerY", unit:getY() );
	
	if unit:getPlayerId() == 1 then
		
		if unit:getTemplateId() == Units.X_ARTILLERY_COAST_SE or
		 	 unit:getTemplateId() == Units.X_ARTILLERY_COAST_SW or
			 unit:getTemplateId() == Units.N_EMPLACEMENT_BUNKER or
		   unit:getTemplateId() == Units.N_EMPLACEMENT_BUNKERTOWER then
		
			if unit:getId() ~= beachCannon and 
				 unit:getId() ~= beachBunker then
	
				Utils:incrementMissionProgress( missionIds.destroyBunkers );
		
				bunkersDestroyedYet = bunkersDestroyedYet + 1;
		
				ScriptManager:storeValue( "bunkersDestroyedYet", bunkersDestroyedYet );
		
				print( bunkersDestroyedYet )
	
				ScriptManager:runForPlayer( 0, "prepareBunkerDestroyedProgress" );
	
				if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.IN_PROGRESS then
				ScriptManager:runForPlayer( 0, "prepareAlternativeBunkerCutscene" );
				ScriptManager:runForPlayer( 0, "prepareBunkerDestroyedProgress" );
				end
			end	
		end
	end
end


function onBunkerClearedCountUp( flamethrower, bunker )

	ScriptManager:storeValue( "bunkerX", bunker:getX() );
	ScriptManager:storeValue( "bunkerY", bunker:getY() );

	if bunker:getPlayerId() == 1 then

		if bunker:getTemplateId() == Units.X_ARTILLERY_COAST_SE or
			 bunker:getTemplateId() == Units.X_ARTILLERY_COAST_SW or
			 bunker:getTemplateId() == Units.N_EMPLACEMENT_BUNKER or
  		 bunker:getTemplateId() == Units.N_EMPLACEMENT_BUNKERTOWER then

			if bunker:getId() ~= beachCannon and 
				 bunker:getId() ~= beachBunker then

				bunkersDestroyedYet = bunkersDestroyedYet + 1;
				
				Utils:incrementMissionProgress( missionIds.destroyBunkers );

				ScriptManager:storeValue( "bunkersDestroyedYet", bunkersDestroyedYet );

				print( bunkersDestroyedYet )

				ScriptManager:runForPlayer( 0, "prepareBunkerDestroyedProgress" );

				if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.IN_PROGRESS then
				ScriptManager:runForPlayer( 0, "prepareAlternativeBunkerCutscene" );
				ScriptManager:runForPlayer( 0, "prepareBunkerDestroyedProgress" );
				end
			end
		end
	end
end



function prepareBunkerDestroyedProgress()
	table.insert( queueTable, showBunkerDestroyedProgress );
	Utils:cutsceneQueue();
end


function showBunkerDestroyedProgress()
	
	if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) == MissionStatus.IN_PROGRESS then

		if ScriptManager:getMissionProgress( missionIds.destroyBunkers ) == fourBunkersDestroyed then
			ScriptManager:runForPlayer( 0, "prepareAttackerCutscene" );
		end

			if ScriptManager:getMissionProgress( missionIds.destroyBunkers ) >= bunkersToDestroy then
	
			ScriptManager:removeTrigger( "onBunkerCleared" );
			ScriptManager:removeTrigger( "onBunkerDestroyed" );
			ScriptManager:removeTrigger( "onBunkerDestroyedCountUp" );
			ScriptManager:removeTrigger( "onBunkerClearedCountUp" );
	
			Utils:setMissionStatus( missionIds.destroyBunkers, MissionStatus.ACCOMPLISHED ); 

			checkForVictory()
	
			else
			Utils:showMissionProgressTwoVar( bunkersDestroyedYet, bunkersToDestroy, Text.T_CAMP_L1_1_PRIMARY3_COUNTER );
	
		end
	end
end


function prepareAlternativeBunkerCutscene()
	table.insert( queueTable, startAlternativeBunkerCutscene );
	Utils:cutsceneQueue();
end


function startAlternativeBunkerCutscene()
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 11, 23, 0.7, 3, true );
	ScriptManager:revealFogOfWar( 11, 23, 1, true );
	
	ScriptManager:wait( 1 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY2_FLAVOR2, 6 );
	
	ScriptManager:revealFogOfWar( 11, 23, 1, false );
	
	ScriptManager:wait( 1 );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.destroyBunkers, MissionStatus.IN_PROGRESS );
end



function checkWaypointsAttackers( squadId, mainOrderData, allMainOrderData )
	if  squadId == enemySquadIds.attackSquadOne or
			squadId == enemySquadIds.attackSquadTwo then
			
			Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, waypointTableAttackers );
	end
end


function prepareAttackerCutscene()
	table.insert( queueTable, playAttackerCutscene );
	Utils:cutsceneQueue();
end


function playAttackerCutscene()

	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 3, 19, 0.5, 3, true );

	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY4_FLAVOR1, 4 );
	
	ScriptManager:revealFogOfWar( 5, 22, 1, true );
	ScriptManager:revealFogOfWar( 2, 16, 1, true );	
	
	for i = 1, #attackWave1 do
		Utils:spawnUnitFromTable( attackWave1[i] );
	end


	for i = 1, #attackWave2 do
		Utils:spawnUnitFromTable( attackWave2[i] );
	end
	

	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY4_FLAVOR2, 4 );
	
	ScriptManager:revealFogOfWar( 5, 22, 1, false );
	ScriptManager:revealFogOfWar( 2, 16, 1, false );	
	
	Utils:endCutscene();
	
	if ScriptManager:getMissionProgress( missionIds.destroyBunkers ) ~= MissionStatus.ACCOMPLISHED then
	
	local orderId = ScriptManager:addOrder( enemySquadIds.attackSquadOne, 16, 20, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.attackSquadTwo, 16, 20, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	end
		-- when one of the attackers gets killed
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onAttackerDestroyed", "onAttackerDestroyed" );
	
	Utils:setMissionStatus( missionIds.pushBackAdvance, MissionStatus.IN_PROGRESS );
end


function onPlaneHasAttacked( unit )
	if unit ~= nil then
	
	ScriptManager:removeTrigger( "onPlaneHasAttacked" );
	
	ScriptManager:runForPlayer( 0, "preparePlaneCutscene" );
	end
end


function preparePlaneCutscene()
	table.insert( queueTable, playPlaneCutscene );
	Utils:cutsceneQueue();
end


function playPlaneCutscene()
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY1_FLAVOR4, 3 );
	
	ScriptManager:moveCameraEx( 11, 4, 0.7, 2, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_PRIMARY1_FLAVOR5 );
	
	ScriptManager:spawnUnit( 0, Units.L_PLANE_LIGHT, 10, 4, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_TRUCK_AA, 12, 4, -1 );
	
	ScriptManager:wait( 6 );
	
	ScriptManager:dismissSubtitle();
	
	Utils:endCutscene();
end


function onArtilleryHasAttacked( attacker )

	ScriptManager:removeTrigger( "onArtilleryHasAttacked" );

	if attacker ~= nil 					and
		 attacker ~= beachBunker  and
		 attacker ~= beachCannon 	then
		 
		 ScriptManager:storeValue( "artilleryX", attacker:getX() );
		 ScriptManager:storeValue( "artilleryY", attacker:getY() );
		 	 
		 ScriptManager:runForPlayer( 0, "prepareAirstrikeCutscene" );
	end
end
		 
		 
function prepareAirstrikeCutscene()
 table.insert( queueTable, playAirstrikeCutscene );
 Utils:cutsceneQueue();
end
		 
		 
function playAirstrikeCutscene()

		Utils:startCutscene()
		
		ScriptManager:wait( 1 );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_SECONDARY2_FLAVOR1 );

		ScriptManager:moveCameraEx( ScriptManager:getValue( "artilleryX" ), ScriptManager:getValue( "artilleryY" ), 0.7, 2, true );
		
		ScriptManager:wait( 5 );
		
		ScriptManager:dismissSubtitle();
	
		ScriptManager:moveCameraEx( 11, 4, 0.7, 3, true );
	
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_SECONDARY2_FLAVOR2, 8 );
		
		ScriptManager:startHighlightingGlobalAbilityMenu();
		
		ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, GlobalAbility.MENU, "onGAmenuSelected", "onGAmenuSelected" );

		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_SECONDARY2_FLAVOR3, 4 ); 
			
		ScriptManager:wait( 2 );
		
		Utils:endCutscene();
		
		ScriptManager:setMissionStatus( missionIds.callAirstrike, MissionStatus.IN_PROGRESS );
		ScriptManager:addOnAirstrikeTrigger( GlobalAbility.AIRSTRIKE, 0, -1, -1, "onAirstrikeCalled", "onAirstrikeCalled" );
		
		Utils:enablePlayerInteraction();
end


function onGAmenuSelected()
	
	ScriptManager:removeTrigger( "onGAmenuSelected" );
	ScriptManager:stopHighlightingGlobalAbilityMenu()
	ScriptManager:wait( 0.1 );
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:startHighlightingGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:wait( 0.1 );
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, GlobalAbility.AIRSTRIKE, "onAirstrikeButtonSlected", "onAirstrikeButtonSlected" );
end



function onAirstrikeButtonSlected()
	ScriptManager:removeTrigger( "onAirstrikeButtonSlected" );
	ScriptManager:stopHighlightingGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
end


function onAirstrikeStopHighlighting()
	ScriptManager:removeTrigger( "onAirstrikeStopHighlighting" );
	ScriptManager:stopHighlightingGlobalAbilityMenu();
	ScriptManager:stopHighlightingGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
end



function onAirstrikeCalled()
	ScriptManager:removeTrigger( "onAirstrikeCalled" );
	ScriptManager:wait( 1 );
	Utils:setMissionStatus( missionIds.callAirstrike, MissionStatus.ACCOMPLISHED );
end


function onAttackerDestroyed( unit )
--	local squadId = unit:getSquadId();
	
		if 	
			unit:getSquadId() == enemySquadIds.attackSquadOne or
			unit:getSquadId() == enemySquadIds.attackSquadTwo	then
			Utils:incrementMissionProgress( missionIds.pushBackAdvance );
			ScriptManager:runForPlayer( 0, "prepareAttackerDestroyedProgress" );
		end
end


function prepareAttackerDestroyedProgress()
	table.insert( queueTable, showAttackerDestroyedProgress );
	Utils:cutsceneQueue();
end


function showAttackerDestroyedProgress()
	if ScriptManager:getMissionProgress( missionIds.pushBackAdvance ) >= attackersToKill then
		Utils:setMissionStatus( missionIds.pushBackAdvance, MissionStatus.ACCOMPLISHED );
		
		checkForVictory()
		
		Utils:startCutscene();
		
			if ScriptManager:getMissionStatus( missionIds.destroyBunkers ) ~= MissionStatus.ACCOMPLISHED then
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_PRIMARY4_FLAVOR3, 3 );
			
			elseif ScriptManager:getMissionStatus( missionIds.destroyBunkers ) == MissionStatus.ACCOMPLISHED then
			Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_1, 3 );
			end
			Utils:endCutscene();
	end
end



function onMineDetected( mineX, mineY, mineId )
	ScriptManager:removeTrigger( "onMineDetected" );	
	
	ScriptManager:storeValue( "mineX", mineX );
	ScriptManager:storeValue( "mineY", mineY );
	
	if ScriptManager:getMissionStatus( missionIds.clearMines ) ~= MissionStatus.IN_PROGRESS then
		ScriptManager:removeTrigger( "onMineTriggered" );
		ScriptManager:runForPlayer( 0, "prepareMineDetectedCutscene" );
	end
end


function prepareMineDetectedCutscene()
	table.insert( queueTable, onMineDetectedCutscene );
	Utils:cutsceneQueue();
end


function onMineDetectedCutscene()

	ScriptManager:removeTrigger( "onMineDetected" );
	
	if ScriptManager:getMissionStatus( missionIds.clearMines ) ~= MissionStatus.IN_PROGRESS then
	ScriptManager:removeTrigger( "onMineTriggered" );
	
	ScriptManager:wait( 1 );
	
	Utils:startCutscene();
	
	ScriptManager:wait( 1 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_SECONDARY1_FLAVOR1 );
	
	ScriptManager:wait( 1 );
	
	ScriptManager:moveCameraEx( 6, 17, 0.7, 3, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 19, 17, 0.7, 4, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "mineX" ), ScriptManager:getValue( "mineY" ), 0.7, 3, true );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:wait( 1 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_SECONDARY1_FLAVOR2 );
	
	ScriptManager:wait( 6 );
	
	ScriptManager:dismissSubtitle();
	
	Utils:endCutscene();
	
	ScriptManager:setMissionStatus( missionIds.clearMines, MissionStatus.IN_PROGRESS );

	end
end



function onMineTriggered( mineX, mineY, unitId, mineId )

	ScriptManager:removeTrigger( "onMineTriggered" );	

	ScriptManager:storeValue( "mineX", mineX );
	ScriptManager:storeValue( "mineY", mineY );
	
	if ScriptManager:getMissionStatus( missionIds.clearMines ) ~= MissionStatus.IN_PROGRESS then
	ScriptManager:removeTrigger( "onMineDetected" );
	ScriptManager:runForPlayer( 0, "prepareMineTriggeredCutscene" );
	end
end


function prepareMineTriggeredCutscene()
	table.insert( queueTable, onMineTriggeredCutscene );
	Utils:cutsceneQueue();
end


function onMineTriggeredCutscene()
	
	Utils:startCutscene();
	
	ScriptManager:wait( 1 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_SECONDARY1_FLAVOR1 );
	
	ScriptManager:wait( 1 );
	
	ScriptManager:moveCameraEx( 6, 17, 0.7, 3, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 19, 17, 0.7, 4, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "mineX" ), ScriptManager:getValue( "mineY" ), 0.7, 3, true );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:wait( 1 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_1_SECONDARY1_FLAVOR2 );
	
	ScriptManager:wait( 6 );
	
	ScriptManager:dismissSubtitle();
	
	Utils:endCutscene();
	
	ScriptManager:setMissionStatus( missionIds.clearMines, MissionStatus.IN_PROGRESS );

end


function onMineDisarmed()

	Utils:incrementMissionProgress( missionIds.clearMines );
	if ScriptManager:getMissionProgress( missionIds.clearMines )>= minesToDisarm then
		ScriptManager:removeTrigger( "onMineDisarmed" );
		Utils:setMissionStatus( missionIds.clearMines, MissionStatus.ACCOMPLISHED );
	else
	Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.clearMines ), Text.T_CAMP_L1_1_SECONDARY1_FLAVOR3 );
	end
end



-- END
-- BEGIN Victory



function checkForVictory()
	if 	ScriptManager:getMissionStatus( missionIds.reachShore ) 						== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.takeOutFortifications ) 	== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.destroyBunkers ) 				== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.pushBackAdvance ) 				== MissionStatus.ACCOMPLISHED then
			
			startVictoryCutscene()
	end
end


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_VICTORY_FLAVOR1, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_1_VICTORY_FLAVOR2, 3 );
	
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