require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	captureHQ	= 1,
	captureDestroyOutpost = 2,
	destroyEmplacements	= 3,
	destroyAntiAirs = 4,
	sendParatroopers = 5,
};

--TODO set XP and Gold!



-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.captureHQ,							true,	Text.T_MISSION_CAP_BASE,	100 },
	{ missionIds.captureDestroyOutpost,	true,	Text.T_MISSION_CAP_DESTROY_OUTPOST,	100 },	
	{ missionIds.destroyEmplacements,		true,	Text.T_CAMP_L1_3_PRIMARY3,	100 },
	{ missionIds.destroyAntiAirs,				false,Text.T_CAMP_L1_3_SECONDARY1, 50 },
	{ missionIds.sendParatroopers,			false,Text.T_CAMP_L1_3_SECONDARY2, 50 },		--TODO
};


beachTiles = { { 17, 9 }, { 18, 10 }, { 17, 11 }, { 18, 12 }, { 18, 13 }, { 19, 14 }, { 19, 15 }, { 20, 15 } };
leftTiles = { { 1, 14 }, { 2, 14 } }; -- small passage to the left
bridgeTiles = { { 6, 40 }, { 5, 39 }, { 6, 38 }, { 5, 37 }, }; -- left side of the bridge

rubberboatTiles = { { 10, 17 }, { 11, 16 }, { 10, 15 }, { 11, 14 }, { 12, 4 }, { 12, 3 } };

AApatrolTiles = { { 3, 40 }, { 13, 40 }, { 20, 32 } };

enemySquadIds = {

	attackSquadOne = 1;
	attackSquadTwo = 2;
	attackSquadThree = 3;

	
	enemiesBeachRight = 6;
	
	mgNestBeachRight = 7;
	
	enemiesBeachLeft = 8;
		
	-- beach bunkers from left to right
	
	bunkerBeach1 = 9;	
	bunkerBeach2 = 10;
	bunkerBeach3 = 11;	
	bunkerBeach4 = 12;
	bunkerBeach5 = 13;
	
	enemiesLeftDown = 14;
	
	bunkerLeftDown = 15;
	
	enemiesLeftUp = 16;
	
	mgNestLeftUp = 17;
	
	enemiesRightUp = 19;
	
	enemiesHQ = 20;
	
	mgNestHQ = 21;
	
	enemiesRightDown = 22;
	
	bunkerNearBridge = 23,
	
	riverWoods = 24,
	
	patrollingAA = 25,
	
	outpostDefenders = 26,
	
	stationaryAntiAir1 = 30;
	stationaryAntiAir2 = 31;
	stationaryAntiAir3 = 32;
	stationaryAntiAir4 = 33;
	stationaryAntiAir5 = 34;
	stationaryAntiAir6 = 35;
	stationaryAntiAir7 = 36;
	stationaryAntiAir8 = 37;
	
	riverBunker1 = 40,
	riverBunker2 = 41,	
	riverBunker3 = 42,
	riverBunker4 = 43,
	riverBunker5 = 44,	

	mines = 50 ;
	
	
};

attackSquadOne = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.X_INFANTRY_MG, 16, 22, enemySquadIds.attackSquadOne };
	{ 1, Units.X_INFANTRY_AT, 16, 23, enemySquadIds.attackSquadOne };
	{ 1, Units.X_ARTILLERY_MORTAR, 12, 19, enemySquadIds.attackSquadOne };	
};

attackSquadTwo = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.X_INFANTRY_MG, 1, 20, enemySquadIds.attackSquadTwo };
	{ 1, Units.X_TANK_MEDIUM, 1, 21, enemySquadIds.attackSquadTwo };
	{ 1, Units.X_INFANTRY_MG, 1, 22, enemySquadIds.attackSquadTwo };
};

attackSquadThree = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.X_TANK_HEAVY, 14, 42, enemySquadIds.attackSquadThree };
	{ 1, Units.X_INFANTRY_MG, 14, 41, enemySquadIds.attackSquadThree };
	{ 1, Units.X_INFANTRY_FLAME, 15, 42, enemySquadIds.attackSquadThree };
	{ 1, Units.X_ARTILLERY_MORTAR, 13, 42, enemySquadIds.attackSquadThree };
};


riverEmplacement1 = 65;
riverEmplacement2 = 14;
riverEmplacement3 = 51;
riverEmplacement4 = 62;
riverEmplacement5 = 67;


stationaryAA1 = 19;
stationaryAA2 = 2;
stationaryAA3 = 6;
stationaryAA4 = 5;
stationaryAA5 = 4;
stationaryAA6 = 8;
stationaryAA7 = 3;
stationaryAA8 = 52;


enemyOutpostId = 7;
enemyHQId = 1;

suppliesLeft = 12;

riverBunkerLeftDown = 14;
riverBunkerRightDown = 76;
riverBunkerRightUp = 62;
riverBunkerLeftUp = 67;

playerAC = 60;
playerBalloon = 80;

unitsSquadOne = 3;
unitSquadTwo = 3;
unitsSquadThree = 4;

attackersToKill = 10;
AAsToDestroy = 8;

riverBunkersToDestroy = 5;

-- BEGIN Init



function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1200 );
	
	
	Utils:setIsAttackable( enemyHQId, false );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 17, 4, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MORTAR, 18, 5, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_ENGINEER, 20, 4, -1 );
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME, 19, 7, -1 );
	ScriptManager:spawnUnit( 0, Units.L_PLANE_LIGHT, 20, 1, -1 );
	
	ScriptManager:fortifyUnit( 6, true );
	ScriptManager:fortifyUnit( 2, true );
	ScriptManager:fortifyUnit( 19, true );
	ScriptManager:fortifyUnit( 52, true );
	ScriptManager:fortifyUnit( 3, true );
	ScriptManager:fortifyUnit( 8, true );
	ScriptManager:fortifyUnit( 5, true );
	ScriptManager:fortifyUnit( 4, true );
	ScriptManager:fortifyUnit( 42, true );
	
	Unit:getUnitById( playerBalloon ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloon ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloon ):setIsAttackable(false);
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	
	ScriptManager:storeValue( "rubberboatTrigger", 0 );
	ScriptManager:storeValue( "leftLineTrigger", 0 );
	ScriptManager:storeValue( "bridgeTrigger", 0 ); 
	
end



function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, playerAC , -1,	"showAttackedWarningAC",	"showAttackedWarningAC" );
	ScriptManager:addOnUnitHasAttackedTrigger( 0, Units.X_BUILDING_HQ, enemyHQId, "stopAttackingHint", "stopAttackingHint" );

	ScriptManager:addOnUnitDestroyedTrigger(	0, playerAC , -1,	"transitionToFail",		"transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, -1,				 -1, "checkForEnd",			"checkForEnd" );
	
	-- when the enemy HQ is captured or destroyed
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_HQ, enemyHQId, "onEnemyHQCaptured", "onEnemyHQCaptured" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_HQ, enemyHQId, "transitionToFail", "transitionToFail" );
		
	-- when the enemy outpost is captured or destroyed
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_HQ, enemyOutpostId, "onEnemyOutpostCaptured", "onEnemyOutpostCaptured" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_HQ, enemyOutpostId, "onEnemyOutpostCaptured", "onEnemyOutpostCaptured" );

	
	ScriptManager:addOnUnitUnloadedTrigger( 0, -1, -1, "onUnitunloaded", "onUnitunloaded" );
	
	
	-- when player has crossed line at 1/14 | 2/14 set target tile for attack squad two
	for i = 1, #leftTiles do
	ScriptManager:addOnEnterTileTrigger( leftTiles[i][1], leftTiles[i][2], 0, -1, -1, false, "onLeftLineCrossed", "onLeftLineCrossed", false );
	end
		
	-- when player has crossed the bridge, set target tile for attack squad three
	for i = 1, #bridgeTiles do
	ScriptManager:addOnEnterTileTrigger( bridgeTiles[i][1], bridgeTiles[i][2], 0, -1, -1, false, "onEnterBridge", "onEnterBridge", false );
	end
	
	-- Triggers the rubberboat cutscene
	for i = 1, #rubberboatTiles do
	ScriptManager:addOnEnterTileTrigger( rubberboatTiles[i][1], rubberboatTiles[i][2], 0, -1, -1, true, "playRubberboatCutscene", "playRubberboatCutscene", false );
	end

	-- trigger for paratrooper and on enter tile triggers
	ScriptManager:addOnUnitCreatedTrigger( 0, -1, "onUnitCreated", "onUnitCreated" );

	
	-- when one of the river emplacements has attacked
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_COAST_SE, -1, "onRiverBunkerHasAttacked", "onRiverBunkerHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_COAST_SW, -1, "onRiverBunkerHasAttacked", "onRiverBunkerHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.N_EMPLACEMENT_BUNKER, -1, "onRiverBunkerHasAttacked", "onRiverBunkerHasAttacked" );
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "onRiverBunkerHasAttacked", "onRiverBunkerHasAttacked" );

	ScriptManager:addOnUnitSightedTrigger( 1, -1, -1, true, "onRiverEmplacementSighted", "onRiverEmplacementSighted" );

		
	-- when one of the AAs gets spotted
	ScriptManager:addOnUnitSightedTrigger( 1, Units.X_ARTILLERY_AA, -1, true, "onAAsighted", "onAAsighted" );
	
	-- when one of the AAs has attacked
	ScriptManager:addOnUnitHasAttackedTrigger( 1, Units.X_ARTILLERY_AA, -1, "onAAhasAttacked", "onAAhasAttacked" );
	
	-- when a stationary AntiAir gets destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_ARTILLERY_AA, -1, "onAAdestroyed", "onAAdestroyed" );
	
	
	ScriptManager:addOnUnitHasAttackedTrigger( 1, -1, -1, "onAttackerHasAttacked", "onAttackerHasAttacked" );
	
		
	-- patrolling mobile AA
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	
	-- Reducing the action points of stationary AAs
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "reduceAAactionPoints", "reduceAAactionPoints" );
	
	ScriptManager:addOnGameResumeTrigger( "setBalloonTurns", "setBalloonTurns" );
	
end

function loadValues()
	
	local balloon = Unit:getUnitById( playerBalloon );
	if balloon ~= nil then
	balloon:setMaxPlaneTurns( -1 );
	balloon:setPlaneTurns( -1 );
	balloon:setIsAttackable(false);	
	end

end

function addAiOrders()

	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir1, 4, 18, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir2, 2, 25, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir3, 4, 39, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir4, 10, 37, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir5, 18, 39, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir6, 17, 30, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir7, 13, 26, -1, 4, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.stationaryAntiAir8, 18, 20, -1, 4, AiOrder.DEFEND );

	-- squadID = 40
	local orderId =  ScriptManager:addOrder( enemySquadIds.riverBunker1, 6, 18, -1, 5, AiOrder.DEFEND );
	
	-- SquadId = 41
	local orderId =  ScriptManager:addOrder( enemySquadIds.riverBunker2, 11, 19, -1, 3, AiOrder.DEFEND );
	
	-- SquadId = 42
	local orderId =  ScriptManager:addOrder( enemySquadIds.riverBunker3, 10, 23, -1, 3, AiOrder.DEFEND );
	
	-- SquadId = 43
	local orderId =  ScriptManager:addOrder( enemySquadIds.riverBunker4, 9, 28, -1, 5, AiOrder.DEFEND );
	
	-- SquadId = 44
	local orderId =  ScriptManager:addOrder( enemySquadIds.riverBunker5, 5, 35, -1, 3, AiOrder.DEFEND );

	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesBeachRight, 16, 21, -1, 4, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.mgNestBeachRight, 14, 14, -1, 4, AiOrder.DEFEND );
	 
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesBeachLeft, 3, 10, -1, 4, AiOrder.DEFEND );


	
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerBeach1, 3, 14, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerBeach2, 4, 13, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerBeach3, 15, 23, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerBeach4, 19, 27, -1, 5, AiOrder.DEFEND );
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerBeach5, 20, 18, -1, 6, AiOrder.DEFEND );

	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesLeftDown, 2, 20, suppliesLeft, 2, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesLeftUp, 3, 37, -1, 3, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesRightDown, 17, 30, stationaryAA6, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesRightUp, 10, 37, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerLeftDown, 2, 24, -1, 3, AiOrder.DEFEND );



	local orderId = ScriptManager:addOrder( enemySquadIds.mgNestLeftUp, 1, 38, -1, 3, AiOrder.DEFEND );

	
	local orderId = ScriptManager:addOrder( enemySquadIds.bunkerNearBridge, 9, 40, -1, 3, AiOrder.DEFEND );
	
	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemiesHQ, 20, 40, enemyHQId, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.mgNestHQ, 16, 42, -1, 3, AiOrder.DEFEND );

	local orderId = ScriptManager:addOrder( enemySquadIds.riverWoods, 12, 29, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.patrollingAA, -1, -1, -1, 3, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.outpostDefenders, 2, 40, enemyOutpostId, 2, AiOrder.DEFEND );
end 



-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR1, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR2, 6 );
	
	ScriptManager:moveCameraEx( 20, 40, 0.7, 3, true );
	
	ScriptManager:revealFogOfWar( 20, 40, 1, true );
	ScriptManager:showMarkerAt( 20, 40 );
	
	ScriptManager:wait( 1 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR3, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR4, 6 );
	
	ScriptManager:removeAllMarkers();
	ScriptManager:wait( 1 );
	ScriptManager:revealFogOfWar( 20, 40, 1, false );
	
	ScriptManager:moveCameraEx( 2, 40, 0.7, 3, true );
	
	ScriptManager:revealFogOfWar( 2, 40, 1, true );
	ScriptManager:showMarkerAt( 2, 40 );
	
	ScriptManager:wait( 1 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR5, 3 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR6, 5 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR7, 5 );
	
	ScriptManager:removeAllMarkers();
	ScriptManager:wait( 1 );
	ScriptManager:revealFogOfWar( 2, 40, 1, false );
	
	ScriptManager:moveCameraEx( 18, 5, 0.7, 4, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_INTRO_FLAVOR8, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.captureHQ, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.captureDestroyOutpost, MissionStatus.IN_PROGRESS );
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

function onUnitCreated( createdUnit )
	local posX = createdUnit:getX();
	local posY = createdUnit:getY();
	
	-- leftline Trigger
	if posX == 1 and posY == 14 or 
		 posX == 2 and posY == 14 then
		if ScriptManager:getValue( "leftLineTrigger" ) == 0 then
		onLeftLineCrossed( posX, posY, 0, createdUnit:getTemplateId() );
		end

	elseif posX == 10 and posY == 15 or
				 posX == 11 and posY == 16 or
				 posX == 10 and posY == 17 or
				 posX == 11 and posY == 14 or
				 posX == 12 and posY == 4	 or
				 posX == 12 and posY == 3  then
		if ScriptManager:getValue( "rubberboatTrigger" ) == 0 then
		playRubberboatCutscene( posX, posY, 0, createdUnit:getTemplateId() );
		end
	
	elseif	posX == 6 and posY == 40 or
					posX == 5 and posY == 39 or
					posX == 6 and posY == 38 or
					posX == 5 and posY == 37 then
		if ScriptManager:getValue("bridgeTrigger") == 0 then
		onEnterBridge( posX, posY, 0, createdUnit:getTemplateId() );
		end
	end
end


function onUnitunloaded()
			
	ScriptManager:removeTrigger( "onUnitunloaded" );
	
	for i = 1, #attackSquadOne do
	Utils:spawnUnitFromTable( attackSquadOne[i] );
	end
	

	local orderId = ScriptManager:addOrder( enemySquadIds.attackSquadOne, 17, 14, -1, 4, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );	
		
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY2_FLAVOR1, 5 );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY2_FLAVOR2, 4 );
						
		ScriptManager:startHighlightingGlobalAbilityMenu();	
		
		ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, GlobalAbility.MENU, "onGAmenuSelected", "onGAmenuSelected" );
		
		ScriptManager:moveCameraEx( 16, 26, 0.7, 2, true );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L1_3_SECONDARY2_FLAVOR3 ); 
		
		ScriptManager:moveCameraEx( 11, 23, 0.7, 3, true );
		
		ScriptManager:wait( 1 );
		
		ScriptManager:moveCameraEx( 3, 19, 0.7, 3, true );
		
		ScriptManager:wait( 1 );
		
		ScriptManager:dismissSubtitle();
		
		ScriptManager:moveCameraEx( 18, 14, 0.7, 3, true );

		Utils:endCutscene();
		
		Utils:setMissionStatus( missionIds.sendParatroopers, MissionStatus.IN_PROGRESS );
		
		ScriptManager:addOnDropUnitTrigger( GlobalAbility.PARATROOPER, 0, -1, -1, -1, "onParatrooperDropped", "onParatrooperDropped" );
end


function onGAmenuSelected()
	ScriptManager:removeTrigger( "onGAmenuSelected" );
	ScriptManager:stopHighlightingGlobalAbilityMenu();
	ScriptManager:wait(0.1)
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:startHighlightingGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:wait(0.1)
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, GlobalAbility.PARATROOPER, "onParatrooperButtonSelected", "onParatrooperButtonSelected" );
end


function onParatrooperButtonSelected()
	ScriptManager:removeTrigger( "onParatrooperButtonSelected" );
	ScriptManager:stopHighlightingGlobalAbilityButton( GlobalAbility.PARATROOPER );
end



function onParatrooperDropped()
	ScriptManager:removeTrigger( "onParatrooperDropped" );
	ScriptManager:wait( 1 );
	ScriptManager:setMissionStatus( missionIds.sendParatroopers, MissionStatus.ACCOMPLISHED );
end



function playRubberboatCutscene( tileX, tileY, playerId, unitTemplateId, unit, hasSmoke )--TODO

	if 	unitTemplateId ~= Units.L_PLANE_BOMBER and
			unitTemplateId ~= Units.L_PLANE_HEAVY and
			unitTemplateId ~= Units.L_PLANE_LIGHT and
			unitTemplateId ~= Units.L_PLANE_TRANSPORT then
				
		ScriptManager:removeTrigger( "playRubberboatCutscene" );
		ScriptManager:storeValue( "rubberboatTrigger", 1 );  

		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY1_FLAVOR1, 5 );
	
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY1_FLAVOR2, 4 );
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY1_FLAVOR3, 3 );
		
		ScriptManager:moveCameraEx( 18, 5, 0.7, 3, true );
		
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME, 17, 3, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 16, 3, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_MORTAR, 18, 3, -1 );
		ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_SNIPER, 19, 3, -1 );		
		
	Utils:endCutscene();
	
		ScriptManager:gainGold( 0, 150 );
	
	end
end


function onLeftLineCrossed( tileX, tileY, playerId, unitTemplateId, unit, hasSmoke )
	if 	unitTemplateId ~= Units.L_PLANE_BOMBER or
			unitTemplateId ~= Units.L_PLANE_HEAVY or
			unitTemplateId ~= Units.L_PLANE_LIGHT or
			unitTemplateId ~= Units.L_PLANE_TRANSPORT then
			
		ScriptManager:removeTrigger( "onLeftLineCrossed" );
		ScriptManager:storeValue( "leftLineTrigger", 1 ); 

		
		for i = 1, #leftTiles do
		Utils:spawnUnitFromTable( attackSquadTwo[i] );
		end
			
		local orderId = ScriptManager:addOrder( enemySquadIds.attackSquadTwo, 2, 17, -1, 4, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	end
end


function onEnterBridge( tileX, tileY, playerId, unitTemplateId, unit, hasSmoke  )
	if 	unitTemplateId ~= Units.L_PLANE_BOMBER or
			unitTemplateId ~= Units.L_PLANE_HEAVY or
			unitTemplateId ~= Units.L_PLANE_LIGHT or
			unitTemplateId ~= Units.L_PLANE_TRANSPORT then
	
		ScriptManager:removeTrigger( "onEnterBridge" );
		ScriptManager:storeValue( "bridgeTrigger", 1 ); 
	
	for i = 1, #bridgeTiles do
	Utils:spawnUnitFromTable( attackSquadThree[i] );
	end
		
		local orderId = ScriptManager:addOrder( enemySquadIds.attackSquadThree, 8, 38, -1, 4, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_ATTACK_ALL_IN_RANGE );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	end
end


function onAttackerHasAttacked( attackerUnit, isAoe , defenderUnit, defenderUnits, unitsHit )

	if attackerUnit:getSquadId() == enemySquadIds.attackSquadOne or
		 attackerUnit:getSquadId() == enemySquadIds.attackSquadTwo or
		 attackerUnit:getSquadId() == enemySquadIds.attackSquadThree then
		 
		 ScriptManager:removeTrigger( "onAttackerHasAttacked" );
		
		ScriptManager:runForPlayer( 0, "prepareAttackerCutscene" );
	end
end


function prepareAttackerCutscene()
	table.insert( queueTable, playAttackerCutscene );
	Utils:cutsceneQueue();
end


function playAttackerCutscene()

	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY3_FLAVOR1, 4 );
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_L1_3_SECONDARY3_FLAVOR2, 4 ); 
	
	Utils:endCutscene();
end



function onEnemyHQCaptured()
	ScriptManager:removeTrigger( "onEnemyHQCaptured" );
	ScriptManager:setMissionStatus( missionIds.captureHQ, MissionStatus.ACCOMPLISHED );

	checkForVictory()
end


function onEnemyOutpostCaptured()

	ScriptManager:removeTrigger( "onEnemyOutpostCaptured" );
	ScriptManager:setMissionStatus( missionIds.captureDestroyOutpost, MissionStatus.ACCOMPLISHED );
	
	checkForVictory()
end



function onAAhasAttacked( unit )
	
	ScriptManager:storeValue( "AAX", unit:getX() );
	ScriptManager:storeValue( "AAY", unit:getY() );
	
	ScriptManager:removeTrigger( "onAAsighted" );
	ScriptManager:removeTrigger( "onAAhasAttacked" );

	ScriptManager:runForPlayer( 0, "prepareAAcutscene" );
end
	
function prepareAAcutscene()
	table.insert( queueTable, playAAcutscene );
	Utils:cutsceneQueue();
end

function playAAcutscene()	

	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "AAX" ), ScriptManager:getValue( "AAY" ), 0.7, 2, true );
	
	ScriptManager:revealFogOfWar( ScriptManager:getValue( "AAX" ), ScriptManager:getValue( "AAY" ), 1, true );
	
	ScriptManager:wait( 0.5 );
	
	ScriptManager:showMarkerAt( ScriptManager:getValue( "AAX" ), ScriptManager:getValue( "AAY" ) );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY1_FLAVOR1, 7 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY1_FLAVOR2, 6 );
	
	ScriptManager:removeAllMarkers();
	
	ScriptManager:wait( 0.5 );
	
	ScriptManager:revealFogOfWar( ScriptManager:getValue( "AAX" ), ScriptManager:getValue( "AAY" ), 1, false );
	
	Utils:endCutscene();
		
	Utils:setMissionStatus( missionIds.destroyAntiAirs, MissionStatus.IN_PROGRESS );
end


function onAAsighted( discoveringUnit, discoveredUnit )

	ScriptManager:storeValue( "discoveredUnitX", discoveredUnit:getX() );
	ScriptManager:storeValue( "discoveredUnitY", discoveredUnit:getY() );
	
	ScriptManager:removeTrigger( "onAAsighted" );
	ScriptManager:removeTrigger( "onAAhasAttacked" );
	
	ScriptManager:runForPlayer( 0, "prepareAASightedCutscene" );
end

function prepareAASightedCutscene()
	table.insert( queueTable, playAAsightedCutscene );
	Utils:cutsceneQueue();
end

function playAAsightedCutscene()
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "discoveredUnitX" ), ScriptManager:getValue( "discoveredUnitY" ), 0.7, 2, true );
	
	ScriptManager:revealFogOfWar( ScriptManager:getValue( "discoveredUnitX" ), ScriptManager:getValue( "discoveredUnitY" ), 1, true );
	
	ScriptManager:wait( 0.5 );
	
	ScriptManager:showMarkerAt( ScriptManager:getValue( "discoveredUnitX" ), ScriptManager:getValue( "discoveredUnitY" ) );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY1_FLAVOR1, 7 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY1_FLAVOR2, 6 );
	
	ScriptManager:removeAllMarkers();
	
	ScriptManager:wait( 0.5 );
	
	ScriptManager:revealFogOfWar( ScriptManager:getValue( "discoveredUnitX" ), ScriptManager:getValue( "discoveredUnitY" ), 1, false );
	
	Utils:endCutscene();
		
	Utils:setMissionStatus( missionIds.destroyAntiAirs, MissionStatus.IN_PROGRESS );
end


function onAAdestroyed()
	Utils:incrementMissionProgress( missionIds.destroyAntiAirs );
	ScriptManager:runForPlayer( 0, "prepareAAmissionProgress" );
end

function prepareAAmissionProgress()
	table.insert( queueTable, showAAmissionProgress );
	Utils:cutsceneQueue();
end

function showAAmissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyAntiAirs )>= AAsToDestroy then

		ScriptManager:removeTrigger( "onAAdestroyed" );
		
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_SECONDARY1_FLAVOR3, 3 );
		
		Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_1, 3 ); 

		Utils:endCutscene();
		
		Utils:setMissionStatus( missionIds.destroyAntiAirs, MissionStatus.ACCOMPLISHED );
	
		else
		Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress( missionIds.destroyAntiAirs ), AAsToDestroy, Text.T_CAMP_L1_3_SECONDARY1_COUNTER );
		end
end




function onRiverEmplacementSighted( discoveringUnit, discoveredUnit )
	
	if 	discoveredUnit:getId() == riverEmplacement1 or
			discoveredUnit:getId() == riverEmplacement2 or
			discoveredUnit:getId() == riverEmplacement3 or
			discoveredUnit:getId() == riverEmplacement4 or
			discoveredUnit:getId() == riverEmplacement5 then
	
			ScriptManager:storeValue( "bunkerX", discoveredUnit:getX() );
			ScriptManager:storeValue( "bunkerY", discoveredUnit:getY() );
	
		ScriptManager:removeTrigger( "onRiverBunkerHasAttacked" );
		ScriptManager:removeTrigger( "onRiverEmplacementSighted" );
	
	ScriptManager:runForPlayer( 0, "prepareRiverBunkerCutscene" );	
	end
end


function onRiverBunkerHasAttacked( attacker )
	

	if 	attacker:getSquadId() == enemySquadIds.riverBunker1 or
			attacker:getSquadId() == enemySquadIds.riverBunker2 or
			attacker:getSquadId() == enemySquadIds.riverBunker3 or
			attacker:getSquadId() == enemySquadIds.riverBunker4 or
			attacker:getSquadId() == enemySquadIds.riverBunker5 then
	
		ScriptManager:removeTrigger( "onRiverBunkerHasAttacked" );
		ScriptManager:removeTrigger( "onRiverEmplacementSighted" );
		
		ScriptManager:storeValue( "bunkerX", attacker:getX() );
		ScriptManager:storeValue( "bunkerY", attacker:getY() );
	
	ScriptManager:runForPlayer( 0, "prepareRiverBunkerCutscene" );
	end
end
	

function prepareRiverBunkerCutscene()
	table.insert( queueTable, playRiverBunkerCutscene );
	Utils:cutsceneQueue();
end

	
function playRiverBunkerCutscene()
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "bunkerX" ), ScriptManager:getValue( "bunkerY" ), 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY3_FLAVOR1, 6 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY3_FLAVOR2, 5 );
	
	ScriptManager:moveCameraEx( 9, 20, 0.7, 2, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L1_3_PRIMARY3_FLAVOR3 );
	
	ScriptManager:moveCameraEx( 9, 28, 0.7, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:moveCameraEx( 5, 35, 0.7, 2, true );
	
	ScriptManager:wait( 2 );
	
	ScriptManager:dismissSubtitle();
	
	ScriptManager:moveCameraEx( 8, 19, 0.7, 3, true );
	
	Utils:endCutscene();
	
	ScriptManager:removeTrigger( "onRiverEmplacementSighted" );
	ScriptManager:removeTrigger( "onRiverBunkerHasAttacked" );
	
	-- when a riverbunker gets destroyed or cleared
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onRiverBunkerDestroyed", "onRiverBunkerDestroyed" );
	ScriptManager:addOnBunkerClearedTrigger( 1, -1, -1, "onRiverBunkerCleared", "onRiverBunkerCleared" );
	
	Utils:setMissionStatus( missionIds.destroyEmplacements, MissionStatus.IN_PROGRESS );
end


function onRiverBunkerDestroyed( unit )
	
	if 	unit:getSquadId() == enemySquadIds.riverBunker1 or
			unit:getSquadId() == enemySquadIds.riverBunker2 or
			unit:getSquadId() == enemySquadIds.riverBunker3 or
			unit:getSquadId() == enemySquadIds.riverBunker4 or
			unit:getSquadId() == enemySquadIds.riverBunker5 then
		
	Utils:incrementMissionProgress( missionIds.destroyEmplacements );
	
	ScriptManager:runForPlayer( 0, "prepareRiverBunkerProgress" );
	end
end


function onRiverBunkerCleared( flamethrower, bunker )

	
	if bunker:getSquadId() == enemySquadIds.riverBunker1 or
		bunker:getSquadId() == enemySquadIds.riverBunker2 or
		bunker:getSquadId() == enemySquadIds.riverBunker3 or
		bunker:getSquadId() == enemySquadIds.riverBunker4 or
		bunker:getSquadId() == enemySquadIds.riverBunker5 then
		
		Utils:incrementMissionProgress( missionIds.destroyEmplacements );
		ScriptManager:runForPlayer( 0, "prepareRiverBunkerProgress" );
	end
end


function prepareRiverBunkerProgress()
	
	table.insert( queueTable, showRiverBunkerProgress );
	Utils:cutsceneQueue();
end


function showRiverBunkerProgress()
	
	if ScriptManager:getMissionProgress( missionIds.destroyEmplacements ) >= riverBunkersToDestroy then
	
	ScriptManager:removeTrigger( "onRiverBunkerDestroyed" );
	ScriptManager:removeTrigger( "onRiverBunkerCleared" );
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_PRIMARY3_FLAVOR4, 5 );
	
	Utils:endCutscene();
	
	Utils:setMissionStatus( missionIds.destroyEmplacements, MissionStatus.ACCOMPLISHED );

	checkForVictory()

	else
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress( missionIds.destroyEmplacements), riverBunkersToDestroy, Text.T_CAMP_L1_3_PRIMARY3_COUNTER );
	end
end


function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.patrollingAA then
	Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, AApatrolTiles );
	end
end


function reduceAAactionPoints()

	local artillery1 = Unit:getUnitById( stationaryAA1 ):getId();
	if artillery1 ~= nil then
	Unit:getUnitById( stationaryAA1 ):setActionPoints( 0 );
	end

	local artillery2 = Unit:getUnitById( stationaryAA2 ):getId();
	if artillery2 ~= nil then
	Unit:getUnitById( stationaryAA2 ):setActionPoints( 0 );
	end
	
	local artillery3 = Unit:getUnitById( stationaryAA3 ):getId();
	if artillery3 ~= nil then
	Unit:getUnitById( stationaryAA3 ):setActionPoints( 0 );
	end
	
	local artillery4 = Unit:getUnitById( stationaryAA4 ):getId();
	if artillery4 ~= nil then	
	Unit:getUnitById( stationaryAA4 ):setActionPoints( 0 );
	end

	local artillery5 = Unit:getUnitById( stationaryAA5 ):getId();
	if artillery5 ~= nil then
	Unit:getUnitById( stationaryAA5 ):setActionPoints( 0 );
	end
	
	local artillery6 = Unit:getUnitById( stationaryAA6 ):getId();
	if artillery6 ~= nil then
	Unit:getUnitById( stationaryAA6 ):setActionPoints( 0 );
	end

	local artillery7 = Unit:getUnitById( stationaryAA7 ):getId();
	if artillery7 ~= nil then
	Unit:getUnitById( stationaryAA7 ):setActionPoints( 0 );
	end

	local artillery8 = Unit:getUnitById( stationaryAA8 ):getId();	
	if artillery8 ~= nil then
	Unit:getUnitById( stationaryAA8 ):setActionPoints( 0 );
	end
end


function setBalloonTurns()
	if playerBalloon ~= nil then
	Unit:getUnitById( playerBalloon ):setMaxPlaneTurns( -1 );
	Unit:getUnitById( playerBalloon ):setPlaneTurns( -1 );
	Unit:getUnitById( playerBalloon ):setIsAttackable(false);	
	end
end


-- END
-- BEGIN Victory


function checkForVictory()

	if	ScriptManager:getMissionStatus( missionIds.captureHQ ) 						== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.destroyEmplacements )	== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.captureDestroyOutpost )== MissionStatus.ACCOMPLISHED then
	
		startVictoryCutscene()
	end
end



function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_VICTORY_FLAVOR1, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_VICTORY_FLAVOR2, 3 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L1_3_VICTORY_FLAVOR3, 6 );
	
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



function showAttackedWarningAC( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_SHIP_AC );
end


function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.X_BUILDING_HQ );
end

function transitionToFail()
	ScriptManager:runForPlayer( 0, "missionFailed" );
end

function checkForEnd()
	if ScriptManager:noUnitsLeftExt( { 0, Units.N_MINE_LAND, Units.L_PLANE_SCOUT } ) then
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