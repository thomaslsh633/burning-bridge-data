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
	{ missionIds.followInstructions, true, Text.T_TUTORIAL_PRIMARY, 75 },
};

--[[
		I do all unit selecting, moving, attacking, etc. with the tables below ( camera movements are still magic numbers ), 
		So if you want / have to change anything, correct the position in the table and it should work ( except if it is out of range ). 
		BUT DO NOT CHANGE THE ORDER WITHIN THE TABLES, everything works with it, so unless you want to change everything leave it =)
]]

-- order in the table will be tank, mg, at, mg
playerUnitIds	= { 3, 4, 5, 2 };
mgNestIds		= { 6, 0 };
mgNestPos		= { 6, 5 };
scoutPlaneId	= 7;
airfieldTiles	= { { 3, 2 }, { 4, 2 }, };

playerUnitStartPos = {
	{ 5, 7 }, -- tank
	{ 7, 4 }, -- mg1
	{ 5, 4 }, -- at
	{ 6, 6 }, -- mg2 - for mg-nest
};

unitsToDef = 0;
unitDefStatus = { 0, 0, 0 }; -- tank, mg, at; 0 = normal, 1 = fortified, 2 = fortified & camouflaged

playerReinforcements = { Units.TUT_L_TRUCK_TRANSPORT, Units.TUT_L_INFANTRY_ENGINEER, Units.TUT_L_ARTILLERY_AA, Units.TUT_L_ARTILLERY_AA };
aaGunIds			 = { { -1, 0 }, { -1, 0 } };
unloadedAas			 = 0;
playerReinforcementsPos = {
	{ 0, 11 },-- spawn
	{ 2, 11 },-- spawnMove
	{ 3,  7 },-- playerMove1
	{ 4,  5 },-- playerMove2
};

transportUnloadPos = {
	{ 4, 7 },-- aa1
	{ 4, 6 },-- aa2
	{ 5, 5 },-- engineer
};

-- position the units move to in the first turn
playerUnitFirstMove = {
	{ 8,  9 }, -- at, silent run scouting pos
	{ 6,  9 }, -- tank1
	{ 7, 10 }, -- tank2
	{ 8, 10 }, -- light tank
};

buildingPositions = {
	{ 5, 6 }, -- depot
	{ 3, 3 }, -- airfield
};

engineerPositions = {
	{ 7, 6 }; -- move
	{ 7, 7 }; -- set mine
	{ 6, 7 }, -- build mg nest
};

-- enemy attackers that spawn in a cutscene
enemyAttackers = {
--	templateID, 				pos
	{ Units.TUT_X_TANK_MEDIUM,	10, 4 },
	{ Units.TUT_X_INFANTRY_MG,	10, 5 },
	{ Units.TUT_X_INFANTRY_MG,	11, 6 },
	{ Units.TUT_X_INFANTRY_AT,	11, 4 },
	{ Units.TUT_X_PLANE_LIGHT,	11, 5 },
	{ Units.TUT_X_PLANE_LIGHT,	10, 3 },
	{ Units.TUT_X_INFANTRY_AT,	11, 7 },
};

enemyAttackerIds = {};

-- positions the attackers move after spawning, also the final position of the enemy
attackerMovePos = {
	{ 7, 7 }, -- tank
	{ 8, 6 }, -- mg1
	{ 8, 6 }, -- mg2
	{ 8, 7 }, -- at1
	{ 6, 8 }, -- bomber
	{ 7, 3 }, -- light fighter
	{ 8, 7 }, -- at2
};

lightFighterMove	= { 6, 4 };
planeDiscoverTile	= { 4, 3 };
heavyFighterMove	= { 6, 2 };

playerUnitAttackMove = {
	{ 7, 6 }, -- mgTruck
	{ 6, 6 }, -- at
};


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
		ScriptManager:setControllerCursorPosition( 10, 12 );
	end
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_INTRO_FLAVOR1, 5 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_INTRO_FLAVOR2, 4 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_INTRO_FLAVOR3 );
	Utils:antiRush();
	
	ScriptManager:moveUnitEx( scoutPlaneId, airfieldTiles[2][1], airfieldTiles[2][2], true );
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_INTRO_FLAVOR4, 5 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_INTRO_FLAVOR5, 5 );
	
	Utils:endCutscene();
	ScriptManager:disableAllTilesExcept( 0, 0 );
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus(		missionIds.followInstructions, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionProgress(	missionIds.followInstructions, 0 );
	ScriptManager:wait( 3 );
	
	firstExplanations();
end


-- END Intro Cutscene
-- BEGIN Defense Preparations


function firstExplanations()
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR1 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerUnitStartPos[4][1], playerUnitStartPos[4][2] );

	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_MG, -1, "occupyMgNest", "occupyMgNest" );
end

function occupyMgNest()
	Utils:tutorialFunctionInit( "occupyMgNest", false, true );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( mgNestPos[1], mgNestPos[2] );
	
	ScriptManager:addOnUnitSelectedTrigger( -1, Units.TUT_N_EMPLACEMENT_MG_NEST, -1, "removeMarker",	"removeMarker" );
	ScriptManager:addOnUnitOccupiedTrigger(  0, Units.TUT_L_INFANTRY_MG,		 -1, "mgNestEntered",	"mgNestEntered" );
end

function mgNestEntered()
	Utils:tutorialFunctionInit( "mgNestEntered", true, false );
	
	prepareFortify();
end

function prepareFortify()
	Utils:tutorialFunctionInit( "prepareFortify", true, false );
	ScriptManager:disableAllInteractionButtons();
	
	unitsToDef = checkDefense( 1, "fortifyUnit", #unitDefStatus, playerUnitIds, playerUnitStartPos );
	
	if unitsToDef == 0 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR4 );
		
	elseif unitsToDef == 1 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR5 );
		
	elseif unitsToDef == 3 then
		incomingReinforcements();
	end
end

function fortifyUnit( unit )
	Utils:tutorialFunctionInit( "fortifyUnit", true, true );
	
	local templateId = unit:getTemplateId();
	
	if templateId == Units.TUT_L_TANK_MEDIUM then
		unitDefStatus[1] = 1;
	
	elseif templateId == Units.TUT_L_INFANTRY_MG then
		unitDefStatus[2] = 1;
	
	elseif templateId == Units.TUT_L_INFANTRY_AT then
		unitDefStatus[3] = 1;
	end
	
	if unitsToDef == 0 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR6 );
	end
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.FORTIFY );
	
	-- TODO: controller for ability
	
	ScriptManager:addOnInteractionButtonDeselectedTrigger( 0, -1, -1, InteractionButton.FORTIFY, "prepareFortify", "prepareFortify" );
end

function incomingReinforcements()
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_PRIMARY_FLAVOR7, 2 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR8 );
	ScriptManager:moveCameraEx( 1, 11, 0.7, 2, false );
	Utils:antiRush();
	
	local transporterId;
	for i = 1, #playerReinforcements do
		local unit = ScriptManager:spawnUnit( 0, playerReinforcements[i], playerReinforcementsPos[1][1], playerReinforcementsPos[1][2], 0 );
		
		if i == 1 then
			transporterId = unit:getId();
		
		elseif i > 2 then
			aaGunIds[i-2][1] = unit:getId();
		end
	end
	
	ScriptManager:moveUnitEx( transporterId, playerReinforcementsPos[2][1], playerReinforcementsPos[2][2], true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR10 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerReinforcementsPos[2][1], playerReinforcementsPos[2][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TRUCK_TRANSPORT, -1, "transporterSelected", "transporterSelected" );
end


-- END Defense Preparations
-- BEGIN Reinforcements


function transporterSelected()
	Utils:tutorialFunctionInit( "transporterSelected", false, true );
	
	local tileX = playerReinforcementsPos[3][1];
	local tileY = playerReinforcementsPos[3][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx( tileX, tileY, 0.7, 2, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										 "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_TRUCK_TRANSPORT, -1, false, "unloadAa",	 "unloadAa" );
end

function unloadAa( buttonTag, tileY, playerId, unitTemplateId, unitId )
	Utils:tutorialFunctionInit( "unloadAa", true, true );
	ScriptManager:wait( 0.25 );
	-- i call this function on two occasions: when the aa enters a tile or when i deselect the unload mode
	-- as i am lazy, i just check here that the first variable ( which would be posX in enter tile ) is not a button tag
	-- therefore i know whether or not an aa has been unloaded and can count towards moving on
	if buttonTag ~= InteractionButton.TRANSPORT_UNLOAD_2 and buttonTag ~= InteractionButton.TRANSPORT_UNLOAD_2 then
		unloadedAas = unloadedAas + 1;
	end
	
	if unloadedAas == 3 then -- 3 because 1x arriving with the transporter on that tile and 2x unloading aa
		moveTransporterFurther()
		
	else
		ScriptManager:wait( 0.25 );
		Utils:tutorialEnableAndBlockButton(		InteractionButton.TRANSPORT_UNLOAD_1 );
		Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSPORT_UNLOAD_2 );
		Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSPORT_UNLOAD_3 );
		
		ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_TRUCK_TRANSPORT, -1, -1, "unloadModeActive", "unloadModeActive" );
	end
end

function unloadModeActive()
	Utils:tutorialFunctionInit( "unloadModeActive", false, false );
	
	for i = InteractionButton.TRANSPORT_UNLOAD_2, InteractionButton.TRANSPORT_UNLOAD_3 do
		ScriptManager:stopHighlightingInteractionButton( i );	
		ScriptManager:blockInteractionButton( i );
	end
	
	local tileX, tileY;
	for i = 1, 2 do
		tileX = transportUnloadPos[i][1];
		tileY = transportUnloadPos[i][2];
		
		if Unit:getUnitAt( tileX, tileY ) == nil then
			Utils:tutorialAttackOrMovePreparationAddTile( tileX, tileY, true );
			
			ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										"removeMarker",	"removeMarker" );
			ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_ARTILLERY_AA, -1, false,	"unloadAa",		"unloadAa" );
		end
	end
end

function moveTransporterFurther()
	Utils:tutorialFunctionInit( "", false, false );
	
	local tileX = playerReinforcementsPos[4][1];
	local tileY = playerReinforcementsPos[4][2];
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR11 );
	ScriptManager:moveCameraEx( tileX, tileY, 0.7, 1, true );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0, 										 "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_TRUCK_TRANSPORT, -1, false, "finalPos",	 "finalPos" );
end

function finalPos()
	Utils:tutorialFunctionInit( "finalPos", true, false );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_TRUCK_TRANSPORT, -1, -1, "unloadEngineer", "unloadEngineer" );
end

function unloadEngineer()
	Utils:tutorialFunctionInit( "unloadEngineer", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	local tileX = transportUnloadPos[3][1];
	local tileY = transportUnloadPos[3][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0, 											"removeMarker",		"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_INFANTRY_ENGINEER, -1, false,	"readyToUpgrade",	"readyToUpgrade" );
end

function readyToUpgrade()
	Utils:tutorialFunctionInit( "readyToUpgrade", true, false );
	
	Utils:tutorialEnableAndBlockButton( InteractionButton.TRANSFORM );
	
	ScriptManager:enableInteractionButton(	InteractionButton.TRANSFORM + 1 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR12 );
	
	ScriptManager:startHighlightingInteractionButton( InteractionButton.TRANSFORM + 1 );
	
	ScriptManager:addOnTransformedTrigger( 0, Units.TUT_L_TRUCK_MG, -1, "mgTruckReady", "mgTruckReady" );
end


-- END Reinforcements
-- BEGIN Final Preparations


function mgTruckReady()
	Utils:tutorialFunctionInit( "mgTruckReady", true, false );
	
	ScriptManager:disableAllInteractionButtons();
	
	unitsToDef = 0;
	
	prepareCamouflage();
end

function prepareCamouflage()
	Utils:tutorialFunctionInit( "prepareCamouflage", true, false );
	ScriptManager:disableAllInteractionButtons();
	
	for i = 1, #aaGunIds do
		if aaGunIds[i][2] == 0 then
			local aa = Unit:getUnitById( aaGunIds[i][1] )
			Utils:tutorialSelectionPreparationAddTile( aa:getX(), aa:getY(), true );
			
			ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_ARTILLERY_AA, -1, "camouflageUnit", "camouflageUnit" );
		end
	end
	
	if unitsToDef == 0 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR15 );
		
	elseif unitsToDef == 2 then
		Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_PRIMARY_FLAVOR16, 5 );
		
		endOfTurn( Text.T_TUTORIAL_TURN_END );
	end
end

function camouflageUnit( unit )
	Utils:tutorialFunctionInit( "camouflageUnit", true, true );
	
	if unitsToDef == 0 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR18 );
		
	else
		ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR17 );
	end
	
	for i = 1, #aaGunIds do
		if aaGunIds[i][1] == unit:getId() then
			aaGunIds[i][2] = 1;
			break;
		end
	end
	unitsToDef = unitsToDef + 1;
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.CAMOUFLAGE );
	
	-- TODO: controller for ability
	
	ScriptManager:addOnInteractionButtonDeselectedTrigger( 0, -1, -1, InteractionButton.CAMOUFLAGE, "prepareCamouflage", "prepareCamouflage" );
end

function startSecondPlayerTurn()
	Utils:tutorialFunctionInit( "", false, false );
	ScriptManager:stopHighlightingEndTurnButton();
	ScriptManager:disableEndTurnButton();
	Utils:antiRush();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR19 );
	
	Utils:tutorialSelectionPreparationNoFinger( transportUnloadPos[3][1], transportUnloadPos[3][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, "engineerExplanation", "engineerExplanation" );
end

function engineerExplanation()
	Utils:tutorialFunctionInit( "engineerExplanation", true, true );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_PRIMARY_FLAVOR20, 5 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR21 );
	
	local tileX = engineerPositions[1][1];
	local tileY = engineerPositions[1][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7,1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0, "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger( tileX, tileY, 0, Units.TUT_L_INFANTRY_ENGINEER, -1, false, "mineLayMode", "mineLayMode" );
end

function mineLayMode()
	Utils:tutorialFunctionInit( "mineLayMode", true, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR22 );
	Utils:tutorialEnableAndHighlightButton(	InteractionButton.LAY_MINES );
	Utils:tutorialEnableAndBlockButton(		InteractionButton.DETECT_MINES );
	Utils:tutorialEnableAndBlockButton(		InteractionButton.DISARM_MINE );
		
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, InteractionButton.LAY_MINES,
														 "setLandMine", "setLandMine" );
end

function setLandMine()
	Utils:tutorialFunctionInit( "setLandMine", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.LAY_MINES );
	
	Utils:tutorialSelectionPreparationNoFinger( engineerPositions[2][1], engineerPositions[2][2] );
	
	-- will trigger after setting the mine!
	ScriptManager:addOnUnitCreatedTrigger( 0, Units.TUT_N_MINE_LAND, "buildMgNest", "buildMgNest" );
end

function buildMgNest()
	Utils:tutorialFunctionInit( "buildMgNest", false, true );
	ScriptManager:wait( 0.5 );
	ScriptManager:disableAllInteractionButtons();
	
	Utils:tutorialEnableAndBlockButton( InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_MG_NEST );
	Utils:tutorialEnableAndBlockButton( InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_METAL );
	Utils:tutorialEnableAndBlockButton( InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_WIRE );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_PRIMARY_FLAVOR23, 4 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR24 );
	Utils:tutorialEnableAndHighlightButton( InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_MG_NEST );

	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_MG_NEST,
														 "selectMgNestSpot", "selectMgNestSpot" );
end

function selectMgNestSpot()
	Utils:tutorialFunctionInit( "selectMgNestSpot", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.BUILDER + Units.TUT_N_EMPLACEMENT_MG_NEST );
	
	local tileX = engineerPositions[3][1];
	local tileY = engineerPositions[3][2];
	
	Utils:tutorialSelectionPreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY,	 0,								 "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitCreatedTrigger(				-1, Units.TUT_N_EMPLACEMENT_MG_NEST, "enterMgNest",	 "enterMgNest" );
end

function enterMgNest( mgNest )
	Utils:tutorialFunctionInit( "enterMgNest", true, true );
	
	mgNestIds[2] = mgNest:getId();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR25 );
	
	Utils:tutorialSelectionPreparationNoFinger( engineerPositions[3][1], engineerPositions[3][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( -1, Units.TUT_N_EMPLACEMENT_MG_NEST, -1, "removeMarker", 	"removeMarker" );
	ScriptManager:addOnUnitOccupiedTrigger(  0, Units.TUT_L_INFANTRY_ENGINEER,	 -1, "readyForAssault",	"readyForAssault" );
end

function readyForAssault()
	Utils:tutorialFunctionInit( "readyForAssault", true, false )
	
	endOfTurn( Text.T_TUTORIAL2_PRIMARY_FLAVOR27 );
end

-- END Final Preparations
-- BEGIN Enemy Assault


function startThirdPlayerTurn()
	Utils:tutorialFunctionInit( "", true, false )
	ScriptManager:stopHighlightingEndTurnButton();
	ScriptManager:disableEndTurnButton();
	
	ScriptManager:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR28 );
	
	for i = 1, #enemyAttackers do
		local unitId = Utils:spawnUnitFromShortTable( 1, 0, enemyAttackers[i] );
		
		table.insert( enemyAttackerIds, unitId );
	end
	ScriptManager:moveCameraEx( 8, 6, 0.7, 2, true );
	
	local attacker = enemyAttackerIds[2];
	ScriptManager:moveUnitEx( attacker, attackerMovePos[2][1], attackerMovePos[2][2], true );-- mg 1 moves
	ScriptManager:dismissSubtitle();
	
	ScriptManager:fortifyUnit(	attacker, true );
	ScriptManager:attackUnitEx( attacker, playerUnitIds[2], true );-- mg1 attacks player mg
	Unit:getUnitById( playerUnitIds[2] ):setHealth( 140 );
	
	ScriptManager:attackUnitEx( mgNestIds[1], attacker, true );
	
	attacker = enemyAttackerIds[1];
	local tank = Unit:getUnitById( attacker );
	tank:setAttacksPerTurn( 0 ); -- prevent tank from attacking after hitting the mine
	ScriptManager:moveUnitEx( attacker, attackerMovePos[1][1], attackerMovePos[1][2], true );
	
	enemyAttackMove( 4, 1 );-- at moves and attacks tank
	ScriptManager:attackUnitEx( mgNestIds[2], enemyAttackerIds[4], true ); -- mgNest kills at
	
	enemyAttackMove( 7, 1 );-- at 2 moves and attacks tank
	
	-- give player tank attack back as it was not a replay until now but a cutscene and the cutscene attack removes the attack per round
	local playerTank = Unit:getUnitById( playerUnitIds[1] );
	playerTank:setAttacksPerTurn( 1 );
	
	local attacker = enemyAttackerIds[3];
	ScriptManager:moveUnitEx(	attacker, attackerMovePos[3][1], attackerMovePos[3][2], true );-- mg 1 moves	
	ScriptManager:fortifyUnit(	attacker, true );
	ScriptManager:attackUnitEx( attacker, playerUnitIds[2], true );-- mg1 attacks player mg
	
	enemyAttackMove( 5, 1 ); -- plane attacks player tank
	playerTank:setHealth( 350 ); -- cheat more hp to the tank
	
	local bomber = enemyAttackerIds[5];
	ScriptManager:attackUnitEx( aaGunIds[1][1], bomber, true );
	ScriptManager:attackUnitEx( aaGunIds[2][1], bomber, true );
	
	enemyAttackMove( 6, 2 ); -- light fighter destroys player mg
	
	Utils:endCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_PRIMARY_FLAVOR29, 3 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR30 );
	
	local tileX = airfieldTiles[2][1];
	local tileY = airfieldTiles[2][2];
	
	Utils:tutorialSelectionPreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx( tileX, tileY, 0.7, 2, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_PLANE_LIGHT, -1, "planeSelected", "planeSelected" );
end

function enemyAttackMove( attackerIndex, playerIndex )
	local attacker = enemyAttackerIds[attackerIndex];
	ScriptManager:moveUnitEx( attacker, attackerMovePos[attackerIndex][1], attackerMovePos[attackerIndex][2], true );
	ScriptManager:attackUnitEx( attacker, playerUnitIds[playerIndex], true );
end

function planeSelected()
	Utils:tutorialFunctionInit( "planeSelected", true, true );
	
	local tileX = lightFighterMove[1];
	local tileY = lightFighterMove[2]; 
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR31 );
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0, "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger( planeDiscoverTile[1], planeDiscoverTile[2], 0, Units.TUT_L_PLANE_LIGHT, -1, false, 
										 "enemyDiscovered", "enemyDiscovered" );
end

function enemyDiscovered()
	Utils:tutorialFunctionInit( "enemyDiscovered", true, false );
	
	local tileX = lightFighterMove[1];
	local tileY = lightFighterMove[2]; 
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR32 );
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,									 "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_PLANE_LIGHT, -1, false, "planeAttack",	 "planeAttack" );
end

function planeAttack()
	Utils:tutorialFunctionInit( "planeAttack", true, false );
	
	local tileX = attackerMovePos[6][1];
	local tileY = attackerMovePos[6][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_PLANE_LIGHT, -1, "removeMarker",		"removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_PLANE_LIGHT, -1, "selectAirfield",	"selectAirfield" );
end

function selectAirfield()
	Utils:tutorialFunctionInit( "selectAirfield", false, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR33 );
	
	local posX = buildingPositions[2][1];
	local posY = buildingPositions[2][2];
	
	Utils:tutorialSelectionPreparationScaleMarker(	posX, posY, 1.2 );
	ScriptManager:moveCameraEx(						posX, posY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_BUILDING_AIRFIELD, -1, "buyHeavyFighter", "buyHeavyFighter" );
end

function buyHeavyFighter()
	Utils:tutorialFunctionInit( "buyHeavyFighter", true, true );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.REINFORCEMENT + Units.TUT_L_PLANE_HEAVY );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, InteractionButton.REINFORCEMENT + Units.TUT_L_PLANE_HEAVY,
														 "selectHeavyFighterTile", "selectHeavyFighterTile" );
end

function selectHeavyFighterTile()
	Utils:tutorialFunctionInit( "selectHeavyFighterTile", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.REINFORCEMENT + Units.TUT_L_PLANE_HEAVY );
	
	Utils:tutorialSelectionPreparationNoFinger( airfieldTiles[1][1], airfieldTiles[1][2] );
	
	ScriptManager:addOnUnitDeselectedTrigger( 0, Units.TUT_L_BUILDING_AIRFIELD, -1, "moveHeavyFighter", "moveHeavyFighter" );
end

function moveHeavyFighter()
	Utils:tutorialFunctionInit( "moveHeavyFighter", true, true );
	ScriptManager:disableAllInteractionButtons();
	
	local tileX = heavyFighterMove[1];
	local tileY = heavyFighterMove[2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger(	tileX, tileY, 0, 				"removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, -1, -1, false,	"attackPlane",	"attackPlane" );
end

function attackPlane()
	Utils:tutorialFunctionInit( "attackPlane", false, false );
	
	local tileX = attackerMovePos[6][1];
	local tileY = attackerMovePos[6][2];
	ScriptManager:setMissionProgress( missionIds.followInstructions, 1112 );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnUnitSelectedTrigger(	 1, Units.TUT_X_PLANE_LIGHT, -1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.TUT_X_PLANE_LIGHT, -1, "finalAttacks", "finalAttacks" );
end

function finalAttacks()
	Utils:tutorialFunctionInit( "finalAttacks", false, false );
	
	local progress = ScriptManager:getMissionProgress( missionIds.followInstructions )
	
	if progress == 0 then
		startVictoryCutscene();
	
	
	else
		ScriptManager:moveCameraEx( 6, 6, 0.7, 1, true );
		if progress == 1112 then
			ScriptManager:displaySubtitle( Text.T_TUTORIAL2_PRIMARY_FLAVOR34 );
		end
		
		if progress >= 1000 then
			tankSelection();
			progress = progress - 1000;
		end
		
		if  progress >= 100 then
			atInfantrySelection();
			progress = progress - 100;
		end
		
		if progress >= 10 then
			mgTruckSelection();
			progress = progress - 10;
		end
		
		if progress > 0 then
			mgNestSelection();
		end
	end
end

function mgNestSelection()
	local unit;
	for i = 1, #mgNestIds do
		unit = Unit:getUnitById( mgNestIds[i] );
		if unit:hasAttacksLeft() then
			Utils:tutorialSelectionPreparationAddTile( unit:getX(), unit:getY(), true );
			
			ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_N_EMPLACEMENT_MG_NEST, -1, "attackWithMgNest", "attackWithMgNest" );
		end
	end
end

function attackWithMgNest()
	Utils:tutorialFunctionInit( "attackWithMgNest", true, true );
	
	ScriptManager:setMissionProgress( missionIds.followInstructions, ScriptManager:getMissionProgress( missionIds.followInstructions ) - 1 );
	
	local tileX = attackerMovePos[3][1];
	local tileY = attackerMovePos[3][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_INFANTRY_MG,			-1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_N_EMPLACEMENT_MG_NEST, -1, "finalAttacks", "finalAttacks" );
end

function mgTruckSelection()
	Utils:tutorialSelectionPreparationAddTile( playerReinforcementsPos[4][1], playerReinforcementsPos[4][2], true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TRUCK_MG, -1, "moveMgTruck", "moveMgTruck" );
end

function moveMgTruck()
	Utils:tutorialFunctionInit( "moveMgTruck", true, true );
	
	local tileX = playerUnitAttackMove[1][1];
	local tileY = playerUnitAttackMove[1][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,									"removeMarker",		 "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_TRUCK_MG, -1, false,	"attackWithMgTruck", "attackWithMgTruck" );
end

function attackWithMgTruck()
	Utils:tutorialFunctionInit( "attackWithMgTruck", false, false );
	
	ScriptManager:setMissionProgress( missionIds.followInstructions, ScriptManager:getMissionProgress( missionIds.followInstructions ) - 10 );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( attackerMovePos[4][1], attackerMovePos[4][2] );
	
	ScriptManager:addOnUnitSelectedTrigger(	 1, Units.TUT_X_INFANTRY_AT, -1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.TUT_X_INFANTRY_AT, -1, "finalAttacks", "finalAttacks" );
end

function atInfantrySelection()
	Utils:tutorialSelectionPreparationAddTile( playerUnitStartPos[3][1], playerUnitStartPos[3][2], true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_AT, -1, "moveAtInfantry", "moveAtInfantry" );
end

function moveAtInfantry()
	Utils:tutorialFunctionInit( "moveAtInfantry", true, true );
	
	local tileX = playerUnitAttackMove[2][1];
	local tileY = playerUnitAttackMove[2][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,									 "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_INFANTRY_AT, -1, false, "attackWithAt", "attackWithAt" );
end

function attackWithAt()
	Utils:tutorialFunctionInit( "attackWithAt", true, true );
	
	ScriptManager:setMissionProgress( missionIds.followInstructions, ScriptManager:getMissionProgress( missionIds.followInstructions ) - 100 );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( attackerMovePos[1][1], attackerMovePos[1][2] );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_TANK_MEDIUM, -1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_INFANTRY_AT, -1, "finalAttacks", "finalAttacks" );
end

function tankSelection()
	Utils:tutorialSelectionPreparationAddTile( playerUnitStartPos[1][1], playerUnitStartPos[1][2], true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_MEDIUM, -1, "attackWithTank", "attackWithTank" );
end

function attackWithTank()
	Utils:tutorialFunctionInit( "attackWithTank", true, true );
	
	ScriptManager:setMissionProgress( missionIds.followInstructions, ScriptManager:getMissionProgress( missionIds.followInstructions ) - 1000 );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( attackerMovePos[1][1], attackerMovePos[1][2] );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_TANK_MEDIUM, -1, "removeMarker", "removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_TANK_MEDIUM, -1, "finalAttacks", "finalAttacks" );
end


-- END Enemy Assault
-- BEGIN Victory


function startVictoryCutscene()
	ScriptManager:disableAllTilesExcept( 0, 0 );
	ScriptManager:dismissSubtitle();
	
	Utils:setMissionStatus( missionIds.followInstructions, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL2_VICTORY_FLAVOR1, 10 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	Utils:endGame();
end


-- END Victory
-- BEGIN Special Utils


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

function endOfTurn( textkey )
	Utils:tutorialFunctionInit( "endOfTurn", true, true );
	
	ScriptManager:displaySubtitle( textkey );
	
	Utils:antiRush();
	
	ScriptManager:enableEndTurnButton();
	ScriptManager:startHighlightingEndTurnButton();
	
	if ScriptManager:isControllerConnected() then
		-- TODO: when implementing controller give position depending on turn!
		Utils:showControllerButtonGfx( ControllerButton.FACE_UP, 1, 5, 6, false );
	end
	
	ScriptManager:runForPlayer( 1, "skipEnemyTurn" );
end

function skipEnemyTurn()
	ScriptManager:endTurn();
	ScriptManager:dismissSubtitle();
	
	local round = ScriptManager:getCurrentRound();
	
	if round == 0 then
		ScriptManager:runForPlayer( 0, "startSecondPlayerTurn" );
		
	elseif round == 1 then
		ScriptManager:runForPlayer( 0, "startThirdPlayerTurn" );
		
	elseif round == 2 then
		ScriptManager:runForPlayer( 0, "startFourthPlayerTurn" );
	end
end

function checkDefense( wantedState, funcName, numberOfUnits, unitIdTable, unitPosTable )
	local counter = 0;
	
	for i = 1, numberOfUnits do 
		if unitDefStatus[i] == wantedState then
			counter = counter + 1;
			
		else
			Utils:tutorialSelectionPreparationAddTile( unitPosTable[i][1], unitPosTable[i][2], true );
			
			ScriptManager:addOnUnitSelectedTrigger( 0, -1, unitIdTable[i], funcName, funcName );
		end
	end
	
	return counter;
end


-- END Special Utils