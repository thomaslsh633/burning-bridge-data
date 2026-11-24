require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

-- mission stuff
missionIds = {
	followInstructions = 1,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.followInstructions, true, Text.T_TUTORIAL_PRIMARY, 50 },
};

--[[
		I do all unit selecting, moving, attacking, etc. with the tables below ( camera movements are still magic numbers ), 
		So if you want / have to change anything, correct the position in the table and it should work ( except if it is out of range ). 
		BUT DO NOT CHANGE THE ORDER WITHIN THE TABLES, everything works with it, so unless you want to change everything leave it =)
]]

playerUnitIds = { 2, 3, 4, 5 };

playerUnitsStart = {
	{ 3, 8 }, -- mg1
	{ 2, 5 }, -- mg2
	{ 2, 7 }, -- at
	{ 3, 6 }, -- tank
};

-- where the three infantry units will stand after their very first move
playerUnitsFirstMove = {
	{ 5, 8 }, -- mg1
	{ 5, 5 }, -- mg2
	{ 6, 6 }, -- at
	{ 5, 7 }, -- tank
};

enemyUnitIds = { 1, 6, 7 };

-- positions of the mg infantry and light tank next to the depot
enemyDefenderPos = {
	{ 6, 9 }, -- mg-nest
	{ 8, 6 }, -- mg
	{ 7, 7 }, -- at
};

-- the move position the three infantry units will move to in order to make the first attack
playerUnitsAttackMove = {
	{ 6, 9 }, -- mg1
	{ 8, 4 }, -- mg2
};

depotPos			 = { 8, 7 };
playerAtAfterCapture = { 7, 7 };

buyTile	= { 8, 8 };

mgHP	= 0;
tankHP	= 0;
weaknessSubShown = false;


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:disableAICalculation();
	ScriptManager:disableEndTurnButton();
	ScriptManager:disableAllInteractionButtons();
	ScriptManager:disableGlobalAbilityMenu();
	
	-- TODO: only for testing disabled!!!
	ScriptManager:disableSkipReplayButton();
	ScriptManager:disableSkipCutsceneButton();
	
	if ScriptManager:isControllerConnected() then
		ScriptManager:setControllerCursorPosition( 2, 13 );
	end
	
	Utils:camouflageSquad( enemyUnitIds );
	
	mgHP	= Unit:getUnitById( playerUnitIds[1] ):getHealth();
	tankHP	= Unit:getUnitById( playerUnitIds[4] ):getHealth();
		
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_INTRO_FLAVOR1, 6 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_INTRO_FLAVOR2 );
	Utils:antiRush();
	ScriptManager:moveCameraEx( depotPos[1], depotPos[2], 0.7, 4, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_INTRO_FLAVOR3 );
	Utils:markUnit( depotPos[1], depotPos[2], 1, 2, 0 );
	ScriptManager:moveCameraEx( 3, 7, 0.7, 4, true );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	ScriptManager:disableAllTilesExcept( 0, 0 );
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.followInstructions, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionProgress( missionIds.followInstructions, 0 );
	ScriptManager:wait( 3 );
	
	firstExplanations();
end


-- END Intro Cutscene
-- BEGIN First Selection And Movement


function firstExplanations()
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR1, 6 );
	
	local tankX = playerUnitsStart[4][1];
	local tankY = playerUnitsStart[4][2];
	
	ScriptManager:showMarkerAt( 		 tankX, tankY );
	ScriptManager:disableAllTilesExcept( tankX, tankY );
	
	--[[if ScriptManager:isControllerConnected() then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL_CONTROLLER_MOVE_CURSOR );
		
		ScriptManager:addOnControllerSelectedTileTrigger( tankX, tankY, "cursorOverUnitFirstSelection", "cursorOverUnit", false );
	
	else]]
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR2_TOUCH );
	
	ScriptManager:showFingerAtTile( tankX, tankY, 1.5 );
	ScriptManager:loopFingerClicks( 1.5 );
	--end

	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_HEAVY, -1, "firstSelection", "firstSelection" );
end

function cursorOverUnitFirstSelection( tileX, tileY )
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR2_CONTROLLER );
	
	Utils:cursorOverUnitSinglePress( tileX, tileY, false );
end

function firstSelection()
	ScriptManager:hideFinger();
	Utils:tutorialFunctionInit( "firstSelection", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR4 );
	
	local posX = playerUnitsFirstMove[4][1];
	local posY = playerUnitsFirstMove[4][2];
	
	Utils:tutorialAttackOrMovePreparation(	posX, posY );
	ScriptManager:moveCameraEx(				posX, posY, 0.8, 2, true );
	
	ScriptManager:addOnTileSelectedTrigger(		posX, posY, 0, "removeMarker",			 "removeMarker" );
	ScriptManager:addOnTileDeselectedTrigger(	posX, posY, 0, "removeMarkerFingerSubs", "removeMarkerFingerSubs" );
	
	ScriptManager:addOnEnterTileTrigger(		posX, posY, 0, Units.TUT_L_TANK_HEAVY, -1, true, "firstMoveDone", "firstMoveDone" );
end

function firstMoveDone()
	removeMarkerFingerSubs(); -- leave in as long as on tile deselected not working
	Utils:tutorialFunctionInit( "firstMoveDone", true, true  );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR6 );
	
	firstMoveInfantry()
end

function firstMoveInfantry()
	Utils:tutorialFunctionInit( "firstMoveInfantry", false, true );
	
	-- reset the progress count
	ScriptManager:setMissionProgress( missionIds.followInstructions, 0 );
	
	-- enable movement and show a marker at the units that still need to move this turn. for each unit that has to move progress count +1
	for i = 1, #playerUnitsFirstMove do
		enableMovement( playerUnitIds[i], playerUnitsFirstMove[i][1], playerUnitsFirstMove[i][2], "infantryFirstMoveSelected" )
	end
	
	-- if the progress is still 0, no unit need to move => all units have moved. so the tutorial can move on
	if ScriptManager:getMissionProgress( missionIds.followInstructions ) == 0 then
		Utils:hideDialogue();
		Utils:cleanupController();
		
		ScriptManager:moveCameraEx( 5, 7, 0.7, 3, false );
		ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR7_3 );-- turn end text
		ScriptManager:wait( 2 );
		
		ScriptManager:enableEndTurnButton();
		ScriptManager:startHighlightingEndTurnButton();
		
		if ScriptManager:isControllerConnected() then
			Utils:showControllerButtonGfx( ControllerButton.FACE_UP, 1, 3, 11, false );
		end
		
		ScriptManager:runForPlayer( 1, "skipFirstEnemyTurn" );
			
	else
		ScriptManager:moveCameraEx( 3, 6, 0.7, 1, true );
			
		if ScriptManager:isControllerConnected() then
			ScriptManager:setControllerCursorEnabled( true );
		end
	end
end

function infantryFirstMoveSelected( unit )
	Utils:tutorialFunctionInit( "infantryFirstMoveSelected", true, true );
	
	local unitId = unit:getId();
	local posX, posY;
	
	local progress = ScriptManager:getMissionProgress( missionIds.followInstructions );
	
		if progress == 3 then
			ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR3 );
		
		elseif progress == 2 then
			ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR5 );
		end
	
	-- go through the infantry units and find the unit that is currently selected and give it the move order to the position it has to move
	for i = 1, #playerUnitIds - 1 do -- - 1 cause the tank already moved
		if unitId == playerUnitIds[i] then
			posX = playerUnitsFirstMove[i][1];
			posY = playerUnitsFirstMove[i][2];
			
			Utils:tutorialAttackOrMovePreparationNoFinger( posX, posY );
			ScriptManager:moveCameraEx( posX, posY, 0.7,1, true );
			
			ScriptManager:addOnTileSelectedTrigger( posX, posY, 0, "removeMarker", "removeMarker" );
														
			-- after move go back to steps and check if there are still units that need to be moved
			ScriptManager:addOnEnterTileTrigger( posX, posY, 0, -1, unitId, true, "firstMoveInfantry", "firstMoveInfantry" );
			break;
		end
	end
end


-- END My First Selection And Movements
-- BEGIN First Blood


function skipFirstEnemyTurn()
	ScriptManager:endTurn();
	ScriptManager:stopHighlightingEndTurnButton();
	ScriptManager:disableEndTurnButton();
	ScriptManager:dismissSubtitle();
	
	ScriptManager:runForPlayer( 0, "startSecondPlayerTurn" );
end


function startSecondPlayerTurn()
	ScriptManager:disableEndTurnButton();
	for i = 1, #playerUnitIds do
		if i ~= 2 then
			local unit = Unit:getUnitById( playerUnitIds[i] )
			unit:setAttacksPerTurn( 2 );
		end
	end
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR7_1 );
	
	ScriptManager:attackUnitEx( enemyUnitIds[1], playerUnitIds[1], true );-- mgnest -> mg1
	Utils:antiRush();
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR7_2 );
	Utils:antiRush();
	
	ScriptManager:attackUnitEx( enemyUnitIds[2], playerUnitIds[3], true );-- mg -> mg2
	Utils:antiRush();
	
	ScriptManager:attackUnitEx( enemyUnitIds[3], playerUnitIds[4], true );-- at -> tank
	Utils:antiRush();
	Utils:hideDialogue();
	
	Utils:endCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR8 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerUnitsFirstMove[4][1], playerUnitsFirstMove[4][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_HEAVY, -1, "tankReadyForAttack", "tankReadyForAttack" );
end

function tankReadyForAttack()
	Utils:tutorialFunctionInit( "tankReadyForAttack", false, true );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( enemyDefenderPos[1][1], enemyDefenderPos[1][2] );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_N_EMPLACEMENT_MG_NEST, -1, "removeMarker",		"removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_TANK_HEAVY,			-1, "tankHasAttacked",	"tankHasAttacked" );
end

function tankHasAttacked()
	Utils:tutorialFunctionInit( "tankHasAttacked", true, true );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR9, 3 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR10, 6 );
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR11 );
	
	infantryToAttackPosition();
end

function infantryToAttackPosition()
	Utils:tutorialFunctionInit( "infantryToAttackPosition", false, true );
	
	-- reset the progress count
	ScriptManager:setMissionProgress( missionIds.followInstructions, 0 ); -- could use a variable, but i decided for the progress
	
	ScriptManager:moveCameraEx( 5, 6, 0.7, 1, true );
	
	-- enable movement and show a marker at the units that still need to move this turn. for each unit that has yet tomove progress count +1
	for i = 1, #playerUnitsAttackMove do
		enableMovement( playerUnitIds[i], playerUnitsAttackMove[i][1], playerUnitsAttackMove[i][2], "checkSelectedInfantry" )
	end
	
	-- if the progress is still 0, no unit need to move => all units have moved. so the tutorial can move on
	if ScriptManager:getMissionProgress( missionIds.followInstructions ) == 0 then
		selectInfantryToCapture();
			
	else -- there are still units to move so enable the cursor for controller ( tiles and input already unblocked in enableMovement )
		if ScriptManager:isControllerConnected() then
			ScriptManager:setControllerCursorEnabled( true );
		end
	end
end

function checkSelectedInfantry( unit )
	Utils:tutorialFunctionInit( "checkSelectedInfantry", true, true );
	
	local unitId = unit:getId();
	
	if unitId == playerUnitIds[1] then -- infantry that needs to be instant supplied
		Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR12, 7 );
		
		ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR13 );
		
		Utils:tutorialEnableAndHighlightButton( InteractionButton.INSTANT_SUPPLY_SINGLE );
		
		-- TODO: controller for ability
		
		ScriptManager:addOnInteractionButtonDeselectedTrigger(  0, Units.TUT_L_INFANTRY_MG, -1, InteractionButton.INSTANT_SUPPLY_SINGLE, 
																"infantryResupplied", "infantryResupplied" );
	
	else
		infantryIntoAttackRangeSelected( unitId, playerUnitsAttackMove[2][1], playerUnitsAttackMove[2][2] );
	end
end

function infantryResupplied()
	Utils:tutorialDisableButton( InteractionButton.INSTANT_SUPPLY_SINGLE );
	Utils:tutorialFunctionInit( "infantryResupplied", true, true );
	Utils:antiRush();	
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR14 );
		
	infantryIntoAttackRangeSelected( playerUnitIds[1], playerUnitsAttackMove[1][1], playerUnitsAttackMove[1][2] );
end

function infantryIntoAttackRangeSelected( unitId, movePosX, movePosY )
	Utils:tutorialFunctionInit( "infantryIntoAttackRangeSelected", false, true );
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	movePosX, movePosY );
	ScriptManager:moveCameraEx(						movePosX, movePosY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( movePosX, movePosY, 0,					 "removeMarkerHideSubs", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	movePosX, movePosY, 0, -1, unitId, true, "firstAttackInfantry",	 "firstAttackInfantry" );
end

function firstAttackInfantry( tileX, tileY, playerId, unitTemplateId, unitId )
	Utils:tutorialFunctionInit( "firstAttackInfantry", false, true );
	
	if weaknessSubShown == false then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR15 );
		weaknessSubShown = true;
	end
	
	local posX, posY;	
	-- check which infantry was selected and show information about it and a marker on its target 
	if unitId == playerUnitIds[1] then
		posX = enemyDefenderPos[3][1];
		posY = enemyDefenderPos[3][2];

	else
		posX = enemyDefenderPos[2][1];
		posY = enemyDefenderPos[2][2];
	end
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	posX, posY );
	ScriptManager:moveCameraEx(						posX, posY, 0.7, 1, true );
	
	-- no need to check for specify units as there is only one unit clickable, 
	-- i do it normally though to make it clearer what happens but here i dont want to just copy paste the same stuff
	ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "removeMarkerFingerSubs", "removeMarker" );
	
	-- after the attack is done move back to check if there is still infantry that needs to move & attack
	ScriptManager:addOnUnitHasAttackedTrigger( 0, -1, -1, "infantryToAttackPosition", "infantryToAttackPosition" );
end


-- END First Blood
-- BEGIN Capture Depot And Supply


function selectInfantryToCapture()
	Utils:tutorialFunctionInit( "", false, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR16 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerUnitsFirstMove[3][1], playerUnitsFirstMove[3][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_AT, -1, "captureDepot", "captureDepot" );
end

function captureDepot()
	Utils:tutorialFunctionInit( "captureDepot", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR17 );
	
	local posX = depotPos[1];
	local posY = depotPos[2];
	
	Utils:tutorialAttackOrMovePreparationScaleMarker(	posX, posY, 1.2 );
	ScriptManager:moveCameraEx(							posX, posY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 1, Units.TUT_X_BUILDING_HQ, -1, "removeMarker",  "removeMarker" );
	ScriptManager:addOnUnitCapturedTrigger( 0, Units.TUT_X_BUILDING_HQ, -1, "depotCaptured", "depotCaptured" );
end

function depotCaptured()
	Utils:tutorialFunctionInit( "depotCaptured", true, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR18 );
	
	Utils:tutorialSelectionPreparationScaleMarker( depotPos[1], depotPos[2], 1.2 );

	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_X_BUILDING_HQ, -1, "depotSelected", "depotSelected" );
end

function depotSelected()
	ScriptManager:removeTrigger( "unitSupplied" );
	Utils:tutorialFunctionInit( "depotSelected", true, true );
	
	ScriptManager:disableComponent( 0, ComponentType.DEALER, 0 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR19 );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.SUPPLY );
	
	if ScriptManager:isControllerConnected() then
		Utils:showControllerButtonGfx( ControllerButton.FACE_DOWN, depotPos[1], depotPos[2], 2, false );
	end
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_X_BUILDING_HQ, -1, InteractionButton.SUPPLY, "depotInSupplyMode", "depotInSupplyMode" );
end

function depotInSupplyMode()
	Utils:tutorialFunctionInit( "depotInSupplyMode", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.SUPPLY );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( playerAtAfterCapture[1], playerAtAfterCapture[2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_AT, -1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitSuppliedTrigger( 0, Units.TUT_L_INFANTRY_AT, -1, "unitSupplied", "unitSupplied" );
end

function unitSupplied()
	Utils:tutorialFunctionInit( "unitSupplied", true, false );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR20, 5 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR21, 4 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR22 );
	
	ScriptManager:enableComponent( 0, ComponentType.DEALER, 0 );
	Utils:tutorialEnableAndHighlightButton( InteractionButton.REINFORCEMENT + Units.TUT_L_TRUCK_SUPPLY );
	
	if ScriptManager:isControllerConnected() then
		Utils:showControllerButtonGfx( ControllerButton.FACE_DOWN, 1, depotPos[1], depotPos[2], false );
	end
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, InteractionButton.REINFORCEMENT + Units.TUT_L_TRUCK_SUPPLY,
														 "selectBuyTile", "selectBuyTile" );
end

function selectBuyTile()
	Utils:tutorialDisableButton( InteractionButton.REINFORCEMENT + Units.TUT_L_TRUCK_SUPPLY );
	ScriptManager:removeTrigger( "selectBuyTile" );
	Utils:cleanupController()
	Utils:hideAllMarkers();
	
	Utils:tutorialSelectionPreparationNoFinger( buyTile[1], buyTile[2] );
	
	ScriptManager:addOnUnitDeselectedTrigger( 0, Units.TUT_X_BUILDING_HQ, -1, "supplyWithTruck", "supplyWithTruck" );
end

function supplyWithTruck()
	Utils:tutorialFunctionInit( "supplyWithTruck", true, true );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_PRIMARY_FLAVOR23, 4 );
	ScriptManager:moveCameraEx( buyTile[1], buyTile[2], 0.7, 1, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL1_PRIMARY_FLAVOR24 );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( playerUnitsFirstMove[4][1], playerUnitsFirstMove[4][2] );
		
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_HEAVY, -1, "removeMarker",			"removeMarker" );
	ScriptManager:addOnUnitSuppliedTrigger( 0, Units.TUT_L_TANK_HEAVY, -1, "startVictoryCutscene",	"startVictoryCutscene" );
end


-- BEGIN Capture Depot And Supply
-- BEGIN Victory


function startVictoryCutscene()
	Utils:tutorialFunctionInit( "", true, true );
	
	Utils:setMissionStatus( missionIds.followInstructions, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL1_VICTORY_FLAVOR, 6 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	Utils:endGame();
end


-- END Victory
-- BEGIN Special Utils


function cursorOverUnitSinglePressEnable(  tileX, tileY )
	Utils:cursorOverUnitSinglePress( tileX, tileY, true );
end

function cursorOverUnitDoublePressEnable(  tileX, tileY )
	Utils:cursorOverUnitDoublePress( tileX, tileY, true );
end

function removeMarkerFingerSubs()
	removeMarkerAndFinger();
	Utils:hideDialogue();
end

function removeMarkerAndFinger()
	ScriptManager:removeTrigger( "removeMarker" );
	Utils:hideAllMarkers();
end

function removeMarkerHideSubs()
	removeMarker()
	Utils:hideDialogue();
end

function removeMarker()
	ScriptManager:removeTrigger( "removeMarker" );
	ScriptManager:removeAllMarkers();
end

function enableMovement( unitId, targetPosX, targetPosY, triggerName )
	local unit = Unit:getUnitById( unitId );
	local posX = unit:getX();
	local posY = unit:getY();
	
	-- if unit not at target location than enable movement there
	if posX ~= targetPosX or posY ~= targetPosY then		
		ScriptManager:enableAdditionalTile( posX, posY );
		ScriptManager:showMarkerAt( posX, posY );
		
		if ScriptManager:isControllerConnected() then
			ScriptManager:addOnControllerSelectedTileTrigger( posX, posY, "cursorOverUnitSinglePressEnable", "cursorOverUnit" );
		end
		
		ScriptManager:addOnUnitSelectedTrigger( 0, -1, unitId, triggerName, triggerName );
		
		Utils:incrementMissionProgress( missionIds.followInstructions );
	end
end


-- END Special Utils