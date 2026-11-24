require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


ENEMY_ARTILLERY_HOWITZER_ONE_UNIT_ID = 38;
ENEMY_ARTILLERY_HOWITZER_TWO_UNIT_ID = 41;
ENEMY_ARTILLERY_HOWITZER_THREE_UNIT_ID = 42;
ENEMY_ARTILLERY_HOWITZER_FOUR_UNIT_ID = 44;

ENEMY_SUPPLY_CRATE_ONE_UNIT_ID = 7;
ENEMY_SUPPLY_CRATE_TWO_UNIT_ID = 6;
ENEMY_SUPPLY_CRATE_THREE_UNIT_ID = 4;
ENEMY_SUPPLY_CRATE_FOUR_UNIT_ID = 5;

ROUND_OF_ENEMY_ARTILLERY_ATTACK_INIT = 1;

-- mission stuff
missionIds = {
		recaptureRailroadBridge = 1,
		keepBridgesIntact 	= 2,
		defeatParatroopers 	= 3,
		destroySuppliers 		= 4,
		destroyArtillery	  = 5,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.recaptureRailroadBridge,	true,	Text.T_CAMP_X_2_2_PRIMARY1,	50 },
	{missionIds.keepBridgesIntact,				true,	Text.T_CAMP_X_2_2_PRIMARY2,	50 },
	{missionIds.defeatParatroopers,			true,	Text.T_CAMP_X_2_2_PRIMARY3,	 125 },
	{missionIds.destroySuppliers,				false,Text.T_CAMP_X_2_2_SECONDARY1,	 75 },
	{missionIds.destroyArtillery,				false,Text.T_CAMP_X_2_2_SECONDARY2,	 25 },
};

supplyPatrol1Tiles = { { 20, 2 }, { 9, 4 }, { 1, 22 } };
supplyPatrol2Tiles = { { 4, 1 }, { 12, 2 }, { 19, 2 }};

waypointTablePlanes1 = { { 7, 17 }, { 10, 23 }, { 14, 23 } }; -- attack bridge, towncenter, airfield
waypointTablePlanes2 = { { 11, 11 }, { 17, 13 }, { 13, 26 } }; -- riverbank, railbridge, HQ
waypointTablePlanes3 = { { 18, 15 }, { 16, 22 }, { 14, 26 } }; -- railbridge, airfield, HQ


enemySquadIds = {

paratroopers1 = 1;
paratroopers2 = 2;
paratroopers3 = 3;
paratroopers4 = 4;
paratroopers5 = 5;

heavyUnits1 = 6;
heavyUnits2 = 7;
heavyUnits3 = 8;
heavyUnits4 = 9;
heavyUnits5 = 10;

artillery1 = 11;
artillery2 = 12;
artillery3 = 13;
artillery4 = 14;

truck1 = 16;
truck2 = 17;
truck3 = 18;
truck4 = 19;
truck5 = 20;

supplyPatrol1 = 21;
supplyPatrol2 = 22;
supplyCrates = 23;

enemyStartUnits1 = 24;
enemyStartUnits2 = 25;

supplyDefenders1 = 26;
supplyDefenders2 = 27;
supplyDefenders3 = 28;
supplyDefenders4 = 29;
supplyDefenders5 = 30;

supplytruck = 31;

enemyStartUnits3 = 32;

planes1 = 50;
planes2 = 51;
planes3 = 52;

};

unitRespawnInterval = 0;
unitSpawnInProgress = 0;

paratroopers1 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_INFANTRY_MG,				 1, 22, 	enemySquadIds.paratroopers1 };
	{ 1, Units.L_INFANTRY_SNIPER, 	 1, 23, 	enemySquadIds.paratroopers1 };
	{ 1, Units.L_INFANTRY_AT, 			 1, 24, 	enemySquadIds.paratroopers1 };
	};

paratroopers2 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_INFANTRY_MG, 				1, 17, 		enemySquadIds.paratroopers2 };
	{ 1, Units.L_INFANTRY_MG,					1, 18,		enemySquadIds.paratroopers2 };
	{ 1, Units.L_INFANTRY_MORTAR, 		1, 19,	 	enemySquadIds.paratroopers2 };
	};

paratroopers3 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_INFANTRY_MG,				  3, 1, 	enemySquadIds.paratroopers3 };
	{ 1, Units.L_INFANTRY_SNIPER, 		4, 1, 	enemySquadIds.paratroopers3 };
	{ 1, Units.L_INFANTRY_FLAME, 			5, 1, 	enemySquadIds.paratroopers3 };
	};
	
paratroopers4 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_INFANTRY_MG, 			12, 1, 	enemySquadIds.paratroopers4 };
	{ 1, Units.L_INFANTRY_AT,				12, 2, 	enemySquadIds.paratroopers4 };
	{ 1, Units.L_INFANTRY_SNIPER, 	13, 2, 	enemySquadIds.paratroopers4 };
	};
	
paratroopers5 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_INFANTRY_SNIPER, 	20, 7, 	enemySquadIds.paratroopers5 };
	{ 1, Units.L_INFANTRY_MG,				20, 8, 	enemySquadIds.paratroopers5 };
	{ 1, Units.L_INFANTRY_MG, 			20, 9, 	enemySquadIds.paratroopers5 };
	};


heavyUnits1 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_TANK_LIGHT, 				12, 1, 	enemySquadIds.heavyUnits1 };
	{ 1, Units.L_TANK_MEDIUM, 			12, 2, 	enemySquadIds.heavyUnits1 };
	{ 1, Units.L_TRUCK_MG,		 			13, 2, 	enemySquadIds.heavyUnits1 };
};

heavyUnits2 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_TANK_LIGHT, 				3, 1, 	enemySquadIds.heavyUnits2 };
	{ 1, Units.L_TANK_HEAVY, 				4, 1, 	enemySquadIds.heavyUnits2 };
};

heavyUnits3 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_TANK_MEDIUM, 			1, 22, 	enemySquadIds.heavyUnits3 };
	{ 1, Units.L_TANK_HEAVY, 				1, 23, 	enemySquadIds.heavyUnits3 };
};

heavyUnits4 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_TRUCK_MG, 				20, 1, 	enemySquadIds.heavyUnits4 };
	{ 1, Units.L_TANK_DESTROYER, 	19, 1, 	enemySquadIds.heavyUnits4 };
};

heavyUnits5 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_TRUCK_AA, 				12, 1, 	enemySquadIds.heavyUnits5 };
	{ 1, Units.L_TRUCK_MG, 				12, 2, 	enemySquadIds.heavyUnits5 };
};


-- Units of the plane wave spawn

planeWaveRespawnInterval = 2; -- defines how often waves will spawn
planeWaveInProgress = 0;

planes1 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_PLANE_LIGHT, 				1, 18, 	enemySquadIds.planes1 };
	{ 1, Units.L_PLANE_BOMBER, 				1, 19, 	enemySquadIds.planes1 };
};

planes2 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_PLANE_HEAVY, 				1, 2, 	enemySquadIds.planes2 };
	{ 1, Units.L_PLANE_BOMBER, 				1, 1, 	enemySquadIds.planes2 };
};

planes3 = {-- playerId, unitTemplateId, tileX, tileY, squadId
	{ 1, Units.L_PLANE_LIGHT, 				20, 6, 	enemySquadIds.planes3 };
	{ 1, Units.L_PLANE_HEAVY, 				20, 7, 	enemySquadIds.planes3 };
};


playerBridge = 0;
playerRailroadBridge = 1;

playerHQ = 3;
playerAirfield = 2;

supplyCrates1 = 5;
supplyCrates2 = 4;
supplyCrates3 = 6;
supplyCrates4 = 7;

MGatBridge = 19;

supplyUnitsToDestroy = 4;
artilleriesToDestroy = 4;
paratroopersToKill = 25;


paratrooperIdStart = 200;
paratrooperInc = 0;

enemyArtilleryDestroyed = 0;

-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:setAiAttackPriority( Units.N_BRIDGE_L, 1, true );
	ScriptManager:setAiAttackPriority( Units.N_BRIDGE_RAIL, 1, true );
	
	if(Unit:getUnitById(ENEMY_SUPPLY_CRATE_ONE_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_SUPPLY_CRATE_ONE_UNIT_ID):setSupplyLoad(Unit:getUnitById(ENEMY_SUPPLY_CRATE_ONE_UNIT_ID):getSupplyLoad() * 0.2);
	end
	
	if(Unit:getUnitById(ENEMY_SUPPLY_CRATE_TWO_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_SUPPLY_CRATE_TWO_UNIT_ID):setSupplyLoad(Unit:getUnitById(ENEMY_SUPPLY_CRATE_TWO_UNIT_ID):getSupplyLoad() * 0.2);
	end
	
	if(Unit:getUnitById(ENEMY_SUPPLY_CRATE_THREE_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_SUPPLY_CRATE_THREE_UNIT_ID):setSupplyLoad(Unit:getUnitById(ENEMY_SUPPLY_CRATE_THREE_UNIT_ID):getSupplyLoad() * 0.2);
	end
	
	if(Unit:getUnitById(ENEMY_SUPPLY_CRATE_FOUR_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_SUPPLY_CRATE_FOUR_UNIT_ID):setSupplyLoad(Unit:getUnitById(ENEMY_SUPPLY_CRATE_FOUR_UNIT_ID):getSupplyLoad() * 0.2);
	end

	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("enemyArtilleryDestroyed", enemyArtilleryDestroyed);
end

function loadValues()
	enemyArtilleryDestroyed = ScriptManager:getValue("enemyArtilleryDestroyed");
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planes1, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planes2, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.planes3, "waveSquadPlaneDestroyed", "waveSquadPlaneDestroyed" );
	

	-- paratroopers and heavy units spawning
	ScriptManager:addOnTurnStartTrigger( 1, -1, 2, "startUnitSpawn", "startUnitSpawn" );

	ScriptManager:addOnTurnStartTrigger(1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	
	-- if one of the bridges get destroyed
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_BRIDGE_RAIL, 1, "transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.N_BRIDGE_M, 0, "transitionToFail", "transitionToFail" );
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.X_BUILDING_HQ, -1,	"showAttackedWarning",	"showAttackedWarning" );
--	ScriptManager:addOnUnitHasAttackedTrigger(	0, , -1,	"stopAttackingHint",	"stopAttackingHint" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.X_BUILDING_HQ, playerHQ,	"transitionToFail",		"transitionToFail" );
	
	-- when the railroadbridge is recaptured
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BRIDGE_RAIL, 1, "onRailBridgeCaptured", "onRailBridgeCaptured" );
	
	-- when the enemy captures the bridge
--	ScriptManager:addOnUnitCapturedTrigger( 1, Units.N_BRIDGE_L, playerBridge, "onBridgeCapturedByEnemy", "onBridgeCapturedByEnemy" );
	
	-- when the enemy captures the bridge / when the player captureds the bridge
--	ScriptManager:addOnUnitCapturedTrigger( -1, Units.N_BRIDGE_M, playerBridge, "transitionToFail", "transitionToFail" );
	ScriptManager:addOnUnitCapturedTrigger( -1, Units.N_BRIDGE_M, playerBridge, "checkForVictory", "checkForVictory" );
	
	
	-- when enemy artillery is destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_ARTILLERY_HOWITZER, -1, "onArtilleryDestroyed", "onArtilleryDestroyed" ); 
	
	-- when a paratrooper gets destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onParatrooperDestroyed", "onParatrooperDestroyed" );
	
	-- when a squad gets destroyed
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.paratroopers1, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.paratroopers2, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.paratroopers3, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.paratroopers4, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.paratroopers5, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );

	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.heavyUnits1, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.heavyUnits2, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.heavyUnits3, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.heavyUnits4, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger( enemySquadIds.heavyUnits5, "onEnemySquadDestroyed", "onEnemySquadDestroyed" );
						
	
	-- when the enemy supplies get destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.N_BUILDING_CRATES, -1, "onSupplyUnitDestroyed", "onSupplyUnitDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_TRUCK_SUPPLY, -1, "onSupplyUnitDestroyed", "onSupplyUnitDestroyed" );
	
	ScriptManager:addOnUnitSightedTrigger( 1, Units.N_BUILDING_CRATES, -1, true, "onCratesSighted", "onCratesSighted" );
	
	-- patrolling supply trucks
	ScriptManager:addOnAiCalculationTrigger( true, "checkWaypoints", "checkWaypoints" );
end

function onEnemyTurnStart(playerId, turnId, roundId)
	if(roundId == ROUND_OF_ENEMY_ARTILLERY_ATTACK_INIT) then
		initEnemyArtillery();
		ScriptManager:runForPlayer(0, "prepareArtilleryCutscene");
	end
	
	setEnemyArtilleryActionPointsToZero();
end

function setEnemyArtilleryActionPointsToZero()
	if(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_ONE_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_ONE_UNIT_ID):setActionPoints(0);
	end
	
	if(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_TWO_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_TWO_UNIT_ID):setActionPoints(0);
	end
	
	if(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_THREE_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_THREE_UNIT_ID):setActionPoints(0);
	end
	
	if(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_FOUR_UNIT_ID) ~= nil) then
		Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_FOUR_UNIT_ID):setActionPoints(0);
	end
end


function onArtilleryDestroyed()
	incrementEnemyArtilleryDestroyed();
	Utils:incrementMissionProgress(missionIds.destroyArtillery);
	ScriptManager:runForPlayer(0, "prepareArtilleryDestroyedProgress");
end

function addAiOrders()
	local aiRadiusArty = 6;
	local aiRadiusNormal = 3;
	
	ScriptManager:addOrder( enemySquadIds.supplyDefenders1, 2, 22, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.supplyDefenders2, 3, 11, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.supplyDefenders3, 10, 1, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.supplyDefenders4, 18, 6, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.truck1, 4, 22, -1, aiRadiusNormal, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.truck2, 9, 13, -1, aiRadiusNormal, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.truck3, 14, 9, -1, aiRadiusNormal, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.truck4, 19, 10, -1, aiRadiusNormal, AiOrder.DEFEND );
	
end

function initEnemyArtillery()
	local aiRadiusArty = 6;
	
	ScriptManager:addOrder(enemySquadIds.artillery1, 4, 22, -1, aiRadiusArty, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.artillery2, 9, 13, -1, aiRadiusArty, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.artillery3, 14, 9, -1, aiRadiusArty, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.artillery4, 19, 10, -1, aiRadiusArty, AiOrder.DEFEND);
end

-- END Init
-- BEGIN Intro Cutscene


function incrementParatrooperId()
	paratrooperInc = paratrooperInc + 1;
	ScriptManager:storeValue( "paratrooperInc", paratrooperInc );
end


function startIntroCutscene()
	Utils:startCutscene();
	
	
	ScriptManager:moveCameraEx( 9, 4, 0.7, 2, true );
	ScriptManager:revealFogOfWar( 9, 4, 2, true );
		
	local MG = ScriptManager:runAbility( 1, Units.L_INFANTRY_MG, paratrooperIdStart + paratrooperInc, GlobalAbility.PARATROOPER, 9, 4, enemySquadIds.enemyStartUnits1 );
	incrementParatrooperId();
	ScriptManager:wait( 3 );
	
	local MORTAR = ScriptManager:runAbility( 1, Units.L_INFANTRY_MORTAR, paratrooperIdStart + paratrooperInc, GlobalAbility.PARATROOPER, 9, 3, enemySquadIds.enemyStartUnits1 );
	incrementParatrooperId();
	ScriptManager:wait( 3 );
	
	local AT = ScriptManager:runAbility( 1, Units.L_INFANTRY_AT, paratrooperIdStart + paratrooperInc, GlobalAbility.PARATROOPER, 8, 3, enemySquadIds.enemyStartUnits1 );
	incrementParatrooperId();
	ScriptManager:wait( 3 );
	
	local MG2 = ScriptManager:runAbility( 1, Units.L_INFANTRY_MG, paratrooperIdStart + paratrooperInc, GlobalAbility.PARATROOPER, 8, 4, enemySquadIds.enemyStartUnits1 );
	incrementParatrooperId();
	ScriptManager:wait( 3 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_2_INTRO_FLAVOR1, 5 );		
	
			
	ScriptManager:moveCameraEx( 18, 14, 0.7, 2, true );
	ScriptManager:revealFogOfWar( 18, 14, 3, true );


	ScriptManager:runAbility( 1, -1, -1, GlobalAbility.AIRSTRIKE, 17, 14, -1 );

	ScriptManager:wait( 1 );

	local tank = ScriptManager:spawnUnit( 1, Units.L_TANK_HEAVY, 20, 9, enemySquadIds.enemyStartUnits3 ):getId();
	ScriptManager:moveUnitEx( tank, 20, 14, true );
	ScriptManager:wait( 1 );
	ScriptManager:attackUnitEx( tank, Unit:getUnitAt( 17, 14 ):getId(), true );
	
	local tank2 = ScriptManager:spawnUnit( 1, Units.L_TANK_DESTROYER, 20, 10, enemySquadIds.enemyStartUnits2 ):getId();
	ScriptManager:moveUnitEx( tank2, 19, 15, true );
	ScriptManager:fortifyUnit( tank2, true );
	
	local sniper = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_SNIPER, 19, 10, enemySquadIds.enemyStartUnits2 ):getId();
	ScriptManager:moveUnitEx( sniper, 19, 13, true );
	ScriptManager:fortifyUnit( sniper, true );
			
	ScriptManager:attackUnitEx( sniper, MGatBridge, true );
	
	ScriptManager:captureUnitEx( sniper, playerRailroadBridge, true );

	local MGtruck = ScriptManager:spawnUnit( 1, Units.L_TRUCK_MG, 20, 13, enemySquadIds.enemyStartUnits3 ):getId();
	ScriptManager:moveUnitEx( MGtruck, 16, 13, true );	

	ScriptManager:moveUnitEx( tank, 17, 14, true );

	ScriptManager:fortifyUnit( tank, true );

	local mediumTank = ScriptManager:spawnUnit( 1, Units.L_TANK_MEDIUM, 20, 13, enemySquadIds.enemyStartUnits2 ):getId();
	ScriptManager:moveUnitEx( mediumTank, 19, 14, true );
	ScriptManager:fortifyUnit( mediumTank, true );
	

	
	local AA = ScriptManager:spawnUnit( 1, Units.L_TRUCK_AA, 20, 11, enemySquadIds.enemyStartUnits2 ):getId();
	ScriptManager:moveUnitEx( AA, 20, 14, true );
	ScriptManager:wait( 0.5 );
	ScriptManager:fortifyUnit( AA, true );		
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_2_INTRO_FLAVOR2, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_2_INTRO_FLAVOR3, 7 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_2_INTRO_FLAVOR4, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X_2_2_INTRO_FLAVOR5, 5 );
	
	ScriptManager:moveCameraEx( 13, 24, 0.7, 2, true );
	
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_FLAME, 11, 25, -1 );
	ScriptManager:spawnUnit( 0, Units.X_INFANTRY_MG, 13, 25, -1 );
	
	ScriptManager:revealFogOfWar( 9, 4, 2, false );
	ScriptManager:revealFogOfWar( 18, 14, 3, false );
	
	local bridge = Unit:getUnitById( playerRailroadBridge )
	bridge:setHealth( 600 );
	
	Utils:endCutscene();
	
	ScriptManager:wait( 1 );
--	Utils:disablePlayerInteraction();

	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits1, 8, 17, -1, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits2, 19, 14, -1, 2, AiOrder.DEFEND );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits3, -1, -1, playerHQ, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.recaptureRailroadBridge, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.keepBridgesIntact, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.defeatParatroopers, MissionStatus.IN_PROGRESS );
		
	-- start the plane  wave
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval;
	ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );
	
--	Utils:enablePlayerInteraction();
	
	-- when the enemy captures a bridge
	ScriptManager:addOnUnitCapturedTrigger( 1, Units.N_BRIDGE_RAIL, -1, "onRailBridgeCapturedByEnemy", "onRailBridgeCapturedByEnemy" );
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BRIDGE_RAIL, -1, "onRailBridgeCapturedByPlayer", "onRailBridgeCapturedByPlayer" );
	
	
	ScriptManager:addOnUnitCapturedTrigger( 1, Units.N_BRIDGE_M, -1, "onBridgeCapturedByEnemy", "onBridgeCapturedByEnemy" );
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BRIDGE_M, -1, "onBridgeCapturedByPlayer", "onBridgeCapturedByPlayer" );
	
	
	ScriptManager:spawnUnit( 1, Units.L_TRUCK_AA, 7, 2, enemySquadIds.supplyDefenders5 )
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_MG, 8, 2, enemySquadIds.supplyDefenders5 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_AT, 8, 3, enemySquadIds.supplyDefenders5 );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.supplyDefenders5, 7, 3, -1, 3, AiOrder.DEFEND );
	local	orderId = ScriptManager:addOrder( enemySquadIds.supplytruck, -1, -1, -1, 2, AiOrder.DEFEND );

	
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


function prepareArtilleryCutscene()
	table.insert( queueTable, startArtilleryCutscene );
	Utils:cutsceneQueue();
end

function startArtilleryCutscene()
	local artX, artY = 9, 13;
	local currentId = -1;
	
	if(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_TWO_UNIT_ID) ~= nil) then
		currentId = ENEMY_ARTILLERY_HOWITZER_TWO_UNIT_ID;
	elseif(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_THREE_UNIT_ID) ~= nil) then
		currentId = ENEMY_ARTILLERY_HOWITZER_THREE_UNIT_ID;
	elseif(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_FOUR_UNIT_ID) ~= nil) then
		currentId = ENEMY_ARTILLERY_HOWITZER_FOUR_UNIT_ID;
	elseif(Unit:getUnitById(ENEMY_ARTILLERY_HOWITZER_ONE_UNIT_ID) ~= nil) then
		currentId = ENEMY_ARTILLERY_HOWITZER_ONE_UNIT_ID;
	end
	
	if(currentId ~= -1) then
		artX, artY = Unit:getUnitById(currentId):getX(), Unit:getUnitById(currentId):getY();
	end
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(artX, artY, 0.7, 3, true);
	ScriptManager:revealFogOfWar(artX, artY, 1, true);
	ScriptManager:showMarkerAt(artX, artY);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X2_2_SECONDARY3_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X2_2_SECONDARY3_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X2_2_SECONDARY3_FLAVOR3, 4);
	
	Utils:endCutscene();
	
	ScriptManager:revealFogOfWar(artX, artY, 1, false)
	Utils:hideAllMarkers() ;
	
	Utils:endCutscene();
	
	Utils:setMissionStatus(missionIds.destroyArtillery, MissionStatus.IN_PROGRESS);
	ScriptManager:setMissionProgress(missionIds.destroyArtillery, getEnemyArtilleryDestroyed());
end


function prepareArtilleryDestroyedProgress()
	table.insert(queueTable, showArtilleryDestroyedProgress);
	Utils:cutsceneQueue();
end


function showArtilleryDestroyedProgress()
	if(ScriptManager:getMissionProgress(missionIds.destroyArtillery) >= artilleriesToDestroy) then
		ScriptManager:removeTrigger("onArtilleryDestroyed");
		ScriptManager:removeTrigger("onEnemyTurnStart");
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_SECONDARY3_FLAVOR4, 3 );
		
		Utils:endCutscene();
		
		Utils:setMissionStatus( missionIds.destroyArtillery, MissionStatus.ACCOMPLISHED );
	else
		Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress( missionIds.destroyArtillery), artilleriesToDestroy, Text.T_CAMP_X2_2_SECONDARY1_COUNTER ) --TODO
	end
end


function onRailBridgeCaptured()
	ScriptManager:removeTrigger( "onRailBridgeCaptured" );
	Utils:setMissionStatus( missionIds.recaptureRailroadBridge, MissionStatus.ACCOMPLISHED );

	checkForVictory();
	
	ScriptManager:runForPlayer( 0, "prepareRailBridgeCutscene" );
end


function prepareRailBridgeCutscene()
	table.insert( queueTable, playRailBridgeCapturedCutscene );
	Utils:cutsceneQueue();
end


function playRailBridgeCapturedCutscene()
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 18, 14, 0.7, 2, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY1_FLAVOR1, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY1_FLAVOR2, 4 );
	
	Utils:endCutscene();

	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits2, -1,-1, playerRailroadBridge, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
  
end


function onEnemySquadDestroyed()
	startUnitSpawn()	
end


function onParatrooperDestroyed(unit)
	if(unit:getTemplateId() ~= Units.N_BUILDING_CRATES) and
		(unit:getTemplateId() ~= Units.L_TRUCK_SUPPLY) then
		Utils:incrementMissionProgress(missionIds.defeatParatroopers);
		
		if(ScriptManager:getMissionProgress(missionIds.defeatParatroopers) >= paratroopersToKill) then
			ScriptManager:removeTrigger("onParatrooperDestroyed");
			
			ScriptManager:runForPlayer(0, "prepareParatrooperMissionFinished");
		elseif(ScriptManager:getMissionProgress(missionIds.defeatParatroopers) == 5) then
			if(ScriptManager:getMissionStatus( missionIds.destroySuppliers ) ~= MissionStatus.IN_PROGRESS) then
				ScriptManager:removeTrigger("onCratesSighted");
				
				ScriptManager:runForPlayer( 0, "prepareSupplierCutscene");
			end
		else--if(ScriptManager:getMissionProgress(missionIds.defeatParatroopers) ~= 5) then
			ScriptManager:runForPlayer(0, "updateParaTropperMissionProgress");
		end
		
	end
end

function updateParaTropperMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.defeatParatroopers), paratroopersToKill, Text.T_CAMP_X2_2_PRIMARY3_COUNTER);
end

function prepareParatrooperMissionFinished()
	table.insert(queueTable, playParatrooperDefeatedCutscene);
	Utils:cutsceneQueue();
end


function playParatrooperDefeatedCutscene()
	Utils:setMissionStatus( missionIds.defeatParatroopers, MissionStatus.ACCOMPLISHED );
	
	Utils:startCutscene()
			
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY2_FLAVOR1, 6 );
			
	Utils:endCutscene();
		
	checkForVictory();
end


function onCratesSighted( discoveringUnit, discoveredUnit )
		
	print("STAGE1")
	
	if discoveredUnit:getId() == supplyCrates1 or
	   discoveredUnit:getId() == supplyCrates2 or
	   discoveredUnit:getId() == supplyCrates3 or
	   discoveredUnit:getId() == supplyCrates4 then
	
		print("STAGE2")
		 		
		ScriptManager:removeTrigger( "onCratesSighted" );
		ScriptManager:runForPlayer( 0, "prepareSupplierCutscene" );
	end
end

function prepareSupplierCutscene()
	table.insert( queueTable, playSupplierCutscene );
	Utils:cutsceneQueue();
end

function playSupplierCutscene()

	if ScriptManager:getMissionStatus( missionIds.destroySuppliers ) ~= MissionStatus.IN_PROGRESS and
		 ScriptManager:getMissionStatus( missionIds.destroySuppliers ) ~= MissionStatus.ACCOMPLISHED then 
			
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY4_FLAVOR1, 4 );
	
	ScriptManager:moveCameraEx( 18, 6, 0.7, 3, true );
	ScriptManager:revealFogOfWar( 18, 6, 1, true );
	ScriptManager:showMarkerAt( 18, 6 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY4_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY4_FLAVOR3, 5 );
	
	Utils:endCutscene();
	
	ScriptManager:revealFogOfWar( 18, 6, 1, false );
	Utils:hideAllMarkers();
	
	Utils:setMissionStatus( missionIds.destroySuppliers, MissionStatus.IN_PROGRESS );
	end
end



function onRailBridgeCapturedByEnemy( capturingUnit, capturedUnit )

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers5, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits1, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits4, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end


function onRailBridgeCapturedByPlayer( capturingUnit, capturedUnit )

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers5, -1, -1, playerRailroadBridge, 3, AiOrder.ATTACK ); -- tries to capture the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits1, -1, -1, playerRailroadBridge, 3, AiOrder.ATTACK ); -- tries to capture the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits4, -1, -1, playerRailroadBridge, 3, AiOrder.ATTACK ); -- tries to capture the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
end



function onBridgeCapturedByEnemy( capturingUnit, capturedUnit )

	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits1, 13, 26, -1, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers2, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers3, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits2, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits3, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits5, 13, 26, -1, 3, AiOrder.ATTACK ); -- attack HQ
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end


function onBridgeCapturedByPlayer( capturingUnit, capturedUnit )

	local orderId = ScriptManager:addOrder( enemySquadIds.enemyStartUnits1, 8, 17, -1, 2, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE ); 

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers2, 8, 17, -1, 3, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers3, 8, 17, -1, 3, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits2, 8, 17, -1, 3, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits3, 8, 17, -1, 3, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits5, 8, 17, -1, 3, AiOrder.ATTACK ); -- tries to capture to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
end



function onSupplyUnitDestroyed()
	Utils:incrementMissionProgress( missionIds.destroySuppliers );
	ScriptManager:runForPlayer( 0, "prepareSupplierMissionProgress" );
end
	
	
function prepareSupplierMissionProgress()
	table.insert( queueTable,showSupplierMissionProgress );
	Utils:cutsceneQueue();
end	


function showSupplierMissionProgress()
	if ScriptManager:getMissionProgress( missionIds.destroySuppliers ) >= supplyUnitsToDestroy then
		ScriptManager:removeTrigger( "onSupplyUnitDestroyed" );
		Utils:setMissionStatus( missionIds.destroySuppliers, MissionStatus.ACCOMPLISHED );
		
		
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_PRIMARY4_FLAVOR4, 5 );
		
		Utils:endCutscene();
	
	else
		Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress( missionIds.destroySuppliers ), supplyUnitsToDestroy, Text.T_CAMP_X2_2_PRIMARY4_COUNTER );
	end
end



function startUnitSpawn()

--	paratrooperSpawn = 1;

	-- find a wave to spawn by random number
		local rnd = math.random ( 0, 10 );
		local spawnTable = 0;
		
		print("RND1: %i", rnd);
		
	if rnd == 0 then
	spawnTable = paratroopers1
	
	elseif rnd == 1 then
	spawnTable = paratroopers2
	
	elseif rnd == 2 then
	spawnTable = paratroopers3
	
	elseif rnd == 4 then
	spawnTable = paratroopers4
	
	elseif rnd == 5 then
	spawnTable = paratroopers5
	
	elseif rnd == 6 then
	spawnTable = heavyUnits1
	
	elseif rnd == 7 then
	spawnTable = heavyUnits2
	
	elseif rnd == 8 then
	spawnTable = heavyUnits3
	
	elseif rnd == 9 then
	spawnTable = heavyUnits4
	
	elseif rnd == 10 then
	spawnTable = heavyUnits5
	end

	for i = 1, #spawnTable do
	Utils:spawnUnitFromTable( spawnTable[i] );
	end
	
	-- paratrooper orders
	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers1, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers2, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers3, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers4, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.paratroopers5, 20, 14, -1, 3, AiOrder.ATTACK ); -- moves to the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );


	-- heavy units orders
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits1, 20, 14, -1, 3, AiOrder.ATTACK ); -- moves to the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits2, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits3, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits4, 20, 14, -1, 3, AiOrder.ATTACK ); -- moves to the railroadbridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.heavyUnits5, 7, 15, -1, 3, AiOrder.ATTACK ); -- moves to the bridge
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );

end



function spawnPlaneWave()
	
	planeWaveInProgress = 1;
	ScriptManager:removeTrigger( "spawnPlaneWave" ); 
	
	   -- find a wave to spawn by random number
	local rnd = math.random ( 0, 2 );
  local spawnTable = 0;
  
  print("RND2: %i", rnd);

  
  if rnd == 0 then
  spawnTable = planes1
  
  elseif rnd == 1 then
  spawnTable = planes2
  
  elseif rnd == 2 then
  spawnTable = planes3
  end
  
  for i = 1, #spawnTable do
    Utils:spawnUnitFromTable( spawnTable[i] );
  end 

	local orderId = ScriptManager:addOrder( enemySquadIds.planes1, -1, -1, playerHQ, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.planes2, -1, -1, playerAirfield, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.planes3, -1, -1, playerHQ, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	

end
	

function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.supplyPatrol1 then
	Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, supplyPatrol1Tiles );
	end
	
	if squadId == enemySquadIds.supplyPatrol2 then
	Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, supplyPatrol2Tiles );
	end	
	
	if squadId == enemySquadIds.planes1 then
	Utils:checkWaypoints(squadId,mainOrderData,allMainOrderData, waypointTablePlanes1 )
	end
	
	if squadId == enemySquadIds.planes1 then
	Utils:checkWaypoints(squadId,mainOrderData,allMainOrderData, waypointTablePlanes2 )
	end	

	if squadId == enemySquadIds.planes1 then
	Utils:checkWaypoints(squadId,mainOrderData,allMainOrderData, waypointTablePlanes3 )
	end
end


function waveSquadPlaneDestroyed()
	if planeWaveInProgress == 1 then
	-- old wave was destroyed, prepare spawn for the next round
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval
    ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnPlaneWave", "spawnPlaneWave" );  
  end
end



function checkForVictory()
	if 	ScriptManager:getMissionStatus( missionIds.recaptureRailroadBridge ) 	== MissionStatus.ACCOMPLISHED and
			ScriptManager:getMissionStatus( missionIds.defeatParatroopers ) 			== MissionStatus.ACCOMPLISHED then
			
			ScriptManager:wait( 2 );
			
			
			if Unit:getUnitById( playerBridge ):getPlayerId() == 0 then
		
			Utils:missionCheckerAccomplish( missionIds.keepBridgesIntact );
		
			ScriptManager:wait( 2 );
		
			startVictoryCutscene()
			end

	end
end

-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 8, 17, 0.7, 3, true );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_VICTORY_FLAVOR1, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_VICTORY_FLAVOR2, 4 );
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X2_2_VICTORY_FLAVOR3, 4 );
	
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

function getEnemyArtilleryDestroyed()
	return enemyArtilleryDestroyed;
end

function setEnemyArtilleryDestroyed(value)
	enemyArtilleryDestroyed = value;
	
	ScriptManager:storeValue("enemyArtilleryDestroyed", enemyArtilleryDestroyed);
end

function incrementEnemyArtilleryDestroyed()
	setEnemyArtilleryDestroyed(getEnemyArtilleryDestroyed() + 1);
end
-- END Defeated