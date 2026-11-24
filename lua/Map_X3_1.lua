require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

--[[ story summary:
	player has to catch spies along the way. as soon as they see the player they attempt to run away and the player has to destroy them before they can
	reach the map border. even though this sounds like a main goal ( its the catch the spy campaign after all ) it is only the secondary mission because
	failing the mission because you failed to catch one / two / three guys did not really fit into the game so the main goal is to cross the area fast in order
	to stop tem from sending the intel ( thats happening in the second mission as well ).
	near the end of the map allied troops block the way and the player has to clear them and open the path to the exit
]]

-- mission stuff
missionIds = {
	crossMap		= 1,
	clearPath		= 2,
	disarmMines		= 3,
	destroySpies	= 4,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.crossMap,		true,	Text.T_CAMP_X3_1_PRIMARY1,		125 },
	{ missionIds.clearPath,		true,	Text.T_CAMP_X3_1_PRIMARY2,		100 },
	{ missionIds.disarmMines,	false,	Text.T_CAMP_X3_1_SECONDARY1,	 75 },
	{ missionIds.destroySpies,	false,	Text.T_CAMP_X3_1_SECONDARY2,	125 }, -- 25 xp per scout, only 1 need to accomplish
};

enemySquadIds = {
	barrierSpy		=  1,
	outpostSpy		=  2,
	jettySpy		=  3, -- tries to escape via rubber boat
	forestSpy		=  4,
	puddleSpy		=  5,
	barrierSquad	=  6,
	outpostSquad	=  7,
	jettySquad		=  8,
	forestSquad		=  9,
	puddleSquad		= 10,
	cityAttacker	= 11, -- attacks together with barrier squad
	railAttacker	= 12, -- falls into the players back when he is near the puddle spy ( or if found before )
	bridgeAttacker	= 13, -- attacks when outpost is captured / outpost squad is annihilated
	fieldSquad		= 14, -- attacks together with forest squad
	lastSquad		= 15, -- player needs to kill them to win
	rockMgNest		= 16,
	craterMgNest	= 17,
	mines			= 18,
};

spyIds		= {  2,  3,  4,  5,  6, };
barrierIds	= {  7,  8,  9, };
outpostIds	= { 11, 14, 15, 16, 17, };
jettyIds	= { 25, 26, };
forestIds	= { 21, 22, 23, 24, };
puddleIds	= { 27, 28, 29, 30, };
cityIds		= { 10, 12, 13, };
railIds		= { 31, 32, 33, 34, 35, };
bridgeIds	= { 18, 19, 20, };
fieldIds	= { 36, 37, 38, 39, };
lastIds		= { 40, 41, 42, 43, 44, };
mgNestIds	= { 53, 54, };
mineIds		= { 55, 56, 57, 58, 59, 60, };

spySquadsSeen		= {};
spyTargetTiles		= { { 21, 1 }, { 3, 18 }, { 10, 1 }, { 3, 18 }, { 1, 1 } };
unitsInGoal			= {};
unitsNeededToWin	= 5;
playerUnits			= 8; -- 8 = number of start units
minesToDisarm		= 3;


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.AIRSTRIKE );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "playerUnits", playerUnits );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitDestroyedTrigger(	0, -1, -1,	"checkForEnd", "checkForEnd" );
	
	-- trigger for spies
	ScriptManager:addOnUnitSightedTrigger(		1, Units.L_INFANTRY_SPY, -1, false,	"onSpySighted",			"onSpySighted" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, -1,					 -1,		"onPlayerHasAttacked",	"onPlayerHasAttacked" );
	ScriptManager:addOnUnitSightedTrigger(		0, -1,					 -1, true,	"onPlayerSighted",		"onPlayerSighted" );
	ScriptManager:addOnUnitDestroyedTrigger(	1, Units.L_INFANTRY_SPY, -1,		"onSpyDestroyed",		"onSpyDestroyed" );
	
	-- one spy tries to escape via rubber boat, so i need a special trigger for him
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_SHIP_RUBBERBOAT, -1,		"onSpyDestroyed",	"onSpyDestroyed" ); 
	
	for i = 1, #spyTargetTiles do
		local posX = spyTargetTiles[i][1];
		local posY = spyTargetTiles[i][2];
		
		Utils:addOnEnterAreaTrigger( posX, posY, 1, 1, Units.L_INFANTRY_SPY, -1, true, "spyEscaped", "spyEscaped" );
		
		-- one spy tries to escape via rubber boat, so i need a special trigger for him
		Utils:addOnEnterAreaTrigger( posX, posY, 1, 1, Units.L_SHIP_RUBBERBOAT, -1, true, "spyEscaped", "spyEscaped" );
	end
	
	-- trigger for mines
	ScriptManager:addOnMineTriggeredTrigger( 1, -1, -1, "startMineCutscene",	"startMineCutscene" );
	ScriptManager:addOnMineDetectedTrigger(	 1, -1, -1, "startMineCutscene",	"startMineCutscene" );
	ScriptManager:addOnMineDisamedTrigger(	 1,			"onMineDisarmed",		"onMineDisarmed" );
	
	-- trigger for clearing the path
	for i = 1, 7 do
		ScriptManager:addOnEnterTileTrigger( i, 7, 0, -1, -1, true, "startClearPathCutscene", "startClearPathCutscene" );
		ScriptManager:addOnEnterTileTrigger( 8, i, 0, -1, -1, true, "startClearPathCutscene", "startClearPathCutscene" );
	end
	ScriptManager:addOnUnitDestroyedTrigger( 1, -1, -1, "onUnitDestroyed", "onUnitDestroyed" );
	
	-- trigger for crossing the map
	local x = 5;
	for i = 1, 4 do
		-- I combine two loops and use it once as X and once as Y var
		ScriptManager:addOnEnterTileTrigger( x,		i, 0, -1, -1, false, "onEndLeft", "onEndLeft", false );
		ScriptManager:addOnEnterTileTrigger( x + 1, i, 0, -1, -1, false, "onEndLeft", "onEndLeft", false );
		
		if x % 2 == 0 then
			x = x - 1;
		end
		
		ScriptManager:addOnEnterTileTrigger( i, 6, 0, -1, -1, false, "onEndLeft", "onEndLeft" );
		ScriptManager:addOnEnterTileTrigger( i, 7, 0, -1, -1, false, "onEndLeft", "onEndLeft" );
	end
	
	Utils:addOnEnterAreaTrigger( 		 2, 2, 2,	0, -1, -1, false, "onEndReached", "onEndReached" );
	ScriptManager:addOnEnterTileTrigger( 4, 1,		0, -1, -1, false, "onEndReached", "onEndReached" );
	
	ScriptManager:addOnUnitPurchasedTrigger( 0,			"onUnitBought",			 "onUnitBought" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, -1, -1, "onPlayerUnitDestroyed", "onPlayerUnitDestroyed" );
end

function loadValues()
	playerUnits		= ScriptManager:getValue( "playerUnits" );
	
	unitsInGoal		= Utils:loadValuesFromSavefileIntoEmptyTable( "goalUnits" );
	spySquadsSeen	= Utils:loadValuesFromSavefileIntoEmptyTable( "spySquadsSeen" );
end

function addAiOrders()
	ScriptManager:addOrder( enemySquadIds.cityAttacker,		21,  2, -1,  3, AiOrder.DEFEND ); -- attacks turn after player sees first spy
	ScriptManager:addOrder( enemySquadIds.bridgeAttacker,	 8, 15, -1,  3, AiOrder.DEFEND ); -- attacks turn after player gets to the depot
	ScriptManager:addOrder( enemySquadIds.railAttacker,		 2, 17, -1,  3, AiOrder.DEFEND ); -- attacks turn after player gets to last spy
	
	local orderId = ScriptManager:addOrder( enemySquadIds.fieldSquad, 4, 10,  -1, 3, AiOrder.DEFEND );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CONTINUE_TO_ATTACK );
	
	ScriptManager:addOrder( enemySquadIds.rockMgNest,	11, 13, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.craterMgNest,	15,  5, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:addOrder( enemySquadIds.lastSquad, 2 ,3, -1, 3, AiOrder.DEFEND );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_INTRO_FLAVOR1 );
	ScriptManager:moveCameraEx( 19, 4, 0.7, 4, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_INTRO_FLAVOR2 );
	ScriptManager:moveCameraEx( 6, 15, 0.7, 6, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 3, 3, 0.7, 4, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_SUBTITLE_INTRO_END_1 );
	ScriptManager:moveCameraEx( 20, 15, 0.7, 7, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.crossMap,	 MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.destroySpies, MissionStatus.IN_PROGRESS );

	Utils:setMissionProgress( missionIds.clearPath,		0, 5 );
	Utils:setMissionProgress( missionIds.destroySpies,	0, 5 );
	Utils:setMissionProgress( missionIds.disarmMines,	0, 3 );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	--ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 7, 42 );
	--ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 7, 42 );
	--ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	3, 7, 42 );
	--ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 8, 42 );
	--ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 8, 42 );
	ScriptManager:spawnUnit( 0, Units.SHORTSIGHTED_GOD,	8, 2, 42 );
	--ScriptManager:setMissionStatus( missionIds.clearPath, MissionStatus.ACCOMPLISHED );
	--ScriptManager:addOnTurnStartTrigger( 0, -1, -1, "fowReveal", "fowReveal" );
end

function fowReveal()
	ScriptManager:revealFogOfWar( 19,  4, 5, true );
	ScriptManager:revealFogOfWar( 14,  6, 3, true );
	ScriptManager:revealFogOfWar( 12, 11, 4, true );
	ScriptManager:revealFogOfWar(  8, 16, 3, true );
	ScriptManager:revealFogOfWar(  5,  6, 3, true );
	ScriptManager:revealFogOfWar(  3, 16, 3, true );
end

function removeSquads()
	Utils:removeSquad( spyIds );
	Utils:removeSquad( barrierIds );
	Utils:removeSquad( outpostIds );
	Utils:removeSquad( jettyIds );
	Utils:removeSquad( forestIds );
	Utils:removeSquad( puddleIds );
	Utils:removeSquad( cityIds );
	Utils:removeSquad( railIds );
	Utils:removeSquad( bridgeIds );
	Utils:removeSquad( fieldIds );
	Utils:removeSquad( mgNestIds );
	Utils:removeSquad( mineIds );
	--Utils:removeSquad( lastIds );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Spy Stuff


-- player sees the spy
function onSpySighted( playerUnit, spyUnit )
	local spySquadId = spyUnit:getSquadId();
	local alreadySeen = false;
	--print( "spy seen" );
	--print( spySquadId );
	
	-- check if spy was already seen
	if #spySquadsSeen > 0 then
		for i = 1, #spySquadsSeen do
			if spySquadsSeen[i] == spySquadId then
				alreadySeen = true;
				--print( "spy was seen before" );
			end
		end
	end
	
	-- if spy was not seen before, show cutscene and update the ai
	if alreadySeen == false then
		--print( "initiating spy cutscene" );
		local spyX = spyUnit:getX();
		local spyY = spyUnit:getY();
		
		Utils:startCutscene();
			
		ScriptManager:moveCameraEx( spyX, spyY, 0.7, 2, false );
		
		if #spySquadsSeen == 0 then
			Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_SECONDARY2_FLAVOR1, 3 );
			Utils:antiRush();
			
			ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_SECONDARY2_FLAVOR2 );
		
			else
			ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_SECONDARY2_FLAVOR3 );
		end
		
		-- one tries to escape by water, show that in cutscene
		if spySquadId == enemySquadIds.jettySpy then
			ScriptManager:transformUnit( spyUnit:getId(), 12, 5, 0, true );
			
			ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_SECONDARY2_FLAVOR4 );
				
			Utils:markUnit( 12, 5, 1, 3, 0 );
			Utils:antiRush();
			Utils:hideDialogue();
			
		else
			Utils:markUnit( spyX, spyY, 1, 2, 0 );
			Utils:hideDialogue();
		end
		
		
		Utils:endCutscene();
		
		-- give the spy and the surrounding squad the right ai orders
		local orderId = ScriptManager:addOrder( spySquadId, spyTargetTiles[spySquadId][1], spyTargetTiles[spySquadId][2], -1, 1, AiOrder.MOVE );
		ScriptManager:disableOrderFlag( orderId, AiOrderFlag.FLAG_STACK_TOGETHER );
		ScriptManager:disableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE );
		
		local playerX = playerUnit:getX();
		local playerY = playerUnit:getY();
		addSquadOrder( spySquadId + 5, playerX, playerY )
		--print(spySquadsSeen)
		spySquadsSeen = Utils:addValueToTableAndSave( spySquadId, "spySquadsSeen", spySquadsSeen );
	end
end

function onPlayerHasAttacked( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	local playerId = defender:getPlayerId();
	
	--should always be case that defender == 1 but just to be sure  
	if playerId == 1 then
		print( "playerAttacked; defender" );
		onPlayerSighted( defender, attacker );
	else
		print( "playerAttacked; attacker" );
		onPlayerSighted( attacker, defender );
	end
end

-- spy squad ( not spy! ) saw the player
function onPlayerSighted( spyAddsUnit, playerUnit )
	local spyAddsSquadId = spyAddsUnit:getSquadId();
	
	if spyAddsSquadId <= 10 and spyAddsSquadId > 5 then
		--print( "player seen" );
		local playerX = playerUnit:getX();
		local playerY = playerUnit:getY();
		addSquadOrder( spyAddsSquadId, playerX, playerY )
	end
end

function addSquadOrder( spyAddsSquadId, playerX, playerY )
	--print( "add order")
	-- give order if squad has none yet
	if ScriptManager:getSquadOrderCount( spyAddsSquadId ) == 0 then 
		--print( "give order" );
		--print( spyAddsSquadId );
		
		if spyAddsSquadId == enemySquadIds.barrierSquad then
			--Utils:attackOrder( spyAddsSquadId, 19, 8, 3 );
			Utils:attackOrder( spyAddsSquadId, playerX, playerY, 3 );
			
			ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "startCityAttack", "startCityAttack" );
		
		elseif spyAddsSquadId == enemySquadIds.outpostSquad then
			ScriptManager:addOrder( spyAddsSquadId, -1, -1,  1, 3, AiOrder.DEFEND );
			ScriptManager:addOrder( spyAddsSquadId, 13, 10, -1, 3, AiOrder.DEFEND );
			
			ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "startBridgeAttack", "startBridgeAttack" );
		
		elseif spyAddsSquadId == enemySquadIds.jettySquad or spyAddsSquadId == enemySquadIds.forestSquad then
			--Utils:attackOrder( spyAddsSquadId, 16, 8, 3 );
			--Utils:attackOrder( spyAddsSquadId, 9, 13, 3 );
			Utils:attackOrder( spyAddsSquadId, playerX, playerY, 3 );
		
		elseif spyAddsSquadId == enemySquadIds.puddleSquad then
			--Utils:attackOrder( spyAddsSquadId, 5, 9, 3 );
			Utils:attackOrder( spyAddsSquadId, playerX, playerY, 3 );
			
			ScriptManager:addOnTurnStartTrigger( 1, -1, ScriptManager:getCurrentRound() + 1, "startRailAttack", "startRailAttack" );
		end
	end
end

function startCityAttack()
	startAttack( "startCityAttack", enemySquadIds.cityAttacker, 19, 8, 3 );
end

function startBridgeAttack()
	startAttack( "startBridgeAttack", enemySquadIds.bridgeAttacker, 14, 10, 3 );
end

function startRailAttack()
	startAttack( "startRailAttack", enemySquadIds.railAttacker, 5, 6, 3 );
end

function startAttack( triggerId, squadId, posX, posY, radius )
	ScriptManager:removeTrigger( triggerId );
	
	ScriptManager:removeAllOrders( squadId );
	Utils:attackOrder( squadId, posX, posY, radius );
end

function onSpyDestroyed( spy )
	Utils:incrementMissionProgress( missionIds.destroySpies )
	
	Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroySpies), Text.T_CAMP_X3_1_SECONDARY2_COUNTER );
end

function spyEscaped( tileX, tileY, playerId, unitTemplateId, unitId )
	if tileY < 5 then -- just a quick check to see if spy leaves the map top or bottom
		ScriptManager:moveUnitEx( unitId, tileX, 0, false );
	
	else
		ScriptManager:moveUnitEx( unitId, tileX, 19, false );
	end
	ScriptManager:removeUnitEx( unitId, true );
end


-- END Spy Stuff
-- BEGIN Mine Stuff


function startMineCutscene( mineX, mineY, mineId )
	ScriptManager:removeTrigger( "startMineCutscene" );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_SECONDARY1_FLAVOR1, 6 );
	
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.disarmMines, MissionStatus.IN_PROGRESS );
end

function onMineDisarmed()
	Utils:incrementMissionProgress( missionIds.disarmMines );
	
	local progress = ScriptManager:getMissionProgress( missionIds.disarmMines ); 
	if progress >= minesToDisarm then
		ScriptManager:removeTrigger( "onMineDisarmed" );
		Utils:setMissionStatus( missionIds.disarmMines, MissionStatus.ACCOMPLISHED );
	
	else
		Utils:showMissionProgress( progress, Text.T_CAMP_X3_1_SECONDARY1_COUNTER );
	end
end


-- END Mine Stuff
-- BEGIN Unit Stuff


function startClearPathCutscene( tileX, tileY )
	ScriptManager:removeTrigger( "startClearPathCutscene" );
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_PRIMARY2_FLAVOR1 );
	ScriptManager:moveCameraEx( 3, 3, 0.7, 4, true );
	Utils:hideDialogue();
	
	ScriptManager:revealFogOfWar( 3, 3, 2, true );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_PRIMARY2_FLAVOR2, 4 );
	ScriptManager:revealFogOfWar( 3, 3, 2, false );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X3_1_PRIMARY2_FLAVOR3 );
	ScriptManager:moveCameraEx( tileX, tileY, 0.7, 4, true );
	Utils:hideDialogue();
		
	Utils:endCutscene();
	Utils:setMissionStatus( missionIds.clearPath, MissionStatus.IN_PROGRESS );
	
	--[[ might not work good
	ScriptManager:removeAllOrders( enemySquadIds.lastSquad );
	local orderId = ScriptManager:addOrder( enemySquadIds.lastSquad, tileX, tileY, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY ); 
	ScriptManager:addOrder( enemySquadIds.lastSquad, 2 ,3, -1, 3, AiOrder.DEFEND );]]
end

function onUnitDestroyed( unit )
	if unit:getSquadId() == enemySquadIds.lastSquad then
		Utils:incrementMissionProgress( missionIds.clearPath );
		ScriptManager:runForPlayer( 0, "prepareClearPathProgress" );
	end
end

function prepareClearPathProgress()
	table.insert( queueTable, startClearPathProgress );
	Utils:cutsceneQueue();
end

function startClearPathProgress()
	if ScriptManager:getMissionProgress( missionIds.clearPath ) >= #lastIds then
		ScriptManager:removeTrigger( "onUnitDestroyed" );
		Utils:setMissionStatus(missionIds.clearPath, MissionStatus.ACCOMPLISHED );
		
		if checkEndZoneObjective( false ) then
			startVictoryCutscene();
		
		else
			Utils:startCutscene();
			
			ScriptManager:moveCameraEx( 2, 2, 0.7, 2, false );
			Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_PRIMARY2_FLAVOR4, 4 );
			
			Utils:endCutscene();
			checkEndZoneObjective( true )
		end
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.clearPath ), Text.T_CAMP_X3_1_PRIMARY2_COUNTER );
	end
end


-- END Unit Stuff
-- BEGIN Cross Map Stuff


function onUnitBought( unit )
	playerUnits = playerUnits + 1;
	ScriptManager:storeValue( "playerUnits", playerUnits );
end

function onPlayerUnitDestroyed( unit )
	local checkObjective = false;
	
	playerUnits = playerUnits - 1;
	ScriptManager:storeValue( "playerUnits", playerUnits );
	
	-- check if unit was in end zone and remove it if it was;
	checkObjective = leftCheck( unit:getId() );
	
	-- check if the need units for the objective have changed by this destruction
	if checkObjective == false and playerUnits < 5 and playerUnits <= #unitsInGoal then
		checkObjective = true;
	end
	
	-- if one of the two checks above happen, check objective / victory
	if checkObjective then
		-- only show if it is relevant ( = the barricades are gone and the player should leave now )
		if ScriptManager:getMissionStatus( missionIds.barricades ) == MissionStatus.ACCOMPLISHED then
			if checkEndZoneObjective( true ) then
				startVictoryCutscene();
			end
		end
	end
end

function onEndReached( tileX, tileY, playerId, unitTemplateId, unitId )
	local alreadyIn = false;
	--print( string.format( "unit %i reached goal", unitId ) );
	
	-- check if unit is already in goal
	if #unitsInGoal >= 1 then
		for i = 1, #unitsInGoal do
			if unitsInGoal[i] == unitId then
				alreadyIn = true;
				--print( "unit was already in" );
				break;
			end
		end
	end
	
	if alreadyIn == false then
		--table.insert( unitsInGoal, unitId );
		--ScriptManager:storeValue( string.format( "goalUnits_%i", unitId ), unitId );
		
		unitsInGoal = Utils:addValueToTableAndSave( unitId, "goalUnits", unitsInGoal );
		print( #unitsInGoal );
		--print( "unit added to goalUnits" );
		--print( ScriptManager:getMissionStatus( missionIds.clearPath ) );
		--print( MissionStatus.ACCOMPLISHED  );
		if ScriptManager:getMissionStatus( missionIds.clearPath ) == MissionStatus.ACCOMPLISHED then
			--print( "checkgoal" );
			if checkEndZoneObjective( true ) then
				startVictoryCutscene();
			end
		end
	end
end

function checkEndZoneObjective( showProgress )
	--print( "check" );
	-- check how many player units are alive and ( if necessary ) adapt the goal
	local neededToWin = unitsNeededToWin;
	
	if playerUnits < 5 then
		--print( "< 5 units needed to win" );
		neededToWin = playerUnits;
	end
	
	--print( neededToWin );
	--print( #unitsInGoal );
	
	-- check for victory
	if #unitsInGoal >= neededToWin then
		ScriptManager:setMissionStatus( missionIds.crossMap, MissionStatus.ACCOMPLISHED );
		
		return true;
		
	else
		if showProgress then
			--print( "popup incoming!" );
			ScriptManager:preparePopupText();
			ScriptManager:addPopupTextParameter( "y", neededToWin );
			ScriptManager:addPopupTextParameter( "x", #unitsInGoal );
			ScriptManager:displaySubtitleAutoEx( Text.T_CAMP_X3_1_PRIMARY1_COUNTER, false );
			ScriptManager:wait( 2.5 );
		end
		
		return false;
	end
end

function onEndLeft( tileX, tileY, playerId, unitTemplateId, unitId )
	if leftCheck( unitId ) == true then
	
		-- only show if it is relevant ( = the barricades are gone and the player should leave now )
		if ScriptManager:getMissionStatus( missionIds.clearPath ) == MissionStatus.ACCOMPLISHED then
			if checkEndZoneObjective( true ) then
				startVictoryCutscene();
			end
		end
	end
end

function leftCheck( unitId )
	--print( unitId )
	local returnValue = false;
	if #unitsInGoal >= 1 then
		for i = 1, #unitsInGoal do
			if unitsInGoal[i] == unitId then
				unitsInGoal = Utils:removeValueFromTableAndSave( unitId, "goalUnits", unitsInGoal );
				--table.remove( unitsInGoal, i );
				--ScriptManager:deleteValue( string.format( "goalUnits_%i", unitId ) );
				--print( "removed! units in goal: " .. #unitsInGoal );
				returnValue = true;
				break;
			end
		end
	end
	
	return returnValue;
end


-- END Cross Map Stuff
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	local progress = ScriptManager:getMissionProgress( missionIds.destroySpies );
	
	if progress == 0 then -- no spies caught
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_VICTORY_FLAVOR1, 4 );
	
	elseif progress == #spyIds then
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_VICTORY_FLAVOR2, 4 );
	
	else
		Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_VICTORY_FLAVOR3, 4 );
	end
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_X3_1_VICTORY_FLAVOR4, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	if ScriptManager:getMissionProgress( missionIds.destroySpies ) > 0 then
		ScriptManager:setMissionStatus( missionIds.destroySpies, MissionStatus.ACCOMPLISHED );
	end
	
	ScriptManager:displaySubtitle( Text.T_MISSION_VICTORY );
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end


-- END Victory
-- BEGIN Defeated


function checkForEnd()
	if ScriptManager:noUnitsLeftExt( { 0, Units.N_MINE_LAND } ) then
		transitionToFail();
	end
end

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


-- END Defeated