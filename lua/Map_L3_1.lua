require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	defendBase 		= 1,
	attackGustaf	= 2,
	captureBridge 	= 3,
	captureOutpost 	= 4,
	captureAirfield = 5,
	destroyBridge	= 6,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.defendBase,		true,	Text.T_CAMP_L3_1_PRIMARY1,	 50 },
	{ missionIds.captureBridge,		true,	Text.T_CAMP_L3_1_PRIMARY2,	 50 },
	{ missionIds.attackGustaf,		true,	Text.T_CAMP_L3_1_PRIMARY3,	100 },
	{ missionIds.destroyBridge,		false,	Text.T_CAMP_L3_1_SECONDARY1, 50 },
	{ missionIds.captureOutpost,	false,	Text.T_MISSION_CAP_BASE,	 50 },
	{ missionIds.captureAirfield,	false,	Text.T_MISSION_CAP_DESTROY_AIRFIELD, 50 },
};

enemySquadIds = {
	greatGustaf				=  1,
	gustafGuards			=  2,
	northernBridgeDefenders =  3,
	southernBridgeAttackers =  4,
	southernBridgeDefenders =  5,
	outpostDefenders		=  6,
	airfieldAmbush			=  7,
	airfieldDefender		=  8,
	southernPlane			=  9,
	northernPlane			= 10,
	easternBridgeDefenders	= 11, -- mgNest
	easternVillageDefender	= 12,
	sniper					= 13,
	mortar					= 14,
	tanks					= 15,
	southBridgeMgNest		= 16,
};

northernBridgeId = 0;
southernBridgeId = 1;
playerDepotID	 = 2;
outpostId		 = 3;

tank1 = 39;
tank2 = 58;
tank3 = 57;

planeWaveRespawnInterval = 3; -- respawn rate after previous spawn was destroyed;
northPlaneWaypoints = { { 21, 18 }, { 12, 21 }, { 4, 17 }, {  7,  4 }, { 15,  5 }, { 21, 4 }, };
southPlaneWaypoints = { { 15,  5 }, {  7,  4 }, { 4, 17 }, { 12, 21 }, { 21, 18 }, { 21, 4 }, };

-- neded to remove blocking units; posX, posY, number of tiles next to each other to remove
removeBlockersTable = {
--	{ 20, 19, 2 }, { 21, 20, 2 }, { 21, 21, 2 }, { 22, 22, 1 }, { 22, 23, 1 }; <- only use again if units around the tracks should be removed as well
	{ 21, 19 }, { 22, 20 }, { 22, 21 }, { 23, 22 },
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	addAiOrders();
	local unit = Unit:getUnitById( 22 );
	unit:setAttacksPerTurn( 0 );
	ScriptManager:gainGold( 0, 1500 );
	
	Utils:setIsAttackable( outpostId, false );
	ScriptManager:setAiAttackPriority( Units.N_BRIDGE_RAIL, 1, true ); -- hopefully prevents gustav from attacking player controlled north bridge
	
	local bridge = Unit:getUnitById( northernBridgeId );
	bridge:setCanBeCaptured( false );
	bridge:setHealth( 1000 );
	
	bridge = Unit:getUnitById( southernBridgeId );
	bridge:setIsAttackable( false );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_BUILDING_HQ , -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_BUILDING_HQ , -1,	"transitionToFail",		"transitionToFail" );
	
	-- destroying the northern bridge accomplishes missionIds.destroyBridge
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.N_BRIDGE_RAIL, -1, "northernBridgeDestroyed",		 "northernBridgeDestroyed" );
	ScriptManager:addOnUnitCapturedTrigger( 	 0, Units.N_BRIDGE_RAIL, -1, "northernBridgeCappedByPlayer", "northernBridgeCappedByPlayer" );
	
	-- spawn reinforcements when southern bridge got captured by the enemy
	ScriptManager:addOnTurnStartTrigger( 0, -1, -1, "onTurnStart", "onTurnStart" );
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BRIDGE_L, -1, "southernBridgeCaptured", "southernBridgeCaptured" );
	
	-- capturing the southern bridge accomplishes missionIds.captureBridge
	ScriptManager:addOnUnitCapturedTrigger(  0,Units.N_BRIDGE_L, southernBridgeId, "southernBridgeRecaptured",	"southernBridgeRecaptured" );
	ScriptManager:addOnBridgeRepairTrigger( -1,Units.N_BRIDGE_L, southernBridgeId, "southernBridgeRepaired",	"southernBridgeRecaptured" );
	
	-- missionIds.attckGustaf is being activated when he attacks
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_ARTILLERY_GUSTAF, -1, "gustafsInitialAttack", "gustafsInitialAttack");
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_ARTILLERY_GUSTAF, -1, "gustafAttacked",		 "gustafAttacked" );
	
	-- check if Gustav is relaoding
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	
	-- if Gustaf's health is below 500 HP missionIds.attackGustaf is accomplished
	ScriptManager:addOnUnitHasAttackedTrigger( -1, Units.X_ARTILLERY_GUSTAF, -1, "gustafReceivedDamage", "gustafReceivedDamage" );
	
	-- sighting the enemy outpost activates missionIds.captureOutpost
	ScriptManager:addOnUnitSightedTrigger( 1, Units.X_BUILDING_HQ, -1, true, "outpostSighted", "outpostSighted" );
	
	-- capturing the enemy outpost accomplishes missionIds.captureOutpost
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.X_BUILDING_HQ, -1, "outpostCaptured", "outpostCaptured" );
	
	-- sighting the airfield activates missionIds.captureAirfield <- also: plane attacks, cause reasons -fst
	ScriptManager:addOnUnitSightedTrigger( 		-1, Units.X_BUILDING_AIRFIELD,	-1, true,	"airfieldSighted", "airfieldSighted" );
	ScriptManager:addOnUnitHasAttackedTrigger(	-1, Units.X_PLANE_LIGHT,		-1,			"airfieldSighted", "airfieldSighted" );
	
	-- capturing the airfield accomplishes missionIds.captureAirfield <- remade the mission to cap or destroy, too lazy to rename stuff -fst
	ScriptManager:addOnUnitCapturedTrigger(	 0, Units.X_BUILDING_AIRFIELD, -1, "airfieldCaptured", "airfieldCaptured" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.X_BUILDING_AIRFIELD, -1, "airfieldCaptured", "airfieldCaptured" );
	
	-- trigger for wavespawn
	ScriptManager:addOnAiCalculationTrigger(	true,						 "checkWaypoints",		"checkWaypoints" );
	ScriptManager:addOnSquadDestroyedTrigger(	enemySquadIds.southernPlane, "waveSquadDestroyed",	"waveSquadDestroyed" );
	ScriptManager:addOnSquadDestroyedTrigger(	enemySquadIds.northernPlane, "waveSquadDestroyed",	"waveSquadDestroyed" );
	ScriptManager:addOnOrderDefendSupportTrigger( 							 "gustavSupport",		"gustavSupport" );
end

function addAiOrders()
	local orderId = ScriptManager:addOrder( enemySquadIds.southernBridgeAttackers, -1, -1, southernBridgeId, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	orderId = ScriptManager:addOrder( enemySquadIds.southernBridgeAttackers,	4, 16, -1, 3, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	-- heavy tanks that attack first
	orderId = ScriptManager:addOrder( enemySquadIds.tanks, 4, 16, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:addOrder( enemySquadIds.tanks,					 8, 20, -1, 1, AiOrder.ATTACK );
	ScriptManager:addOrder( enemySquadIds.tanks,					 4, 16, -1, 1, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.outpostDefenders,			-1, -1,  3, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.outpostDefenders,			15, 14, -1, 1, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.airfieldDefender,			-1, -1,  4, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.airfieldDefender,			22,  2, -1, 1, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.northernBridgeDefenders,	11, 20, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southernBridgeDefenders,	12,  4, -1, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.gustafGuards,				17, 19, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.airfieldAmbush,			18,  1, -1, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternBridgeDefenders,	19,  8, -1, 3, AiOrder.DEFEND );-- only 1 mgNest
	ScriptManager:addOrder( enemySquadIds.southBridgeMgNest,		11,  5, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.easternVillageDefender,	22, 12, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.sniper,					18, 13, -1, 1, AiOrder.DEFEND );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_INTRO_FLAVOR1 );
	ScriptManager:wait( 7 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx( 9, 20, 1, 3, true );
	
	ScriptManager:moveUnitEx(	tank1,  9, 20,	true );
	ScriptManager:moveUnitEx(	tank2, 10, 20,	true );
	ScriptManager:attackUnitEx(	tank1,tank3,	true );
	ScriptManager:attackUnitEx(	tank2,tank3,	true );
	Utils:hideDialogue()
	
	ScriptManager:moveCameraEx( 7, 19, 0.7, 5, false );
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_INTRO_FLAVOR3 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.defendBase,		MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.destroyBridge,	MissionStatus.IN_PROGRESS );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		2, 18, 42 );
	--ScriptManager:spawnUnit( 0, Units.L_ARTILLERY_AA, 		21, 19, 42 );
	--ScriptManager:spawnUnit( 0, Units.L_ARTILLERY_AA, 		22, 20, 42 );
	--ScriptManager:spawnUnit( 0, Units.L_ARTILLERY_AA, 		22, 21, 42 );
	--ScriptManager:spawnUnit( 0, Units.L_TANK_DESTROYER,		23, 22, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
end

function removeSquads()
	--Utils:removeSquad(  );
	ScriptManager:removeUnitEx( 18, false );
	ScriptManager:removeUnitEx( 19, false );
	ScriptManager:removeUnitEx( 20, false );
	ScriptManager:removeUnitEx( 21, false );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN


function northernBridgeDestroyed()
	ScriptManager:removeTrigger( "northernBridgeDestroyed" );
	ScriptManager:removeTrigger( "northernBridgeCappedByPlayer" );
	Utils:setMissionStatus( missionIds.destroyBridge, MissionStatus.ACCOMPLISHED );
	
	-- send them on a quest for revenge to attack the enemy deopt ( cause they have nothing to defend anymore
	ScriptManager:removeAllOrders( enemySquadIds.northernBridgeDefenders );
	local orderId = ScriptManager:addOrder( enemySquadIds.northernBridgeDefenders, -1, -1, playerDepotID, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end

function northernBridgeCappedByPlayer()
	-- dont remove trigger, cause when player recaptures i can renew the orders
	ScriptManager:removeAllOrders( enemySquadIds.northernBridgeDefenders );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.northernBridgeDefenders, -1, -1, northernBridgeId, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	ScriptManager:addOrder( enemySquadIds.northernBridgeDefenders, 11, 20, -1, 3, AiOrder.DEFEND );
end

function onTurnStart()
	local bridge = Unit:getUnitById( southernBridgeId );
	if bridge:getPlayerId() == 1 then
		ScriptManager:removeTrigger( "onTurnStart" );
		prepareSouthernBridgeCapturedCutscene();
	end
end

function prepareSouthernBridgeCapturedCutscene()
	table.insert( queueTable, southernBridgeCapturedCutscene );
	Utils:cutsceneQueue();
end

function southernBridgeCapturedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY2_FLAVOR1 );
	ScriptManager:moveCameraEx( 9, 4, 0.7, 3, true );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY2_FLAVOR2 );
	ScriptManager:moveCameraEx( 6, 12, 0.5, 3, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY2_FLAVOR3 );
	ScriptManager:moveCameraEx( 3, 20, 0.7, 1, false );
	
	local unit = ScriptManager:spawnUnit( 0, Units.L_TANK_MEDIUM, 0, 23, -1 );
	local unitId = unit:getId();
	ScriptManager:moveUnitEx( unitId, 3, 22, true );
	
	unit = ScriptManager:spawnUnitWithTransporter( 0, Units.L_TRUCK_TRANSPORT, Units.L_INFANTRY_FLAME, 0, 23, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_AT,	 0, 23, -1 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_MORTAR, 0, 23, -1 );
	
	unitId = unit:getId();
	ScriptManager:moveUnitEx( unitId, 2, 23, true );
	
	unit = ScriptManager:spawnUnit( 0, Units.L_TRUCK_AA, 0, 23, -1 );
	unitId = unit:getId();
	ScriptManager:moveUnitEx( unitId, 1, 23, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY2_FLAVOR4 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.captureBridge, MissionStatus.IN_PROGRESS );
	
	local gustaf = ScriptManager:spawnUnit( 1, Units.X_ARTILLERY_GUSTAF, 19, 18, enemySquadIds.greatGustaf );
	ScriptManager:rotateUnit( gustaf:getId(), FaceDirection.EAST );
	ScriptManager:storeValue( "gustafId", gustaf:getId() );
	
	ScriptManager:addOrder( enemySquadIds.greatGustaf, 19, 18, -1, 15, AiOrder.DEFEND );
	gustaf:setAllowCounterAttack( false );
	gustaf:setCanBeCaptured( false );
	
	ScriptManager:addOnAirstrikeTrigger( GlobalAbility.AIRSTRIKE, 0, -1, -1, "gustafReceivedDamage", "gustafReceivedDamage" );
	
	ScriptManager:spawnUnit( 1, Units.X_PLANE_SCOUT, 6, 16, -1 );
	
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.PARATROOPER );
end

function southernBridgeRecaptured()
	ScriptManager:removeTrigger( "southernBridgeRecaptured" );
	Utils:setMissionStatus( missionIds.captureBridge, MissionStatus.ACCOMPLISHED );
	checkForVictory();
end

function southernBridgeRepaired( repairer, bridge )
	local bridgeHealth = bridge:getHealth();
	
	if bridgeHealth >= 1200 then
		southernBridgeRecaptured();
	end
end

function gustafAttacked()
	ScriptManager:storeValue( "gustafAttacked", 1 );
end

function onEnemyTurnStart()
	if ScriptManager:getMissionStatus( missionIds.captureBridge ) == 0 then
		ScriptManager:blockInteractionButton( GlobalAbility.PARATROOPER );
		
	else
		ScriptManager:enableInteractionButton( GlobalAbility.PARATROOPER );
	end
	
	if ScriptManager:getValue( "gustafAttacked" ) == 1 then
		local gustaf = Unit:getUnitById( ScriptManager:getValue( "gustafId" ) );
		gustaf:setAttacksPerTurn( 0 );
		ScriptManager:storeValue( "gustafAttacked", 0 );
	end
end

function gustafsInitialAttack( unit, isAoe, defenderUnit, defenderUnits, unitsHit )
	ScriptManager:removeTrigger( "gustafsInitialAttack" );
	--print( defenderUnit );
	--print( defenderUnit:getX())
	local gustaf = Unit:getUnitById( ScriptManager:getValue( "gustafId" ) );
	
	ScriptManager:storeValue( "gustafX",		gustaf:getX() );
	ScriptManager:storeValue( "gustafY",		gustaf:getY() );
	ScriptManager:storeValue( "defenderUnitX",	defenderUnit:getX() );
	ScriptManager:storeValue( "defenderUnitY",	defenderUnit:getY() );
	
	ScriptManager:runForPlayer( 0, "prepareGustafAttackedCutscene" );
end

function prepareGustafAttackedCutscene()
	table.insert( queueTable, gustafAttackedCutscene );
	Utils:cutsceneQueue();
end

function gustafAttackedCutscene()
	local gustafX = ScriptManager:getValue( "gustafX" );
	local gustafY = ScriptManager:getValue( "gustafY" );
	
	Utils:startCutscene()
	
	ScriptManager:moveCameraEx(			gustafX, gustafY, 1, 2,	true );
	ScriptManager:revealFogOfWar(		gustafX, gustafY, 1,	true );
	ScriptManager:showScaledMarkerAt(	gustafX, gustafY, 1.5,	true, true );
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY3_FLAVOR1 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY3_FLAVOR2 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_PRIMARY3_FLAVOR3 );
	ScriptManager:wait( 5 );
	
	ScriptManager:revealFogOfWar( gustafX, gustafY, 1, false );
	Utils:hideAllMarkers();
	Utils:hideDialogue();
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "defenderUnitX" ), ScriptManager:getValue( "defenderUnitY" ), 0.7, 1, true );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.attackGustaf,MissionStatus.IN_PROGRESS );
end

function gustafReceivedDamage()
	local gustaf = Unit:getUnitById( ScriptManager:getValue( "gustafId" ) );
	if gustaf:getHealth() < 500 then
		ScriptManager:storeValue( "gustafX", gustaf:getX() );
		ScriptManager:storeValue( "gustafY", gustaf:getY() );
		ScriptManager:runForPlayer( 0, "prepareGustafEscapeCutscene" );
	end
end

function prepareGustafEscapeCutscene()
	table.insert( queueTable, gustafEscapeCutscene );
	Utils:cutsceneQueue();
end

function gustafEscapeCutscene()
	Utils:startCutscene()
	
	local gustavX = ScriptManager:getValue( "gustafX" );
	local gustavY = ScriptManager:getValue( "gustafY" );
	ScriptManager:moveCameraEx( gustavX, gustavY, 0.7, 1, true );
	
	local mortar = ScriptManager:spawnUnit( 1, Units.X_ARTILLERY_MORTAR, 21, 22, enemySquadIds.mortar );
	local mortarId = mortar:getId();
	mortar:setAttacksPerTurn( 2 );
	
	ScriptManager:smokeTile( mortarId, 22, 21, true );
	Utils:antiRush();
	ScriptManager:smokeTile( mortarId, 20, 18, true );
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_VICTORY_FLAVOR1 );
	calculateEscapeRoute( ScriptManager:getValue( "gustafId" ), gustavX, gustavY, 21 )
	--ScriptManager:removeUnitEx( ScriptManager:getValue( "gustafId" ), true );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_VICTORY_FLAVOR2 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.attackGustaf, MissionStatus.ACCOMPLISHED );
	
	checkForVictory()
end

function calculateEscapeRoute( gustavId, gustavX, gustavY, escapeX )
	local unitFound = false;
	for i = gustavX + 2, escapeX do
		local unit = Unit:getUnitAt( i, gustavY );
		-- blocking unit was found!
		if unit ~= nil then
			unitFound = true;
			
			-- move gustav if the found unit is not directly in front of it
			if i ~= gustavX + 2 then
				local moveX = i - 2;
				ScriptManager:moveCameraEx(			moveX, gustavY, 0.7, 1, false );
				ScriptManager:moveUnitEx( gustavId, moveX, gustavY,			true );
			end
			
			-- remove the blocking unit and save current gustav pos for next search
			ScriptManager:removeUnitEx( unit:getId(), true );
		end
	end
	
	-- all obstacles in front of gustav are gone move the final bit towards the escape
	ScriptManager:moveCameraEx(			escapeX - 1, gustavY, 0.7, 2,	false );
	ScriptManager:moveUnitEx( gustavId, escapeX - 1, gustavY,			true );
	ScriptManager:wait( 1 );
	
	--[[ removes units on the tracks and next to them, not sure if needed, but i think its too punishing for the player if he has units there
	so i only remove the ones on the track now ( for loop i use atm )
	local x, y, unit;
	for i = 1, #removeBlockersTable do
		x = removeBlockersTable[i][1];
		y = removeBlockersTable[i][2];
		for j = 0, removeBlockersTable[i][3] do
			unit = Unit:getUnitAt( x + j, y );
			
			if unit ~= nil then
				ScriptManager:removeUnitEx( unit:getId(), true );
				ScriptManager:wait( 0.5 );
			end
		end
	end]]
	
	for i = 1, #removeBlockersTable do
		local unit = Unit:getUnitAt( removeBlockersTable[i][1], removeBlockersTable[i][2] );
		
		if unit ~= nil then
			ScriptManager:removeUnitEx( unit:getId(), true );
			ScriptManager:wait( 0.5 );
		end
	end
	
	ScriptManager:removeUnitEx( gustavId, true );
end


function outpostSighted( seeingUnit, outpost )
	ScriptManager:removeTrigger( "outpostSighted" );
	
	ScriptManager:storeValue( "seeingUnitX", seeingUnit:getX() );
	ScriptManager:storeValue( "seeingUnitY", seeingUnit:getY() );
	
	table.insert( queueTable, outpostSightedCutscene );
	Utils:cutsceneQueue();
end

function outpostSightedCutscene()
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 15, 4, 1, 1, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_SECONDARY2_FLAVOR1 );
	
	ScriptManager:showMarkerAt( 15, 4 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_SECONDARY2_FLAVOR2 );
	ScriptManager:wait( 5 );
	ScriptManager:hideMarkerAt( 15, 4 );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "seeingUnitX" ), ScriptManager:getValue( "seeingUnitY" ), 0.7, 1, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.captureOutpost, MissionStatus.IN_PROGRESS );
end

function outpostCaptured()
	ScriptManager:removeTrigger( "outpostDestroyed" );
	
	Utils:setMissionStatus( missionIds.captureOutpost, MissionStatus.ACCOMPLISHED );
end

function waveSquadDestroyed( squadId )
	local nextSpawnRound = ScriptManager:getCurrentRound() + planeWaveRespawnInterval;
	-- old wave squad was destroyed, prepare spawn for next
	if squadId == enemySquadIds.northernPlane then
		ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewNorthPlane", "spawnNewNorthPlane" );
	
	elseif squadId == enemySquadIds.southernPlane then
		ScriptManager:addOnTurnStartTrigger( 1, -1, nextSpawnRound, "spawnNewSouthPlane", "spawnNewSouthPlane" );
	end
end

function spawnNewNorthPlane()
	ScriptManager:removeTrigger( "spawnNewNorthPlane" );
	spawnNewWave( 22, 3, enemySquadIds.northernPlane );
end

function spawnNewSouthPlane()
	ScriptManager:removeTrigger( "spawnNewSouthPlane" );
	spawnNewWave( 21, 3, enemySquadIds.southernPlane );
end

function spawnNewWave( spawnX, spawnY, squadId )
	if ScriptManager:getMissionStatus( missionIds.captureAirfield ) ~= MissionStatus.ACCOMPLISHED then
		ScriptManager:spawnUnit( 1, Units.X_PLANE_LIGHT, spawnX, spawnY, squadId );
	end
end

function checkWaypoints( squadId, mainOrderData, allMainOrderData )
	if squadId == enemySquadIds.northernPlane then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, northPlaneWaypoints );
	
	elseif squadId == enemySquadIds.southernPlane then
		Utils:checkWaypoints( squadId, mainOrderData, allMainOrderData, southPlaneWaypoints );
	end
end

function gustavSupport( squadId, unitId, defPosX, defPosY, radius )
	if  squadId == enemySquadIds.greatGustaf or
		squadId == enemySquadIds.gustafGuards then
		newOrder( enemySquadIds.southernPlane, defPosX, defPosY, radius );
		newOrder( enemySquadIds.northernPlane, defPosX, defPosY, radius );
	end
end

function newOrder( squadId, posX, posY, radius )
	ScriptManager:removeAllOrders( squadId );
	ScriptManager:addOrder( squadId, posX, posY, -1, radius, AiOrder.DEFEND );
end

function airfieldSighted( seeingUnit, Airfield )
	ScriptManager:removeTrigger( "airfieldSighted" );
	
	ScriptManager:storeValue( "seeingUnitX", seeingUnit:getX() );
	ScriptManager:storeValue( "seeingUnitY", seeingUnit:getY() );
	
	ScriptManager:runForPlayer( 0 , "prepareAirfieldCutscene" );
end

function prepareAirfieldCutscene()
	table.insert( queueTable, airfieldSightedCutscene );
	Utils:cutsceneQueue();
end

function airfieldSightedCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_SECONDARY3_FLAVOR1 );
	ScriptManager:moveCameraEx( 21, 3, 1, 4, true );
	
	ScriptManager:revealFogOfWar( 22, 2, 1, true );
	ScriptManager:showMarkerAt( 22, 2 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_SECONDARY3_FLAVOR2 );
	ScriptManager:wait( 3 );
	ScriptManager:hideMarkerAt(		22, 2 );
	ScriptManager:revealFogOfWar(	22, 2, 1, false );
	
	ScriptManager:moveCameraEx( ScriptManager:getValue( "seeingUnitX" ), ScriptManager:getValue( "seeingUnitY" ), 0.7, 4, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.captureAirfield, MissionStatus.IN_PROGRESS );
end

function airfieldCaptured()
	ScriptManager:removeTrigger( "waveSquadDestroyed" );
	
	Utils:setMissionStatus( missionIds.captureAirfield, MissionStatus.ACCOMPLISHED );
	ScriptManager:gainGold( 0, 500 );
end

function checkForVictory()
	if	ScriptManager:getMissionStatus( missionIds.captureBridge )	== MissionStatus.ACCOMPLISHED and
		ScriptManager:getMissionStatus( missionIds.attackGustaf )	== MissionStatus.ACCOMPLISHED then
		Utils:setMissionStatus( missionIds.defendBase, MissionStatus.ACCOMPLISHED );
		prepareVictoryCutscene();
	end
end

function prepareVictoryCutscene()
	table.insert( queueTable, startVictoryCutscene );
	Utils:cutsceneQueue();
end


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L3_1_VICTORY_FLAVOR3 );
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


function showAttackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_BUILDING_HQ );
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