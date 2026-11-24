require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	repairBridge		= 1,
	defendBridge		= 2,
	repairBase			= 3, -- also: cap it
	defendBase			= 4,
	defeatAttackers		= 5,
	keepBunkers			= 6, -- fail temporarily when leaving them!
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.repairBridge,		true,	Text.T_CAMP_L5_2_PRIMARY1,		100 },
	{ missionIds.defendBridge,		true,	Text.T_CAMP_L5_2_PRIMARY2,		125 },
	{ missionIds.repairBase,		true,	Text.T_CAMP_L5_2_PRIMARY3,		100 },
	{ missionIds.defendBase,		true,	Text.T_CAMP_L5_2_PRIMARY4,		150 },
	{ missionIds.defeatAttackers,	true,	Text.T_CAMP_L5_2_PRIMARY5,		150 },
	{ missionIds.keepBunkers,		false,	Text.T_CAMP_L5_2_SECONDARY1,	125 },
};

enemySquadIds = {
	eastVillage		=  1,
	eastVillageMg	=  2,
	baseDef			=  3,
	baseEast		=  4,
	wave1W			=  5,
	wave1S			=  6,
	wave1NE			=  7,
	wave2W			=  8,
	wave2S			=  9,
	wave2NE			= 10,
	wave3W			= 11,
	wave3S			= 12,
	wave3NE			= 13,
	wave4W			= 14,
	wave4S			= 15,
	wave4NE			= 16,
	wave5W			= 17,
	wave5S			= 18,
	wave5NE			= 19,
};

bridgeId	=    0;
baseId		=    3;
bridgeMaxHp	= 1200;
baseMaxHp	= 1200;

bunkersToOccupy	= 4;

showProgress	 =  0;
attackStartRound = -1;
enemiesDestroyed =  0; -- for partial xp

spawnPosW	= { {  1, 14 }, {  1, 12 }, {  1, 13 }, {  0, 13 }, {  0, 12 } };
spawnPosS	= { { 23,  2 }, { 24,  2 }, { 22,  1 }, { 23,  1 }, { 24,  1 } };
spawnPosNE	= { { 23, 23 }, { 22, 24 }, { 22, 23 }, { 23, 24 }, { 24, 24 } };

nextSquadW	= enemySquadIds.wave1W;
nextSquadS	= enemySquadIds.wave1S;
nextSquadNE	= enemySquadIds.wave1NE;

enemyWave1 = { Units.X_INFANTRY_MG,	Units.X_INFANTRY_AT,	Units.X_INFANTRY_AT, };
enemyWave2 = { Units.X_INFANTRY_MG,	Units.X_TANK_DESTROYER, };
enemyWave3 = { Units.X_INFANTRY_MG,	Units.X_INFANTRY_AT,	Units.X_TANK_MEDIUM, };
enemyWave4 = { Units.X_INFANTRY_MG,	Units.X_INFANTRY_AT,	Units.X_TRUCK_MG, };


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:disableInteractionButton( InteractionButton.TRANSFORM );
	ScriptManager:setInstantDestroyed( bridgeId, true );
	
	local base = Unit:getUnitById( baseId );
	base:setHealth( 200 );
	base:setSupplyLoad( 0 );
	base:setIsAttackable( false );
	
	ScriptManager:gainGold( 0, 1500 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "attackStartRound",	attackStartRound );
	ScriptManager:storeValue( "nextSquadW",			nextSquadW );
	ScriptManager:storeValue( "nextSquadS",			nextSquadS );
	ScriptManager:storeValue( "nextSquadNE",		nextSquadNE );
	ScriptManager:storeValue( "showProgress",		showProgress );
	ScriptManager:storeValue( "enemiesDestroyed",	enemiesDestroyed );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	--ScriptManager:addOnUnitHasAttackedTrigger(	0, , -1,	"stopAttackingHint",	"stopAttackingHint" );
	
	-- trigger for bridge
	ScriptManager:addOnBridgeRepairTrigger(		-1, Units.N_BRIDGE_L, -1, "onBridgeRepaired",		"onBridgeRepaired" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 1, Units.N_BRIDGE_L, -1, "showAttackedWarning1",	"showAttackedWarning1" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.N_BRIDGE_L, -1, "transitionToFail",		"transitionToFail" );
	
	--trigger for base
	ScriptManager:addOnUnitCapturedTrigger(		0, Units.L_BUILDING_HQ, -1, "onBaseCaptured",		"onBaseCaptured" );
	ScriptManager:addOnUnitSuppliedTrigger( 	0, Units.L_BUILDING_HQ, -1, "onBaseRepaired",		"onBaseRepaired" );
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_BUILDING_HQ, -1, "showAttackedWarning2",	"showAttackedWarning2" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_BUILDING_HQ, -1, "transitionToFail",		"transitionToFail" );
	
	--trigger for bunkers
	ScriptManager:addOnUnitOccupiedTrigger( -1, -1,									-1, "unitEnteredBunker",	"unitEnteredBunker" );
	ScriptManager:addOnUnitUnloadedTrigger( -1, -1,									-1, "unitLeftBunker",		"unitLeftBunker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 1, Units.N_EMPLACEMENT_BUNKER,		-1, "showAttackedWarning3",	"showAttackedWarning3" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.N_EMPLACEMENT_BUNKER,		-1,	"stopAttackingHint1",	"stopAttackingHint1" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.N_EMPLACEMENT_BUNKER,		-1, "onBunkerDestroyed",	"onBunkerDestroyed" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 1, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "showAttackedWarning4",	"showAttackedWarning4" );
	ScriptManager:addOnUnitHasAttackedTrigger(	 0, Units.N_EMPLACEMENT_BUNKERTOWER, -1,	"stopAttackingHint2",	"stopAttackingHint2" );
	ScriptManager:addOnUnitDestroyedTrigger(	-1, Units.N_EMPLACEMENT_BUNKERTOWER,	-1, "onBunkerDestroyed",	"onBunkerDestroyed" );
	
	-- trigger for destroying enemies
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onEnemyDestroyed", "onEnemyDestroyed" );
	
	-- triggers for ai
	ScriptManager:addOnAiCalculationTrigger( true, "addAiOrders", "addAiOrders" );
end

function loadValues()
	attackStartRound	= ScriptManager:getValue( "attackStartRound" );
	nextSquadW			= ScriptManager:getValue( "nextSquadW" );
	nextSquadS			= ScriptManager:getValue( "nextSquadS" );
	nextSquadNE			= ScriptManager:getValue( "nextSquadNE" );
	showProgress		= ScriptManager:getValue( "showProgress" );
	enemiesDestroyed	= ScriptManager:getValue( "enemiesDestroyed" );
end

function addAiOrders( squadId, mainOrderData, allMainOrderData )
	if allMainOrderData:count() <= 0 then
		print( "squad #" .. squadId .. " needs new orders" );
		
		if squadId == enemySquadIds.eastVillage then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.eastVillage, 5, 14, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.eastVillageMg then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.eastVillageMg, 4, 15, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.baseEast then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.baseEast, 19, 15, -1, 3, AiOrder.DEFEND );
		
		elseif squadId == enemySquadIds.baseDef then
			print( "received");
			ScriptManager:addOrder( enemySquadIds.baseDef, -1, -1, baseId, 3, AiOrder.DEFEND );
			ScriptManager:addOrder( enemySquadIds.baseDef, 15, 10, -1, 3, AiOrder.DEFEND );
		end
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx(	15, 10, 0.7, 5, true );
	Utils:markUnit(				15, 10, 1, 2, 0 );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx(	9, 12, 0.7, 5, true );
	Utils:markUnit(				9, 12, 1, 2, 0 );
	Utils:hideDialogue();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 7, 22, 0.7, 5, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.repairBridge, MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.defeatAttackers,	0, 63 ); -- set later when attacking starts
	Utils:setMissionProgress( missionIds.keepBunkers,		0, 5 );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		5, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
	
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER,  7, 12, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 12, 11, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 13,  4, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 18,  5, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 19,  6, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 19, 17, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER, 15,  9, 42 );
	
	--[[ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER,  7, 12, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 12, 11, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 13,  4, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 18,  5, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 19,  6, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 19, 17, 42 );
	ScriptManager:spawnUnit( 1, Units.L_INFANTRY_ENGINEER, 15,  9, 42 );
	
	-- wave start
	attackStartRound = ScriptManager:getCurrentRound(); -- needed for incoming attack waves
	ScriptManager:storeValue( "attackStartRound", attackStartRound );
	
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	ScriptManager:wait( 2 );]]
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Bridge Stuff


function onBridgeRepaired( engi, bridge )
	local bridgeHp = bridge:getHealth();
	
	if bridgeHp == bridgeMaxHp then
		ScriptManager:removeTrigger( "onBridgeRepaired" );
		
		ScriptManager:enableInteractionButton(	InteractionButton.TRANSFORM );
		ScriptManager:disableInteractionButton(	InteractionButton.DETONATE_BRIDGE );
		
		Utils:setMissionStatus( missionIds.repairBridge, MissionStatus.ACCOMPLISHED );
		
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_1, 3 );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_PRIMARY1_FLAVOR1 );
		ScriptManager:moveCameraEx(		15, 10, 0.7, 5, true );
		ScriptManager:revealFogOfWar(	15, 10, 1, true );
		Utils:hideDialogue();
		Utils:antiRush();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_PRIMARY1_FLAVOR2, 4 );
		ScriptManager:revealFogOfWar( 15, 10, 1, false );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_PRIMARY1_FLAVOR3 );
		ScriptManager:moveCameraEx( 18, 17, 0.7, 3, true );
		Utils:antiRush();
		ScriptManager:moveCameraEx( 19, 6, 0.7, 3, true );
		Utils:antiRush();
		Utils:hideDialogue();
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L5_2_PRIMARY1_FLAVOR4 );
		ScriptManager:moveCameraEx( 11, 11, 0.7, 3, true );
		Utils:antiRush();
		ScriptManager:moveCameraEx( 15, 10, 0.7, 3, true );
		Utils:hideDialogue();
		
		Utils:endCutscene()
		Utils:disablePlayerInteraction();
		
		ScriptManager:setMissionStatus( missionIds.repairBase,	 MissionStatus.IN_PROGRESS );
		ScriptManager:setMissionStatus( missionIds.keepBunkers,	 MissionStatus.IN_PROGRESS );
		ScriptManager:wait( 2 );
		
		Utils:enablePlayerInteraction();
	end
end


-- END Bridge Stuff
-- BEGIN Base Stuff


function onBaseCaptured( capturer, base )
	ScriptManager:removeTrigger( "onBaseCaptured" );
	
	base:setIsAttackable( true );
	
	ScriptManager:disableInteractionButton(	InteractionButton.INSTANT_SUPPLY_SINGLE );
	ScriptManager:disableInteractionButton(	InteractionButton.INSTANT_SUPPLY_FULL );
	
	--prevents the player from buying units before repairing it
	for i = Units.L_INFANTRY_MG, Units.L_ARTILLERY_HOWITZER do
		ScriptManager:removeReinforcementsFromBase( baseId, i );
	end
end

function onBaseRepaired( supplier, base )
	-- supplytrucks dont give health on building supply, so i artificially add it
	if supplier:getTemplateId() ~= Units.L_INFANTRY_ENGINEER then
		Unit:setHealth( base:getHealth() + 150 );
		base:setSupplyLoad( 0 ); -- no supplies for the base!
		ScriptManager:wait( 0.25 ); -- just to be sure
	end
	
	local baseHp = base:getHealth();
	if baseHp == baseMaxHp then
		ScriptManager:removeTrigger( "onBaseRepaired" );
		
			for i = Units.L_INFANTRY_MG, Units.L_ARTILLERY_HOWITZER do
				ScriptManager:addReinforcementsToBase( baseId, i );
			end
		
		base:setSupplyLoad( 30 );
		Utils:setMissionStatus( missionIds.repairBase, MissionStatus.ACCOMPLISHED );
		
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_PRIMARY3_FLAVOR1, 4 );
		Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_PRIMARY3_FLAVOR2, 4 );
		
		Utils:endCutscene()
		Utils:disablePlayerInteraction();
		
		ScriptManager:setMissionStatus( missionIds.defendBase,	 MissionStatus.IN_PROGRESS );
		ScriptManager:setMissionStatus( missionIds.defendBridge, MissionStatus.IN_PROGRESS );
		
		-- start enemy waves
		attackStartRound = ScriptManager:getCurrentRound(); -- needed for incoming attack waves
		ScriptManager:storeValue( "attackStartRound", attackStartRound );
		
		ScriptManager:gainGold( 0, 2000 );
		
		ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
		ScriptManager:wait( 2 );
		
		Utils:enablePlayerInteraction();
	end
end


-- END Base Stuff
-- BEGIN Wave Spawn


function spawnWaveWest()
	spawnWave( nextSquadW, "W" );
	
	ScriptManager:storeValue( "nextSquadW", nextSquadW + 3 );
end

function spawnWaveSouth()
	spawnWave( nextSquadS, "S" );
	
	ScriptManager:storeValue( "nextSquadS", nextSquadS + 3 );
end

function spawnWaveNortheast()
	spawnWave( nextSquadNE, "NE" );
	
	ScriptManager:storeValue( "nextSquadNE", nextSquadNE + 3 );
end

function spawnWave( squadId, waveStartingPoint )
	local rng = math.random( 1, 4 );
	local spawnTable = _G["enemyWave" .. rng ];
	local spawnPos	 = _G["spawnPos" .. waveStartingPoint ];
	local unitId, pos;
	for i = 1, #spawnTable do
		pos = spawnPos[i];
		print( "iteration" .. i );
		print( pos[1] .. " | " .. pos[2] );
		print( #spawnTable );
		print( spawnTable[i] );
		unitId = ScriptManager:spawnUnit( 1, spawnTable[i], pos[1], pos[2], squadId );
	end
	
	local newProgress = ScriptManager:getMissionProgress( missionIds.defeatAttackers ) + #spawnTable;
	ScriptManager:setMissionProgress( missionIds.defeatAttackers, newProgress );
	print( "wavestart" .. waveStartingPoint );
	print( "remaining: " .. newProgress );
	
	-- target: bridge
	if waveStartingPoint == "W" then
		ScriptManager:addOrder( squadId, -1, -1, bridgeId,	3, AiOrder.ATTACK );
		ScriptManager:addOrder( squadId,  9, 12, -1,		3, AiOrder.ATTACK );
	
	-- target: depot
	else
		local orderId = ScriptManager:addOrder( squadId, -1, -1, baseId, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		
		orderId = ScriptManager:addOrder( squadId, 15, 10, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	end
end

function onEnemyTurnStart( playerId, turnId, roundId )
	local roundsSinceAttackStart = roundId - attackStartRound;
	print( "rounds since attack started: " .. roundsSinceAttackStart );
	
	-- waves W
	if roundsSinceAttackStart == 1 or roundsSinceAttackStart ==  5 or roundsSinceAttackStart == 6 or 
	   roundsSinceAttackStart == 8 or roundsSinceAttackStart == 11 then
		spawnWaveWest();
	end
	
	-- wave S
	if roundsSinceAttackStart == 1 or roundsSinceAttackStart ==  3 or roundsSinceAttackStart == 6 or 
	   roundsSinceAttackStart == 9 or roundsSinceAttackStart == 11 then
		spawnWaveSouth();
	end
	
	-- wave NE
	if roundsSinceAttackStart ==  2 or roundsSinceAttackStart ==  5 or roundsSinceAttackStart == 7 or 
	   roundsSinceAttackStart == 10 or roundsSinceAttackStart == 12 then
		spawnWaveNortheast();
	end
	
	if roundsSinceAttackStart >= 12 then
		print( "done" );
		ScriptManager:removeTrigger( "onEnemyTurnStart" );
		ScriptManager:runForPlayer( 0, "prepareAlmostDoneCutscene" );
	end
end

function prepareAlmostDoneCutscene()
	table.insert( queueTable, startAlmostDoneCutscene );
	Utils:cutsceneQueue();
end

function startAlmostDoneCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_PRIMARY5_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_PRIMARY5_FLAVOR2, 3 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.defeatAttackers, MissionStatus.IN_PROGRESS );
	
	showProgress = 1;-- show the mission progress from now on
	ScriptManager:storeValue( "showProgress", showProgress );
	
	showAttackerMissionProgress(); -- show the player how many enemies are still left
end


-- END Wave Spawn
-- BEGIN Destroy Attacker Stuff


function onEnemyDestroyed( unit )
	local squadId = unit:getSquadId();
	
	if squadId >= enemySquadIds.wave1W then -- start of waves
		Utils:decrementMissionProgress( missionIds.defeatAttackers );
		print( "remaining attackers: " .. ScriptManager:getMissionProgress( missionIds.defeatAttackers ) );
		
		enemiesDestroyed = enemiesDestroyed + 1;
		ScriptManager:storeValue( "enemiesDestroyed", enemiesDestroyed );
		
		if showProgress == 1 then
			local progress = ScriptManager:getMissionProgress( missionIds.defeatAttackers );
			if progress % 5 == 0 or progress < 5 then -- show progress only every 5th unit / when its close to the end
				ScriptManager:runForPlayer( 0, "prepareAttackerMissionProgress" );
			end
		end
	end
end

function prepareAttackerMissionProgress()
	table.insert( queueTable, showAttackerMissionProgress );
	Utils:cutsceneQueue();
end

function showAttackerMissionProgress()
	local progress = ScriptManager:getMissionProgress( missionIds.defeatAttackers );
	if progress <= 0 then
		Utils:setMissionStatus( missionIds.defeatAttackers, MissionStatus.ACCOMPLISHED );
		startVictoryCutscene();
	
	else
		Utils:showMissionProgress( progress, Text.T_CAMP_L5_2_PRIMARY5_COUNTER );
	end
end


-- END Destroy Attacker Stuff
-- BEGIN Bunker Stuff


function adjustUnitsInBunker( bunker, value )
	local bunkerTemplate = bunker:getTemplateId()
	if bunkerTemplate == Units.N_EMPLACEMENT_BUNKER or
	   bunkerTemplate == Units.N_EMPLACEMENT_BUNKERTOWER then
		local newProgress = ScriptManager:getMissionProgress( missionIds.keepBunkers ) + value;
		ScriptManager:setMissionProgress( missionIds.keepBunkers, newProgress );
		
		print("units in bunkers = " .. newProgress );
		
		if newProgress >= bunkersToOccupy then
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_SECONDARY1_FLAVOR1, 4 );
			
		-- bunkers were all manned, but player moved a unit out
		elseif newProgress == bunkersToOccupy - 1 and value == -1 then
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_SECONDARY1_FLAVOR2, 4 );
			
		else
			-- no util function cause i dont want player input to be blocked
			ScriptManager:preparePopupText();
			ScriptManager:addPopupTextParameter( "x", newProgress );
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_SECONDARY1_COUNTER, 2 );
		end
	end
end

function unitEnteredBunker( bunker, infantry)
	adjustUnitsInBunker( bunker, 1 );
end

function unitLeftBunker( bunker, infantry)
	adjustUnitsInBunker( bunker, -1 );
end

function onBunkerDestroyed()
	ScriptManager:removeTrigger( "onBunkerDestroyed" );
	ScriptManager:removeTrigger( "unitEnteredBunker" );
	ScriptManager:removeTrigger( "unitLeftBunker" );
	
	ScriptManager:setMissionProgress( missionIds.keepBunkers, 0 ); -- prevent the player from getting partial xp
	
	ScriptManager:runForPlayer( 0, "prepareBunkerMissionUpdate" );
end

function prepareBunkerMissionUpdate()
	table.insert( queueTable, failBunkerMission );
	Utils:cutsceneQueue();
end

function failBunkerMission()
	Utils:setMissionStatus( missionIds.keepBunkers, MissionStatus.FAILED );
end


-- END Bunker Stuff
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_VICTORY_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L5_2_VICTORY_FLAVOR2, 4 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	Utils:missionCheckerAccomplish( missionIds.defendBridge );
	Utils:missionCheckerAccomplish( missionIds.defendBase );
	
	if ScriptManager:getMissionProgress( missionIds.keepBunkers ) == bunkersToOccupy then
		Utils:missionCheckerAccomplish( missionIds.keepBunkers );
	end
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Victory
-- BEGIN Defeated


function showAttackedWarning1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.N_BRIDGE_L );
end

function showAttackedWarning2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.L_BUILDING_HQ );
end

function showAttackedWarning3( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.N_EMPLACEMENT_BUNKER );
end

function showAttackedWarning4( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit, Units.N_EMPLACEMENT_BUNKERTOWER );
end

function stopAttackingHint1( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	if defender:getTemplateId() == Units.N_EMPLACEMENT_BUNKER then
		Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.N_EMPLACEMENT_BUNKER );
	end
end

function stopAttackingHint2( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	if defender:getTemplateId() == Units.N_EMPLACEMENT_BUNKERTOWER then
		Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding, Units.N_EMPLACEMENT_BUNKERTOWER  );
	end
end

function transitionToFail()
	ScriptManager:runForPlayer( 0, "missionFailed" );
end

function missionFailed()
	Utils:disablePlayerInteraction();
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:setMissionProgress( missionIds.defeatAttackers, enemiesDestroyed ); -- update partial mission xp
	
	ScriptManager:displaySubtitle( Text.T_MISSION_FAILED );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Defeated