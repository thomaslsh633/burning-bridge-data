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
	{ missionIds.followInstructions, true, Text.T_TUTORIAL_PRIMARY, 125 },
};

--[[
		I do all unit selecting, moving, attacking, etc. with the tables below ( camera movements are still magic numbers ), 
		So if you want / have to change anything, correct the position in the table and it should work ( except if it is out of range ). 
		BUT DO NOT CHANGE THE ORDER WITHIN THE TABLES, everything works with it, so unless you want to change everything leave it =)
]]

bridgeId		= 5;
playerStartIds	= { 2, 3, 4, 0, 1, }; -- order in the table is mortar, tank, engineer, mg1, mg2
enemyStartIds	= { 6, 7, 9, 8 }; -- order in the table is hTank, mTank, mg1, mg2

playerUnitStartPos = {
	{ 4,  6 }, -- mortar
	{ 3,  5 }, -- tank
	{ 4,  5 }, -- engineer
	{ 4,  9 }, -- mg1
	{ 5, 11 }, -- mg2
};

enemyUnitsIntroMove	= {
	{ 6, 10 }, -- hTank
	{ 4, 11 }, -- mTank
	{ 4, 10 }, -- mg1
};

bridgeTiles = {
	{ 4, 7 }, -- center
	{ 4, 6 }, -- bot left
	{ 5, 8 }, -- top right
};

playerReinforcements = {
	--	templateID, 				pos
	{ Units.TUT_L_PLANE_TRANSPORT,	2, 0 },
	{ Units.TUT_L_PLANE_TRANSPORT,	6, 0 },
	{ Units.TUT_L_TANK_DESTROYER,	4, 0 },
	{ Units.TUT_L_INFANTRY_MG,		2, 6 }, -- = movePos of transport plane1
	{ Units.TUT_L_INFANTRY_FLAME,	6, 6 }, -- = movePos of transport plane2
};

playerReinforcementIds = {}; -- filled after spawn, transportPlane1, transportPlane2, dTank, mg, flame

playerReinforcementMove = {
	{ 2, 6 }, -- plane1
	{ 6, 6 }, -- plane2
	{ 3, 4 }, -- dTank
};

-- reinforcements + mortar
counterAttackMove = {
	{ 3, 10 }, -- plane1
	{ 7,  8 }, -- plane2
	{ 5,  8 }, -- mortar
	{ 4,  9 }, -- mTank
	{ 4,  6 }, -- dTank
};

aoeTile			= { 5, 10 };
airstrikeTile	= { 5, 11 };

enemyReinforcements = {
	--	templateID, 				pos
	{ Units.TUT_X_TANK_HEAVY,	5, 16 },
	{ Units.TUT_X_TANK_HEAVY,	5, 16 },
	{ Units.TUT_X_TANK_MEDIUM,	5, 16 },
	{ Units.TUT_X_INFANTRY_AT,	5, 16 },
};

enemyReinforcementIds = {};

enemyReinforcementMove = {
	{ 5, 12 }, -- hTank1 -> mTank
	{ 4, 13 }, -- hTank2 -> mg left
	{ 5, 13 }, -- mTank
	{ 3, 13 }, -- at
	{ 6, 11 }, -- enemyStartIds[4] mg -> mg right
};

fallbackPos = {
	{ 1, 3 }, -- plane1
	{ 6, 2 }, -- plane2
	{ 3, 2 }, -- dTank
};

retreatInfantryPos = { 7, 9 };

rubberBoatTiles = {
	{ 6, 7 }, -- in
	{ 5, 5 }, -- move
	{ 5, 4 }, -- out
};

mortarSmokeTile = {
	{ 3, 5 }, -- move
	{ 5, 9 }, -- shoot
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	ScriptManager:gainGold( 0, 1500 );
	
	ScriptManager:disableAICalculation();
	ScriptManager:disableEndTurnButton();
	ScriptManager:disableAllInteractionButtons();
	
	ScriptManager:disableGlobalAbilityMenu();
	ScriptManager:disableGlobalAbilityButton(	GlobalAbility.AIRSTRIKE );
	ScriptManager:enableGlobalAbilityButton(	GlobalAbility.AIRSTRIKE_TUT );
	
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.AIRSTRIKE_TUT );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.BLIMB );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.PARATROOPER );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.RADAR );
	ScriptManager:blockGlobalAbilityButton( GlobalAbility.SUPPLY_CRATE );
	
	-- TODO: only for testing disabled!!!
	ScriptManager:disableSkipReplayButton();
	ScriptManager:disableSkipCutsceneButton();
	
	if ScriptManager:isControllerConnected() then
		ScriptManager:setControllerCursorPosition( 10, 12 );
	end
	
	local playerMg2 = Unit:getUnitById( playerStartIds[5] );
	playerMg2:setHealth( playerMg2:getHealth() * 0.3 );
	
	local enemyMg1 = Unit:getUnitById( enemyStartIds[3] );
	enemyMg1:setHealth( enemyMg1:getHealth() * 0.75 );
	
	ScriptManager:fortifyUnit( enemyStartIds[1], true );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_INTRO_FLAVOR1 );
	
	ScriptManager:attackUnitEx( enemyStartIds[4], playerStartIds[5], true );
	
	attackMove( 3, playerStartIds[4] );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_INTRO_FLAVOR2 );
	attackMove( 2, playerStartIds[4] );
	
	ScriptManager:moveCameraEx( bridgeTiles[1][1], bridgeTiles[1][2], 0.7, 2, false );
	attackMove( 1, bridgeId );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	ScriptManager:disableAllTilesExcept( 0, 0 );
	
	startTheMission();
end

function attackMove( enemyIndex, defenderId )
	ScriptManager:moveUnitEx(	enemyStartIds[enemyIndex], enemyUnitsIntroMove[enemyIndex][1], enemyUnitsIntroMove[enemyIndex][2], true );
	ScriptManager:attackUnitEx( enemyStartIds[enemyIndex], defenderId, true );
end

function startTheMission()
	ScriptManager:setMissionStatus(		missionIds.followInstructions, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionProgress(	missionIds.followInstructions, 0 );
	ScriptManager:wait( 3 );
	
	firstExplanations();
end


-- END Intro Cutscene
-- BEGIN Bridge


function firstExplanations()
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL3_PRIMARY_FLAVOR1, 5 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL3_PRIMARY_FLAVOR2, 5 );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR3 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerUnitStartPos[3][1], playerUnitStartPos[3][2] );

	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, "enterRepairMode", "enterRepairMode" );
end

function enterRepairMode()
	Utils:tutorialFunctionInit( "enterRepairMode", true, true )
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR4 );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.REPAIR_BRIDGE );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, InteractionButton.REPAIR_BRIDGE,
														 "repairBridge", "repairBridge" );
end

function repairBridge()
	Utils:tutorialFunctionInit( "repairBridge", true, true );
	
	Utils:tutorialBlockButton( InteractionButton.REPAIR_BRIDGE );
	
	bridgeSelection();
	
	ScriptManager:addOnBridgeRepairTrigger( 0, -1, -1, "reinforcementCutscene", "reinforcementCutscene" );
end


-- END Bridge
-- BEGIN Reinforcements & Counter Attack

function reinforcementCutscene()
	Utils:tutorialFunctionInit( "reinforcementCutscene", true , false );
	
	ScriptManager:disableAllInteractionButtons();
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR5 );
	ScriptManager:moveCameraEx( 3, 5, 0.7, 3, false );
	
	for i = 1, #playerReinforcements do
		local id = Utils:spawnUnitFromShortTable( 0, 0, playerReinforcements[i] );
		table.insert( playerReinforcementIds, id );
		
		-- dont move the 2 mgs
		if i < #playerReinforcements - 1 then
			ScriptManager:moveUnitEx( id, playerReinforcementMove[i][1], playerReinforcementMove[i][2], true );
		end
	end
	
	Utils:endCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR6 );
	
	Utils:tutorialSelectionPreparationNoFinger( playerUnitStartPos[1][1], playerUnitStartPos[1][2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_MORTAR, -1, "moveMortar", "moveMortar" );
end

function moveMortar()
	Utils:tutorialFunctionInit( "moveMortar", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR7 );
	
	local tileX = counterAttackMove[3][1];
	local tileY = counterAttackMove[3][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										 "removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_INFANTRY_MORTAR, -1, false, "aoeMode",			"aoeMode" );
end

function aoeMode()
	Utils:tutorialFunctionInit( "aoeMode", true, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR8 );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.ATTACK );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_MORTAR, -1, InteractionButton.ATTACK,
														 "attackWithMortar", "attackWithMortar" );
end

function attackWithMortar()
	Utils:tutorialFunctionInit( "attackWithMortar", true, false );
	
	Utils:tutorialBlockButton( InteractionButton.ATTACK );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR9 );
	
	local tileX = aoeTile[1];
	local tileY = aoeTile[2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx(tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY,	0,									"removeMarker", "removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(				0, Units.TUT_L_INFANTRY_MORTAR, -1, "selectTank",	"selectTank" );
end

function selectTank()
	Utils:tutorialFunctionInit( "selectTank", true, false );
	
	ScriptManager:disableAllInteractionButtons();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR10 );
	
	local tileX = playerUnitStartPos[2][1];
	local tileY = playerUnitStartPos[2][2];
	
	Utils:tutorialSelectionPreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx(					tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_MEDIUM, -1, "moveTank", "moveTank" );
end

function moveTank()
	Utils:tutorialFunctionInit( "moveTank", true, true );
	
	local tileX = counterAttackMove[4][1];
	local tileY = counterAttackMove[4][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,									"removeMarker",		"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_TANK_MEDIUM, -1, true, "attackWithTank",	"attackWitTank" );
end

function attackWithTank()
	Utils:tutorialFunctionInit( "attackWithTank", false, false );
	
	Utils:tutorialAttackOrMovePreparationNoFinger( enemyUnitsIntroMove[2][1], enemyUnitsIntroMove[2][2] );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_TANK_MEDIUM, -1, "removeMarker",		"removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_TANK_MEDIUM, -1, "selectDestroyer",	"selectDestroyer" );
end

function selectDestroyer()
	Utils:tutorialFunctionInit( "selectDestroyer", false, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR11 );
	
	local tileX = playerReinforcementMove[3][1];
	local tileY = playerReinforcementMove[3][2];
	
	Utils:tutorialSelectionPreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx(					tileX, tileY, 0.7, 1, true );	
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_TANK_DESTROYER, -1, "moveDestroyer", "moveDestroyer" );
end

function moveDestroyer()
	Utils:tutorialFunctionInit( "moveDestroyer", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR12 );
	
	local tileX = counterAttackMove[5][1];
	local tileY = counterAttackMove[5][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										"removeMarker",			"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_TANK_DESTROYER, -1, false, "attackWithDestroyer",	"attackWithDestroyer" );
end

function attackWithDestroyer()
	Utils:tutorialFunctionInit( "attackWithDestroyer", true, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR13 );
	
	local tileX = enemyUnitsIntroMove[1][1];
	local tileY = enemyUnitsIntroMove[1][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger(		1, Units.TUT_X_TANK_HEAVY,		-1, "removeMarker",		"removeMarker" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, Units.TUT_L_TANK_DESTROYER,	-1, "gaIntroduction",	"gaIntroduction" );
end


-- END Reinforcements & Counter Attack
-- BEGIN Global Abilities
 

function gaIntroduction()
	Utils:tutorialFunctionInit( "gaIntroduction", true, false );
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL3_PRIMARY_FLAVOR14, 3 );
	
	ScriptManager:enableGlobalAbilityMenu();
	ScriptManager:openGlobalAbilityMenu();
	ScriptManager:blockGlobalAbilityMenu();
		
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR15 );
	ScriptManager:wait( 2 );
	
	ScriptManager:unblockGlobalAbilityButton(			GlobalAbility.AIRSTRIKE_TUT );
	ScriptManager:startHighlightingGlobalAbilityButton( GlobalAbility.AIRSTRIKE_TUT );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, -1, -1, GlobalAbility.AIRSTRIKE_TUT, "selectAirstrikeTarget", "selectAirstrikeTarget" );
end

function selectAirstrikeTarget()
	Utils:tutorialFunctionInit( "selectAirstrikeTarget", true, false );
	
	ScriptManager:stopHighlightingGlobalAbilityButton(	GlobalAbility.AIRSTRIKE_TUT );
	ScriptManager:blockGlobalAbilityButton(				GlobalAbility.AIRSTRIKE_TUT );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR16 );
	
	local tileX = airstrikeTile[1];
	local tileY = airstrikeTile[2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger(								 tileX, tileY, 0,	"removeMarker",		"removeMarker" );
	ScriptManager:addOnAirstrikeTrigger( GlobalAbility.AIRSTRIKE_TUT, 0, tileX, tileY,	 	"transportPlanes",	"transportPlanes" );
end


-- END Global Abilities
-- BEGIN Prepare for Enemy


function transportPlanes()
	Utils:tutorialFunctionInit( "transportPlanes", true, false );
	
	ScriptManager:closeGlobalAbilityMenu();	
	ScriptManager:blockGlobalAbilityMenu();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR17  );
	
	selectPlanes();
end

function selectPlanes()
	Utils:tutorialFunctionInit( "selectPlanes", false, false );
	
	Utils:tutorialDisableButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	-- reset progress
	ScriptManager:setMissionProgress( missionIds.followInstructions, 0 );
	
	for i = 1, 2 do	
		local tileX = playerReinforcementMove[i][1];
		local tileY = playerReinforcementMove[i][2];
		
		if Unit:getUnitAt( tileX, tileY ) ~= nil then
			Utils:tutorialSelectionPreparationAddTile( tileX, tileY, true );
			
			Utils:incrementMissionProgress( missionIds.followInstructions );
		end
	end
	
	if ScriptManager:getMissionProgress( missionIds.followInstructions ) == 0 then
		-- both planes already moved, move on
		endOfTurn();
	else
		ScriptManager:moveCameraEx( 4, 6, 0.7, 1, true );
		ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_PLANE_TRANSPORT, -1, "movePlanes", "movePlanes" );
	end
end

function movePlanes( tPlane )
	Utils:tutorialFunctionInit( "movePlanes", true, true );
	
	local unitId = tPlane:getId();
	local indicator = 0;
	
	-- find out which plane is selected and use the pos for the movement
	if unitId == playerReinforcementIds[1] then
		indicator = 1;
	else
		indicator = 2;
	end
	
	local progress = ScriptManager:getMissionProgress( missionIds.followInstructions );
	if progress == 2 then
		ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR18 );
	
	else
		ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR19 );
	end
	
	local tileX = counterAttackMove[indicator][1];
	local tileY = counterAttackMove[indicator][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										 "removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_PLANE_TRANSPORT, -1, false, "enterUnloadMode", "enterUnloadMode" );
end

function enterUnloadMode()
	Utils:tutorialFunctionInit( "enterUnloadMode", false, false );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_PLANE_TRANSPORT, -1, InteractionButton.TRANSPORT_UNLOAD_1,
														 "unloadUnit", "unloadUnit" );
end

function unloadUnit( buttonTag, unit )
	Utils:tutorialFunctionInit( "unloadUnit", true, false );
	
	Utils:tutorialBlockButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	-- unload pos
	local tileX = unit:getX();
	local tileY = unit:getY() + 1;
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,				 "removeMarker", "removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0 , -1, -1, false, "selectPlanes", "selectPlanes" );
end


-- END Prepare for Enemy
-- BEGIN Enemy Assault


function startSecondPlayerTurn()
	Utils:tutorialFunctionInit( "", true, true );
	ScriptManager:stopHighlightingEndTurnButton();
	ScriptManager:disableEndTurnButton();
	
	-- Ids of the two units that will be destroyed by enemy heavy tanks
	local hTankVictims = { playerStartIds[2], playerReinforcementIds[4] };
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR20 );
	ScriptManager:moveCameraEx( 4, 11, 0.7, 2, false );
	
	for i = 1, #enemyReinforcements do
		local unitId = Utils:spawnUnitFromShortTable( 1, 0, enemyReinforcements[i] );
		
		table.insert( enemyReinforcementIds, unitId );
		
		ScriptManager:moveUnitEx( unitId, enemyReinforcementMove[i][1], enemyReinforcementMove[i][2], true );
		
		-- both heavy tanks attack
		if i <= 2 then
			Utils:killUnit( unitId, hTankVictims[i] );
			Utils:hideDialogue();
			
		elseif i == 3 then
			ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR21 );
		end
	end

	ScriptManager:moveUnitEx(	enemyStartIds[4], enemyReinforcementMove[5][1], enemyReinforcementMove[5][2], true );
	ScriptManager:attackUnitEx( enemyStartIds[4], playerReinforcementIds[5], true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR22 );
	ScriptManager:moveCameraEx( 5, 8, 0.7, 2, false );
	
	-- planes + dTank move back
	for i = 1, #fallbackPos do
		ScriptManager:moveUnitEx( playerReinforcementIds[i], fallbackPos[i][1], fallbackPos[i][2], true );
	end
	Utils:hideDialogue();
	
	Utils:endCutscene();
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR23 );
		
	Utils:tutorialSelectionPreparationNoFinger( retreatInfantryPos[1], retreatInfantryPos[2] );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_FLAME, -1, "enterRubberboatMode", "enterRubberboatMode" );
end

function enterRubberboatMode()
	Utils:tutorialFunctionInit( "enterRubberboatMode", true, true );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSFORM );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_FLAME, -1, InteractionButton.TRANSFORM, "enterBoat", "enterBoat" );
end

function enterBoat()
	Utils:tutorialFunctionInit( "enterBoat", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.TRANSFORM );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR24 );
	
	local tileX = rubberBoatTiles[1][1];
	local tileY = rubberBoatTiles[1][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY,	0,									"removeMarker", "removeMarker" );
	ScriptManager:addOnTransformedTrigger(					0, Units.TUT_L_SHIP_RUBBERBOAT, -1, "crossRiver",	"crossRiver" );
end

function crossRiver()
	Utils:tutorialFunctionInit( "crossRiver", true, false );
	
	ScriptManager:disableInteractionButton( InteractionButton.TRANSFORM );
	
	local tileX = rubberBoatTiles[2][1];
	local tileY = rubberBoatTiles[2][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										 "removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_SHIP_RUBBERBOAT, -1, false, "enterUnloadBoat",	"enterUnloadBoat" );
end

function enterUnloadBoat()
	Utils:tutorialFunctionInit( "enterUnloadBoat", false, false );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_SHIP_RUBBERBOAT, -1, InteractionButton.TRANSPORT_UNLOAD_1,
														 "unloadFlame", "unloadFlame" );
end

function unloadFlame()
	Utils:tutorialFunctionInit( "unloadFlame", false, false );
	
	Utils:tutorialBlockButton( InteractionButton.TRANSPORT_UNLOAD_1 );
	
	local tileX = rubberBoatTiles[3][1];
	local tileY = rubberBoatTiles[3][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger( tileX, tileY );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										"removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_INFANTRY_FLAME, -1, false, "selectMortar",	"selectMortar" );
end

function selectMortar()
	Utils:tutorialFunctionInit( "selectMortar", false, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR25 );
	
	local posX = counterAttackMove[3][1];
	local posY = counterAttackMove[3][2];
	
	Utils:tutorialSelectionPreparationNoFinger( posX, posY );
	ScriptManager:moveCameraEx(					posX, posY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_MORTAR, -1, "mortarFallBack", "mortarFallBack" );
end

function mortarFallBack()
	Utils:tutorialFunctionInit( "mortarFallBack", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR26 );
	
	local tileX = mortarSmokeTile[1][1];
	local tileY = mortarSmokeTile[1][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnTileSelectedTrigger( tileX, tileY, 0,										 "removeMarker",	"removeMarker" );
	ScriptManager:addOnEnterTileTrigger(	tileX, tileY, 0, Units.TUT_L_INFANTRY_MORTAR, -1, false, "enterSmokeMode",	"enterSmokeMode" );
end

function enterSmokeMode()
	Utils:tutorialFunctionInit( "enterSmokeMode", true, false );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.SMOKEMORTAR );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_MORTAR, -1, InteractionButton.SMOKEMORTAR,
														 "shootSmoke", "shootSmoke" );
end

function shootSmoke()
	Utils:tutorialFunctionInit( "shootSmoke", true, false );
	
	Utils:tutorialBlockButton( InteractionButton.SMOKEMORTAR );
	
	local tileX = mortarSmokeTile[2][1];
	local tileY = mortarSmokeTile[2][2];
	
	Utils:tutorialAttackOrMovePreparationNoFinger(	tileX, tileY );
	ScriptManager:moveCameraEx(						tileX, tileY, 0.7, 1 , true );
	
	ScriptManager:addOnTileSelectedTrigger(								 tileX, tileY, 0,	"removeMarker",		"removeMarker" );
	ScriptManager:addOnSmokeTrigger( 0, Units.TUT_L_INFANTRY_MORTAR, -1, tileX ,tileY,		"selectEngineer",	"selectEngineer" );
end

function selectEngineer()
	Utils:tutorialFunctionInit( "selectEngineer", false, false );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR27 );
	
	local tileX = playerUnitStartPos[3][1];
	local tileY = playerUnitStartPos[3][2];
	
	Utils:tutorialSelectionPreparationNoFinger( tileX, tileY );
	ScriptManager:moveCameraEx(					tileX, tileY, 0.7, 1, true );
	
	ScriptManager:addOnUnitSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, "enterDetonateMode", "enterDetonateMode" );
end

function enterDetonateMode()
	Utils:tutorialFunctionInit( "enterDetonateMode", true, true );

	ScriptManager:displaySubtitle( Text.T_TUTORIAL3_PRIMARY_FLAVOR28 );
	
	Utils:tutorialEnableAndHighlightButton( InteractionButton.DETONATE_BRIDGE );
	
	ScriptManager:addOnInteractionButtonSelectedTrigger( 0, Units.TUT_L_INFANTRY_ENGINEER, -1, InteractionButton.DETONATE_BRIDGE, "detonateBridge", "detonateBridge" );
end

function detonateBridge()
	Utils:tutorialFunctionInit( "detonateBridge", true, false );
	
	Utils:tutorialBlockButton( InteractionButton.DETONATE_BRIDGE );
	
	bridgeSelection()
	
	ScriptManager:addOnBridgeDetonateTrigger( -1, Units.N_BRIDGE_L, -1, "startVictoryCutscene", "startVictoryCutscene" );
end


-- END Enemy Assault
-- BEGIN Victory


function startVictoryCutscene()
	ScriptManager:disableAllTilesExcept( 0, 0 );
	ScriptManager:dismissSubtitle();
	
	Utils:setMissionStatus( missionIds.followInstructions, MissionStatus.ACCOMPLISHED );
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL3_VICTORY_FLAVOR1, 6 );
	Utils:displaySubtitleWithDuration( Text.T_TUTORIAL3_VICTORY_FLAVOR2, 5 );
	
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

function bridgeSelection()
	ScriptManager:showScaledMarkerAt( bridgeTiles[1][1], bridgeTiles[1][2], 1.5, true, true );
--	ScriptManager:showScaledMarkerAt( bridgeTiles[1][1], bridgeTiles[1][2], 1, false, true );
--	ScriptManager:showScaledMarkerAt( bridgeTiles[1][1], bridgeTiles[1][2], 3, false, false );
	for i = 1, #bridgeTiles do
		ScriptManager:enableAdditionalTile( bridgeTiles[i][1], bridgeTiles[i][2] );
		
		ScriptManager:addOnUnitSelectedTrigger( 0, Units.N_BRIDGE_L, -1, "removeMarker", "removeMarker" );
	end
end

function endOfTurn()
	Utils:tutorialFunctionInit( "endOfTurn", true, true );
	
	ScriptManager:displaySubtitle( Text.T_TUTORIAL_TURN_END );
	
	Utils:antiRush();
	
	ScriptManager:enableEndTurnButton();
	ScriptManager:startHighlightingEndTurnButton();
	
	if ScriptManager:isControllerConnected() then
		-- TODO: when implementing controller give position depending on turn! turn one: 3 | 11
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


-- END Special Utils