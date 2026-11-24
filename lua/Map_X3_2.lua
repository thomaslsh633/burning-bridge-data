require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

--[[ story summary:
	player moves from the right side into the map with a few units, arrives at the outpost, gets some reinforcements ( intro cutscene )
	after moving through the village and some enemies they arrive near the central bridge that gets detonated before they can reach it
	they have to take a detour over the south bridge or take a huge risk in crossing the river with rubber boats
	they realize that there is a bigger enemy number stationed here than anticipated and this cant be good ( after getting attacked @ south factory / near coast with rubberboats
	a bigger enemy force makes its way towards the outpost and the player has to rush back to defend
	( if player manages to kill engineer that repairs bridge spawn a second or give the enemy smoke cover )
	after defending the outpost the radio units give them the hint towards the attack happening in mission 3
]]


-- mission stuff
missionIds = {
	catchUp			= 1,
	destroyRadio	= 2,
	defOutpost		= 3,
	capFactory		= 4,
	capRadio		= 5,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.catchUp,	 	true,	Text.T_CAMP_X3_2_PRIMARY1,		 75 },
	{ missionIds.destroyRadio,	true,	Text.T_CAMP_X3_2_PRIMARY2,		100 },
	{ missionIds.defOutpost, 	true,	Text.T_CAMP_X3_2_PRIMARY3,		125 },
	{ missionIds.capFactory, 	false,	Text.T_MISSION_CAP_FACOTRY,		 75 },
	{ missionIds.capRadio, 		false,	Text.T_CAMP_X3_2_SECONDARY2,	 75 },
};

enemySquadIds = {
	ruinedVillage	=  1,
	southVillage	=  2,
	southBridge		=  3,
	oldFactory		=  4,
	loneMgInfantry	=  5,
	artyS			=  6,
	artyN			=  7,
	city			=  8,
	mgNestN			=  9,
	mgNestM			= 10,
	mgNestS			= 11,
	radio			= 12,
	bridgeRepair	= 13,
	repairDef		= 14,
	alliedAttackers	= 15,
};

playerUnits = {
	{ Units.X_TRUCK_MG,		23, 15 },
	{ Units.X_INFANTRY_AT,	23 ,14 },
	{ Units.X_TANK_MEDIUM,	23 ,15 },
	{ Units.X_INFANTRY_MG,	23, 16 },
};

playerUnitsMovePos = { { 19, 13 }, { 20, 13 }, { 20, 14 }, { 20, 16 } };

playerReinforcements = {
	{ Units.X_INFANTRY_MG,	19, 15 },
	{ Units.X_TRUCK_SUPPLY,	21, 15 },
	{ Units.X_TANK_MEDIUM,	21 ,14 },
};

alliedAttackers = {
	{ Units.L_INFANTRY_MG,	0, 15 },
	{ Units.L_TANK_HEAVY,	0, 16 },
	{ Units.L_TANK_LIGHT,	0, 17 },
	{ Units.L_INFANTRY_AT,	1, 17 },
	{ Units.L_TRUCK_MG,		1, 16 },
	{ Units.L_TANK_LIGHT,	1, 15 },
	{ Units.L_INFANTRY_MG,	1, 14 },
};

artyIds			= {  5,  6 };
southBridgeIds	= { 20, 21 }

bridgeMaxHp			= 1200;
playerDepotId		=    3;
factoryId			=    2;
centreBridgeId		=    0;
radiosToDestroy 	=    3;
destroyedEngineers	=    0;
repairRoundCounter	=    0;
maxRepairRounds		=   10;
bridgeRepairId		=   33;

-- positions get revealed with radius 2 in enemy turn for the arty to have vision
fowRevealPos = { { 12, 19 }, { 9, 13 }, { 8, 6 } };


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1000 );
	
	ScriptManager:setInstantDestroyed(	centreBridgeId, true );
	--Utils:setCanBeCaptured(				centreBridgeId, false );
	
	ScriptManager:disableGlobalAbilityButton(	GlobalAbility.PARATROOPER );
	ScriptManager:enableGlobalAbilityButton(	GlobalAbility.PARATROOPER_NO_ENGI );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER_NO_ENGI );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	ScriptManager:disableInteractionButton( InteractionButton.DETONATE_BRIDGE );
	
	for i = 1, #artyIds do
		ScriptManager:disableComponent( artyIds[i], ComponentType.MOVEMENT, 0 );
	end
	
	Utils:setIsAttackable( factoryId, false );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "bridgeRepairId",		bridgeRepairId );
	ScriptManager:storeValue( "destroyedEngineers",	destroyedEngineers );
	ScriptManager:storeValue( "repairRoundCounter",	repairRoundCounter );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.X_BUILDING_HQ, -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.X_BUILDING_HQ, -1,	"transitionToFail",		"transitionToFail" );
	
	-- trigger for secondary intro
	ScriptManager:addOnTurnStartTrigger( 0, -1, 1, "startSecondaryIntroCutscene", "startSecondaryIntroCutscene" );
	
	-- trigger for catching up
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.N_EMPLACEMENT_MG_NEST,	-1,						 "crossRiverAttempt", "crossRiverAttempt" );
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_ARTILLERY_HOWITZER,	-1,						 "crossRiverAttempt", "crossRiverAttempt" );
	ScriptManager:addOnUnitSightedTrigger(		1, -1,							southBridgeIds[1], true, "crossRiverAttempt", "crossRiverAttempt" );
	ScriptManager:addOnUnitSightedTrigger(		1, -1,							southBridgeIds[2], true, "crossRiverAttempt", "crossRiverAttempt" );
	
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "showRiverArea", "riverReveal" );
	ScriptManager:addOnTurnEndTrigger(	 1, -1, -1, "hideRiverArea", "riverReveal" );
	
	--trigger for allied attackers
	--ScriptManager:addOnBridgeDetonateTrigger(	-1, -1, centreBridgeId, "onBridgeDestroyed", "onBridgeDestroyed" );
	--ScriptManager:addOnUnitDestroyedTrigger(	-1, -1, centreBridgeId, "onBridgeDestroyed", "onBridgeDestroyed" );
	
	--trigger for radio
	ScriptManager:addOnDropUnitTrigger( -1,						0, -1,	-1, -1, "gaNearRadio", "nearRadio" );
	ScriptManager:addOnSpawnUnitTrigger( GlobalAbility.BLIMB,	0,		-1, -1, "gaNearRadio", "nearRadio" );
	for x = 1, 5 do
		ScriptManager:addOnEnterTileTrigger(x, 15, 0, -1, -1, true, "nearRadio", "nearRadio" );
	end
	
	for y = 16, 22 do
		ScriptManager:addOnEnterTileTrigger( 5, y, 0, -1, -1, true, "nearRadio", "nearRadio" );
	end
	ScriptManager:addOnUnitCapturedTrigger(	 0, Units.L_TRUCK_RADIO, -1, "onRadioTruckCaptured",	"onRadioTruckCaptured" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_TRUCK_RADIO, -1, "onRadioTruckDestroyed",	"onRadioTruckDestroyed" );
	
	--trigger for the factory
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.N_BUILDING_TANKFACTORY, -1, "onFactoryCaptured", "onFactoryCaptured" );
	
	-- trigger for fallback ai orders
	ScriptManager:addOnAiCalculationTrigger( true, "fallbackAiOrders", "fallbackAiOrders" );
end

function loadValues()
	bridgeRepairId		= ScriptManager:getValue( "bridgeRepairId" );
	destroyedEngineers	= ScriptManager:getValue( "destroyedEngineers" );
	repairRoundCounter	= ScriptManager:getValue( "repairRoundCounter" );
end

function addAiOrders()
	ScriptManager:addOrder( enemySquadIds.artyN, 6, 19, -1, 6, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.artyS, 5, 11, -1, 6, AiOrder.DEFEND );
	ScriptManager:setAiAttackPriority( centreBridgeId, -100, false );
	
	ScriptManager:addOrder( enemySquadIds.mgNestN, 10, 21, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNestM,  7, 14, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.mgNestS,  5,  9, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.ruinedVillage,	13, 11, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southVillage,		13,  5, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.southBridge,		 8,  2, -1, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.loneMgInfantry,	 4, 11, -1, 1, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.city,				 2, 19, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.oldFactory, -1, -1, factoryId, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.oldFactory,  3,  3, -1,		 3, AiOrder.DEFEND );
end

function fallbackAiOrders( squadId, mainOrderData, allMainOrderData )
	local count = allMainOrderData:count();
	if squadId == enemySquadIds.oldFactory then
		if count <= 0 then
			ScriptManager:addOrder( squadId, -1, -1, factoryId,	3, AiOrder.DEFEND );
			ScriptManager:addOrder( squadId,  3,  3, -1,		3, AiOrder.DEFEND );
		end
	
	elseif squadId == enemySquadIds.repairDef then
		if count <= 0 then
			ScriptManager:addOrder( squadId, 9, 16, -1, 3, AiOrder.DEFEND );
		end
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR1 );
	Utils:antiRush();
	
	local unitId;
	for i = 1, #playerUnits do
		unitId = Utils:spawnUnitFromShortTable( 0, 0, playerUnits[i] );
		ScriptManager:moveUnitEx( unitId, playerUnitsMovePos[i][1], playerUnitsMovePos[i][2], true );
		Utils:antiRush();
	end
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_INTRO_FLAVOR2, 5 );
	ScriptManager:wait( 2 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR3 );
	Utils:antiRush();	
	ScriptManager:moveCameraEx( 2, 20, 0.7, 7, true );
	Utils:hideDialogue();
	ScriptManager:wait( 2 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR4 );
	ScriptManager:moveCameraEx( 20, 15, 0.7, 7, true );
	Utils:antiRush()
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR5 );
	ScriptManager:wait( 2 );
	
	for i = 1, #playerReinforcements do
		Utils:spawnUnitFromShortTable( 0, 0, playerReinforcements[i] );
		Utils:antiRush();
	end
	ScriptManager:wait( 2 );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.catchUp, MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.destroyRadio,	0, radiosToDestroy );
	Utils:setMissionProgress( missionIds.defOutpost,	0, #alliedAttackers );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	--ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.SHORTSIGHTED_GOD,		21, 15, 42 );
	
	--ScriptManager:spawnUnit( 0, Units.X_INFANTRY_AT, 		11, 5, 42 );
	--ScriptManager:spawnUnit( 0, Units.X_INFANTRY_AT, 		11,  3, 42 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end

function startSecondaryIntroCutscene()
	ScriptManager:removeTrigger( "startSecondaryIntroCutscene" );
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR6 );
	ScriptManager:moveCameraEx( 9, 15, 0.7, 3, true );
	ScriptManager:wait( 2 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_INTRO_FLAVOR7 );
	ScriptManager:moveCameraEx(  5,  3, 0.7, 5, true );
	ScriptManager:wait( 3 );
	ScriptManager:moveCameraEx( 20, 15, 0.7, 5, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.capFactory, MissionStatus.IN_PROGRESS );
end


-- END Intro Cutscene
-- BEGIN First Mission Part


function riverFowChange( reveal )
	for i = 1, #fowRevealPos do
		ScriptManager:revealFogOfWar( fowRevealPos[i][1], fowRevealPos[i][2], 3, reveal );
	end
end

function showRiverArea()
	riverFowChange( true );
end

function hideRiverArea()
	riverFowChange( false );
end

function crossRiverAttempt()
	ScriptManager:removeTrigger( "crossRiverAttempt" );
	
	ScriptManager:runForPlayer( 0, "prepareCrossRiverCutscene" );
end

function prepareCrossRiverCutscene()
	table.insert( queueTable, startCrossRiverCutscene );
	Utils:cutsceneQueue();
end

function startCrossRiverCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY1_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY1_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY1_FLAVOR3, 3 );
	
	Utils:endCutscene();
	
	ScriptManager:runForPlayer( 1, "bridgeRepairSquad" );
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "countdownToAttack", "countdownToAttack" );
end

function onFactoryCaptured()
	ScriptManager:removeTrigger( "onFactoryCaptured" );
	
	Utils:setMissionStatus( missionIds.capFactory, MissionStatus.ACCOMPLISHED );
end


-- END First Mission Part
-- BEGIN Engineer / Bridge Stuff


function bridgeRepairSquad()
	ScriptManager:removeAllOrders( enemySquadIds.bridgeRepair );
	ScriptManager:addOrder( enemySquadIds.bridgeRepair, 9, 15, -1, 1, AiOrder.MOVE );
	
	ScriptManager:removeAllOrders( enemySquadIds.repairDef );
	ScriptManager:addOrder( enemySquadIds.repairDef, -1, -1, bridgeRepairId, 1, AiOrder.DEFEND );
	--print( bridgeRepairId );
	
	ScriptManager:addOnEnterTileTrigger( 9, 16,  1, Units.L_INFANTRY_ENGINEER,	-1, true,	"startRepairing",		"startRepairing" );
	ScriptManager:addOnBridgeRepairTrigger(		-1, -1,							-1,			"onAiRepairedBridge",	"onAiRepairedBridge" );
	ScriptManager:addOnUnitDestroyedTrigger(	 1, Units.L_INFANTRY_ENGINEER,	-1,			"onEngineerDestroyed",	"onEngineerDestroyed" );
end

function startRepairing( tileX, tileY, playerId, unitTemplateId, unitId )
	ScriptManager:removeTrigger( "startRepairing" );
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "aiRepairBridge", "aiRepairBridge" );
end

function aiRepairBridge()
	local unit = Unit:getUnitAt( 9, 16 );
	
	if unit:getTemplateId() == Units.L_INFANTRY_ENGINEER then
		ScriptManager:repairBridge( unit:getId(), centreBridgeId, true );
	end
end

function onAiRepairedBridge( engineer, bridge )
	local bridgeHp = bridge:getHealth();

	--print( "REPAIR" );
	--print( bridgeHp );
	--print( ScriptManager:canSeeTile( 0, 10, 14 ) );

	if ( bridgeHp <= 300 and ( ScriptManager:canSeeTile( 0, 10, 14 ) or ScriptManager:canSeeTile( 0, 9, 15 ) ) ) or
		bridgeHp <= 900 then
		if ScriptManager:getMissionStatus( missionIds.catchUp ) ~= MissionStatus.ACCOMPLISHED then
			ScriptManager:runForPlayer( 0, "prepareAlliedAttackCutscene" );
		end
	
	elseif bridgeHp >= bridgeMaxHp then
		startAlliedAttack();
	end
end

function onEngineerDestroyed()
	destroyedEngineers = destroyedEngineers + 1;
	ScriptManager:storeValue( "destroyedEngineers", destroyedEngineers );
	
	if destroyedEngineers > 1 then
		-- dont try to repair bridge again, just spawn attackers
		startAlliedAttack();
	
	else
		ScriptManager:removeTrigger( "startRepairing" );
		ScriptManager:removeTrigger( "aiRepairBridge" );
		ScriptManager:removeTrigger( "onAiRepairedBridge" );
		ScriptManager:removeTrigger( "onEngineerDestroyed" );
		
		ScriptManager:runForPlayer( 1, "spawnNewEngineer" );
	end
end

function spawnNewEngineer()
	local unit = ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 1, 21, enemySquadIds.bridgeRepair );
	
	bridgeRepairId = unit:getId();
	ScriptManager:storeValue( "bridgeRepairId", bridgeRepairId );
	
	bridgeRepairSquad()
end


--END Engineer / Bridge Stuff
--BEGIN Allied Attack


function prepareAlliedAttackCutscene()
	table.insert( queueTable, startAlliedAttackCutscene );
	Utils:cutsceneQueue();
end

function startAlliedAttackCutscene()
	Utils:setMissionStatus( missionIds.catchUp, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR1 );
	ScriptManager:moveCameraEx( 9, 16, 0.7, 5, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR2 );
	Utils:markUnit( 9, 16, 1, 3, 0 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR3 );
	ScriptManager:moveCameraEx( 20, 15, 0.7, 4, true );
	Utils:markUnit( 20, 15, 1, 2, 0 );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR4, 5 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.defOutpost, MissionStatus.IN_PROGRESS );
end

function countdownToAttack()
	repairRoundCounter = repairRoundCounter + 1;
	ScriptManager:storeValue( "repairRoundCounter",repairRoundCounter );
	
	if repairRoundCounter >= maxRepairRounds then
		startAlliedAttack();
	end
end

function startAlliedAttack()
	ScriptManager:removeTrigger( "startRepairing" );
	ScriptManager:removeTrigger( "aiRepairBridge" );
	ScriptManager:removeTrigger( "onAiRepairedBridge" );
	ScriptManager:removeTrigger( "onEngineerDestroyed" );
	ScriptManager:removeTrigger( "countdownToAttack" );
	
	ScriptManager:removeAllOrders( enemySquadIds.bridgeRepair );
	ScriptManager:wait( 0.25 );
	ScriptManager:addOrder( enemySquadIds.bridgeRepair, 1, 22, -1, 1, AiOrder.MOVE );
	Utils:addOnEnterAreaTrigger( 1, 22, 1, 1, Units.L_INFANTRY_ENGINEER, -1, false, "removeEngineer", "removeEngineer" );
	
	for i = 1, #alliedAttackers do
		local unitId = Utils:spawnUnitFromShortTable( 1, enemySquadIds.alliedAttackers, alliedAttackers[i] );
		
		if i == 1 then
			ScriptManager:storeValue( "attackLeaderId", unitId );
		end
	end
	
	local bridge = Unit:getUnitById( centreBridgeId );
	if bridge:getPlayerId() == 0 then
		bridgeOrderForAlliedAttack()
	
	else
		local orderId = ScriptManager:addOrder( enemySquadIds.alliedAttackers, -1, -1, playerDepotId, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	end
	ScriptManager:addOrder( enemySquadIds.bridgeRepair, 9, 16, -1, 2, AiOrder.DEFEND );
	
	ScriptManager:removeAllOrders( enemySquadIds.repairDef );
	ScriptManager:wait( 0.25 );
	ScriptManager:addOrder( enemySquadIds.repairDef, 9, 16, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onEnemyDestroyed", "onEnemyDestroyed" );
	ScriptManager:addOnTurnStartTrigger( 0, -1, ScriptManager:getCurrentRound() + 2, "enableGa", "enableGa" );
end

function removeEngineer( tileX, tileY, playerId, unitTemplateId, unitId )
	ScriptManager:removeTrigger( "removeEngineer" );
	ScriptManager:runForPlayer( 0, "removeEngineerForReal" );
end

function removeEngineerForReal()
	ScriptManager:removeUnitEx( bridgeRepairId, true );
end

function bridgeOrderForAlliedAttack()
	ScriptManager:removeAllOrders( enemySquadIds.alliedAttackers );
	
	orderId = ScriptManager:addOrder( enemySquadIds.alliedAttackers, -1, -1, playerDepotId, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
end

function enableGa()
	ScriptManager:removeTrigger( "enableGa" );
	
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.PARATROOPER_NO_ENGI );
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:unblockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR5, 5 );
	
	Utils:endCutscene();
	
	ScriptManager:openGlobalAbilityMenu();
end

function onEnemyDestroyed( unit )
	local squadId = unit:getSquadId();
	
	if squadId == enemySquadIds.alliedAttackers then
		Utils:incrementMissionProgress( missionIds.defOutpost );
		ScriptManager:runForPlayer( 0, "prepareAttackerProgress" );
	end
end

function prepareAttackerProgress()
	table.insert( queueTable, showAttackerProgress );
	Utils:cutsceneQueue();
end

function showAttackerProgress()
	if ScriptManager:getMissionProgress( missionIds.defOutpost ) >= #alliedAttackers then
		ScriptManager:removeTrigger( "onEnemyDestroyed" );
		
		Utils:setMissionStatus( missionIds.defOutpost, MissionStatus.ACCOMPLISHED );
		checkForVictory();
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.defOutpost ), Text.T_CAMP_X3_2_PRIMARY3_COUNTER );
	end
end


--END Allied Attack
--BEGIN Radio Mission


function gaNearRadio( targetTileX, targetTileY, spawnedTileX, spawnedTileY, spawnedUnit )
	if	spawnedTileX <= 6 and spawnedTileY >= 15 then
		nearRadio( spawnedTileX, spawnedTileY );
	end
end

function nearRadio( tileX, tileY )
	ScriptManager:removeTrigger( "nearRadio" );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY2_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY2_FLAVOR2, 5 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionIds.destroyRadio, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.capRadio,	 MissionStatus.IN_PROGRESS );
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction()
end

function onRadioTruckCaptured()
	if ScriptManager:getMissionStatus( missionIds.capRadio ) ~= MissionStatus.ACCOMPLISHED then
		ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_SECONDARY2_FLAVOR1 );
		Utils:setMissionStatus( missionIds.capRadio, MissionStatus.ACCOMPLISHED );
		ScriptManager:wait( 2 );
		Utils:hideDialogue();
	end
	
	onRadioTruckDestroyed();
end

function onRadioTruckDestroyed()
	Utils:incrementMissionProgress( missionIds.destroyRadio );
	print( "+1" );
	
	ScriptManager:runForPlayer( 0, "prepareRadioTruckProgress" );
end

function prepareRadioTruckProgress()
	table.insert( queueTable, showRadioTruckProgress );
	Utils:cutsceneQueue();
end

function showRadioTruckProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyRadio ) >= radiosToDestroy then
		ScriptManager:removeTrigger( "onRadioTruckCaptured" );
		ScriptManager:removeTrigger( "onRadioTruckDestroyed" );
		Utils:setMissionStatus( missionIds.destroyRadio, MissionStatus.ACCOMPLISHED );
		checkForVictory();
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyRadio ), Text.T_CAMP_X3_2_PRIMARY2_COUNTER );
	end
end


-- END Radio Mission
-- BEGIN Victory


function checkForVictory()
	local attackerStatus = ScriptManager:getMissionStatus( missionIds.defOutpost );
	local radioStatus	 = ScriptManager:getMissionStatus( missionIds.destroyRadio );
	
	if attackerStatus == MissionStatus.ACCOMPLISHED and radioStatus ~= MissionStatus.ACCOMPLISHED then
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR6, 4 );
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR7, 4 );
		
		if ScriptManager:getMissionStatus( missionIds.destroyRadio ) == MissionStatus.NOT_STARTED then
			ScriptManager:removeTrigger( "nearRadio" );
			
			ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_PRIMARY3_FLAVOR8 );
			ScriptManager:moveCameraEx( 2, 20, 0.7, 5, true );
			Utils:hideDialogue();
			
			ScriptManager:displaySubtitle( Text.T_CAMP_X3_2_PRIMARY2_FLAVOR2 ); 
			ScriptManager:wait( 2 );
			ScriptManager:moveCameraEx( 20, 15, 0.7, 5, true );
			
			Utils:endCutscene();
			Utils:disablePlayerInteraction();
			
			ScriptManager:setMissionStatus( missionIds.destroyRadio, MissionStatus.IN_PROGRESS );
			ScriptManager:setMissionStatus( missionIds.capRadio,	 MissionStatus.IN_PROGRESS );
			ScriptManager:wait( 2 );
			
			Utils:enablePlayerInteraction()
			
		else
			Utils:endCutscene();
		end
	
	elseif attackerStatus ~= MissionStatus.ACCOMPLISHED and radioStatus == MissionStatus.ACCOMPLISHED then
		Utils:startCutscene()
		
		Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 3 );
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY2_FLAVOR3, 4 );
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_PRIMARY2_FLAVOR4, 5 );
		
		Utils:endCutscene();
	
	else
		startVictoryCutscene();
	end
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_VICTORY_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_VICTORY_FLAVOR2, 5 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_2_VICTORY_FLAVOR3, 5 );
	
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
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.X_BUILDING_HQ );
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