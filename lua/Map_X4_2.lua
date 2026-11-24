require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


PLAYER_ID = 0;
AI_ID = 1;

ENEMY_TANKFACTORY_UNIT_ID = 8;

ENEMY_SPY_CARS_TO_DESTROY = 5;
ENEMY_SPY_CARS_TO_DETECT = 3;
ROADBLOCKS_TO_DESTROY = 2;
ENEMY_ARTILLERIES_TO_DESTROY = 4;
NUMBER_OF_ROADBLOCK_UNITS_NORTH = 6;
NUMBER_OF_ROADBLOCK_UNITS_SOUTH = 6;

-- mission stuff
missionIds = {
	DESTROY_ENEMY_SPY_CARS = 1,
	DESTROY_ROADBLOCKS = 2,
	DESTROY_ENEMY_ARTILLERY = 3,
	DETECT_ENEMY_SPY_CARS = 4,
	CAPTURE_DESTROY_TANKFACTORY = 5
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{missionIds.DESTROY_ENEMY_SPY_CARS, true, Text.T_CAMP_X4_2_PRIMARY1, 100},
	{missionIds.DESTROY_ROADBLOCKS, true, Text.T_CAMP_X4_2_PRIMARY2, 100},
	{missionIds.DESTROY_ENEMY_ARTILLERY, false, Text.T_CAMP_X4_2_SECONDARY1, 50},
	{missionIds.DETECT_ENEMY_SPY_CARS, false, Text.T_CAMP_X4_2_SECONDARY2, 50},
	{missionIds.CAPTURE_DESTROY_TANKFACTORY, false, Text.T_CAMP_X4_2_SECONDARY3, 50}
};

enemySquadIds = {
	DEFENDER_NORTHERN_FOREST = 1,
	DEFENDER_SOUTHERN_AGRICULTURES = 2,
	DEFENDER_ROADBLOCK_NORTH = 3,
	DEFENDER_ROADBLOCK_SOUTH = 4,
	DEFENDER_TANKFACTORY = 5,
	DEFENDER_PLATEAU = 6,
	DEFENDER_VILLAGE_SOUTH = 7,
	DEFENDER_VILLAGE_NORTH = 8,
	
	BUNKER_NORTHERN_ROADBLOCK_ONE = 11,
	BUNKER_NORTHERN_ROADBLOCK_TWO = 12,
	BUNKER_SOUTHERN_ROADBLOCK_ONE = 13,
	BUNKER_SOUTHERN_ROADBLOCK_TWO = 14,
	MG_NEST_NORTHERN_VILLAGE = 15,
	
	SNIPER_PLATEAU = 21,
	SNIPER_SOUTHERN_VILLAGE = 22,
	
	ARTILLERY_NORTHERN_FOREST = 31,
	ARTILLERY_AGRICULTURES = 32,
	ARTILLERY_SOUTHERN_VILLAGE = 33,
	ARTILLERY_TANKFACTORY = 34,
	
	BARRICADE_ROADBLOCK_NORTH = 41,
	BARRICADE_ROADBLOCK_SOUTH = 42,
	
	MINES = 50,
};

spyCarStatus = {
	NOT_REVEALED = 0,
	REVEALED = 1,
	DEAD = 1,
};

enemySpyCarUnitIds = {2, 3, 4, 5, 6};
-- 0 = not revealed, 1 = revealed, -1 = dead
enemySpyCarsRevealed = {0, 0, 0, 0, 0};

enemyArtilleryUnitIds = {31, 36, 35, 47};

enemySpyCarsDestroyed = 0;
enemySpyCarsDetected = 0;
roadblocksDestroyed = 0;
artilleryDestroyed = 0;
northernRoadblockUnitsDestroyed = 0;
southernRoadblockUnitsDestroyed = 0;
spyCarCutsceneShown = 0;

cutsceneHighlightX = -1;
cutsceneHighlightY = -1;

-- #######################################-START_GAME-#######################################

function onGameStart()
	Utils:createMissions(missions);
	setTriggers();
	storeValues();
	addAiOrders();
	
	ScriptManager:gainGold(PLAYER_ID, 1250);
	ScriptManager:blockGlobalAbilityButton(GlobalAbility.BLIMB);
	
	for i = 1, #enemySpyCarUnitIds do
		if(Unit:getUnitById(enemySpyCarUnitIds[i]) ~= nil) then
			Unit:getUnitById(enemySpyCarUnitIds[i]):setCanBeCaptured(false);
		end
	end
	
	-- start intro cutscene
	ScriptManager:sleep(0, "startIntroCutscene"); -- without sleep player turn popup shows
end

function storeValues()
	Utils:saveValuesIntoSavefileForExistingTable("enemySpyCarsRevealed", enemySpyCarsRevealed);
	
	ScriptManager:storeValue("enemySpyCarsDestroyed", enemySpyCarsDestroyed);
	ScriptManager:storeValue("enemySpyCarsDetected", enemySpyCarsDetected);
	ScriptManager:storeValue("roadblocksDestroyed", roadblocksDestroyed);
	ScriptManager:storeValue("artilleryDestroyed", artilleryDestroyed);
	ScriptManager:storeValue("northernRoadblockUnitsDestroyed", northernRoadblockUnitsDestroyed);
	ScriptManager:storeValue("southernRoadblockUnitsDestroyed", southernRoadblockUnitsDestroyed);
	ScriptManager:storeValue("spyCarCutsceneShown", spyCarCutsceneShown);
	
	ScriptManager:storeValue("cutsceneHighlightX", cutsceneHighlightX);
	ScriptManager:storeValue("cutsceneHighlightY", cutsceneHighlightY);
end

function loadValues()
	for i = 1, #enemySpyCarUnitIds do
		if(Unit:getUnitById(enemySpyCarUnitIds[i]) ~= nil) then
			Unit:getUnitById(enemySpyCarUnitIds[i]):setCanBeCaptured(false);
		end
	end
	
	if(ScriptManager:getMissionStatus(missionIds.DETECT_ENEMY_SPY_CARS) ~= MissionStatus.ACCOMPLISHED) then
		ScriptManager:addOnRadarTrigger(GlobalAbility.RADAR, PLAYER_ID, -1, -1, "onRadar", "onRadar");
	end
	
	enemySpyCarsRevealed = Utils:loadValuesFromSavefileIntoExistingTable("enemySpyCarsRevealed", enemySpyCarsRevealed);

	enemySpyCarsDestroyed = ScriptManager:getValue("enemySpyCarsDestroyed");
	enemySpyCarsDetected = ScriptManager:getValue("enemySpyCarsDetected");
	roadblocksDestroyed = ScriptManager:getValue("roadblocksDestroyed");
	artilleryDestroyed = ScriptManager:getValue("artilleryDestroyed");
	northernRoadblockUnitsDestroyed = ScriptManager:getValue("northernRoadblockUnitsDestroyed");
	southernRoadblockUnitsDestroyed = ScriptManager:getValue("southernRoadblockUnitsDestroyed");
	spyCarCutsceneShown = ScriptManager:getValue("spyCarCutsceneShown");
	
	cutsceneHighlightX = ScriptManager:getValue("cutsceneHighlightX");
	cutsceneHighlightY = ScriptManager:getValue("cutsceneHighlightY");
end

-- #######################################-TRIGGERS-#######################################

function setTriggers()
	local triggerX1, triggerY1 = 9, 15;
	local triggerX2, triggerY2 = 12, 8;
	local triggerRadius = 4;
	
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger("loadValues", "loadValues", false)
	
	ScriptManager:addOnBunkerClearedTrigger(AI_ID, -1, -1, "onEnemyBunkerCleared", "onEnemyBunkerCleared");
	ScriptManager:addOnRadarTrigger(GlobalAbility.RADAR, PLAYER_ID, -1, -1, "onRadar", "onRadar");
	
	ScriptManager:addOnTurnStartTrigger(AI_ID, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart");
	ScriptManager:addOnUnitSightedTrigger(AI_ID, Units.L_TRUCK_RADIO, -1, true, "onEnemySpyCarSighted", "onEnemySpyCarSighted");
	ScriptManager:addOnUnitSightedTrigger(AI_ID, Units.L_ARTILLERY_HOWITZER, -1, true, "onEnemyArtillerySighted", "onEnemyArtillerySighted");
	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, Units.L_ARTILLERY_HOWITZER, -1, "onEnemyArtilleryAttacked", "onEnemyArtilleryAttacked");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, -1, -1, "onEnemyUnitDestroyed", "onEnemyUnitDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_TRUCK_RADIO, -1, "onEnemySpyCarDestroyed", "onEnemySpyCarDestroyed");
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.L_ARTILLERY_HOWITZER, -1, "onEnemyArtilleryDestroyed", "onEnemyArtilleryDestroyed");
	
	ScriptManager:addOnUnitDestroyedTrigger(AI_ID, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankfactoryDestroyed", "onEnemyTankfactoryDestroyed");
	ScriptManager:addOnUnitCapturedTrigger(PLAYER_ID, Units.N_BUILDING_TANKFACTORY, -1, "onEnemyTankfactoryCaptured", "onEnemyTankfactoryCaptured");
	
	Utils:addOnEnterAreaTrigger(triggerX1, triggerY1, triggerRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterArea", "onPlayerEnterArea");
	Utils:addOnEnterAreaTrigger(triggerX2, triggerY2, triggerRadius, PLAYER_ID, -1, -1, true, "onPlayerEnterArea", "onPlayerEnterArea");
	
	-- trigger for main building / unit
--	ScriptManager:addOnUnitHasAttackedTrigger(AI_ID, , -1,	"showAttackedWarning",	"showAttackedWarning" );
--	ScriptManager:addOnUnitHasAttackedTrigger(PLAYER_ID, , -1,	"stopAttackingHint",	"stopAttackingHint" );
--	ScriptManager:addOnUnitDestroyedTrigger(PLAYER_ID, , -1,	"transitionToFail",		"transitionToFail" );
end

function onRadar(targetTileX, targetTileY, enemiesDetected)
	if(enemiesDetected) then
		--print("##################################################____ SOMETHING DETECTED!", enemiesDetected);
		if(checkRadarInsideSpyCarRadius(targetTileX, targetTileY) == true) then
			incrementDetectSpyCarMissionProgress();
			--ScriptManager:runForPlayer(PLAYER_ID, "prepareSpyCarDiscovoredCutscene");
			--print("##################################################____IN SPY CAR RADIUS!");
		else
			--print("##################################################____NOT IN SPY CAR RADIUS!");
		end
	else
		--print("##################################################____ NOTHING DETECTED!");
	end
end

function onPlayerEnterArea()
	ScriptManager:removeTrigger("onPlayerEnterArea");
	
	startRoadblockMissionCutscene();
end

function onEnemyTurnStart(playerId, turnId, roundId)
	reduceEnemyArtilleryActionPoints();
end

function onEnemySpyCarSighted(discoveringUnit, discoveredUnit)
	if(discoveredUnit ~= nil) then
		for i = 1, #enemySpyCarUnitIds do
			if(discoveredUnit:getId() == enemySpyCarUnitIds[i]) then
				if(getEnemySpyCarStatus(discoveredUnit:getId()) ~= spyCarStatus.REVEALED) then
					enemySpyCarsRevealed[i] = 1;
					Utils:saveValuesIntoSavefileForExistingTable("enemySpyCarsRevealed", enemySpyCarsRevealed);
					setCutsceneHighlightX(discoveredUnit:getX());
					setCutsceneHighlightY(discoveredUnit:getY());
					ScriptManager:runForPlayer(PLAYER_ID, "prepareSpyCarDiscovoredCutscene");
				end
			end
		end
	end
end

function onEnemyArtillerySighted(discoveringUnit, discoveredUnit)
	if(discoveredUnit~= nil) then
		ScriptManager:removeTrigger("onEnemyArtillerySighted");
		ScriptManager:removeTrigger("onEnemyArtilleryAttacked");
		
		setCutsceneHighlightX(discoveredUnit:getX());
		setCutsceneHighlightY(discoveredUnit:getY());
		
		ScriptManager:runForPlayer(PLAYER_ID, "prepareArtilleryMissionCutscene");
	end
end

function onEnemyArtilleryAttacked(attackerUnit, isAoe, defenderUnit, defenderUnits, unitsHit)
	if(attackerUnit ~= nil) then
		ScriptManager:removeTrigger("onEnemyArtilleryAttacked");
		ScriptManager:removeTrigger("onEnemyArtillerySighted");
		
		ScriptManager:runForPlayer(PLAYER_ID, "prepareArtilleryMissionCutscene");
	end
end

function onEnemyTankfactoryCaptured(capturingUnit, capturedUnit)
	ScriptManager:removeTrigger("onEnemyTankfactoryCaptured");
	ScriptManager:removeTrigger("onEnemyTankfactoryDestroyed");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_TANKFACTORY, MissionStatus.ACCOMPLISHED);
end

function onEnemyTankfactoryDestroyed(unit)
	ScriptManager:removeTrigger("onEnemyTankfactoryDestroyed");
	ScriptManager:removeTrigger("onEnemyTankfactoryCaptured");
	
	ScriptManager:setMissionStatus(missionIds.CAPTURE_DESTROY_TANKFACTORY, MissionStatus.ACCOMPLISHED);
end

function onEnemyBunkerCleared(flamethrower, bunker)
	if(bunker ~= nil) then
		if(bunker:getSquadId() == enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_ONE) or
			(bunker:getSquadId() == enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_TWO) then
			incrementNorthernRoadblockUnitsDestroyed();
			
			if(getNorthernRoadblockUnitsDestroyed() >= NUMBER_OF_ROADBLOCK_UNITS_NORTH) then
				incrementRoadblockMissionProgress();
			end
		elseif(bunker:getSquadId() == enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_ONE) or
			(bunker:getSquadId() == enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_TWO) then
			incrementSouthernRoadblockUnitsDestroyed();
			
			if(getSouthernRoadblockUnitsDestroyed() >= NUMBER_OF_ROADBLOCK_UNITS_SOUTH) then
				incrementRoadblockMissionProgress();
			end
		end
	end
end

function onEnemyUnitDestroyed(unit)
	if(unit ~= nil) then
		local currentSquadId = unit:getSquadId();
		
		if(currentSquadId == enemySquadIds.DEFENDER_ROADBLOCK_NORTH) or
			(currentSquadId == enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_ONE) or
			(currentSquadId == enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_TWO) or
			(currentSquadId == enemySquadIds.BARRICADE_ROADBLOCK_NORTH) then
			incrementNorthernRoadblockUnitsDestroyed();
			
			if(getNorthernRoadblockUnitsDestroyed() >= NUMBER_OF_ROADBLOCK_UNITS_NORTH) then
				incrementRoadblockMissionProgress();
			end
		elseif(currentSquadId == enemySquadIds.DEFENDER_ROADBLOCK_SOUTH) or
			(currentSquadId == enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_ONE) or
			(currentSquadId == enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_TWO) or
			(currentSquadId == enemySquadIds.BARRICADE_ROADBLOCK_SOUTH) then
			incrementSouthernRoadblockUnitsDestroyed();
			
			if(getSouthernRoadblockUnitsDestroyed() >= NUMBER_OF_ROADBLOCK_UNITS_SOUTH) then
				incrementRoadblockMissionProgress();
			end
		end
	end
end

function onEnemyArtilleryDestroyed(unit)
	incrementArtilleryMissionProgress();
end

function onEnemySpyCarDestroyed(unit)
	incrementDestroySpyCarMissionProgress();
end

function incrementDestroySpyCarMissionProgress()
	incrementEnemySpyCarsDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_SPY_CARS, getEnemySpyCarsDestroyed());
	
	if(getEnemySpyCarsDestroyed() >= ENEMY_SPY_CARS_TO_DESTROY) then
		--Utils:displaySubtitleWithDuration(Text.T_CAMP_L_4_2_SECONDARY1_FLAVOR3, 4);
		ScriptManager:removeTrigger("onEnemySpyCarDestroyed");
		
		ScriptManager:setMissionStatus(missionIds.DESTROY_ENEMY_SPY_CARS, MissionStatus.ACCOMPLISHED);
		checkForVictory();
	else
		ScriptManager:runForPlayer(PLAYER_ID, "prepareSpyCarDestroyedCutscene");
	end
end

function updateDestroySpyCarMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_ENEMY_SPY_CARS), ENEMY_SPY_CARS_TO_DESTROY, Text.T_CAMP_X4_2_PRIMARY1_COUNTER);
end

function incrementDetectSpyCarMissionProgress()
	incrementEnemySpyCarsDetected();
	ScriptManager:setMissionProgress(missionIds.DETECT_ENEMY_SPY_CARS, getEnemySpyCarsDetected());
	
	if(getEnemySpyCarsDetected() >= ENEMY_SPY_CARS_TO_DETECT) then
		ScriptManager:removeTrigger("onRadar");
		
		ScriptManager:setMissionStatus(missionIds.DETECT_ENEMY_SPY_CARS, MissionStatus.ACCOMPLISHED);
	end
	ScriptManager:runForPlayer(PLAYER_ID, "prepareSpyCarDetectedCutscene");
end

function updateDetectSpyCarMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DETECT_ENEMY_SPY_CARS), ENEMY_SPY_CARS_TO_DETECT, Text.T_CAMP_X4_2_SECONDARY2_COUNTER);
end

function incrementArtilleryMissionProgress()
	incrementArtilleryDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_ARTILLERY, getArtilleryDestroyed());
	
	if(getArtilleryDestroyed() >= ENEMY_ARTILLERIES_TO_DESTROY) then
		ScriptManager:removeTrigger("onEnemyArtilleryDestroyed");
		
		ScriptManager:setMissionStatus(missionIds.DESTROY_ENEMY_ARTILLERY, MissionStatus.ACCOMPLISHED);
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateArtilleryMissionProgress");
	end
end

function updateArtilleryMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_ENEMY_ARTILLERY), ENEMY_ARTILLERIES_TO_DESTROY, Text.T_CAMP_X4_2_SECONDARY1_COUNTER);
end

function incrementRoadblockMissionProgress()
	incrementRoadblocksDestroyed();
	ScriptManager:setMissionProgress(missionIds.DESTROY_ROADBLOCKS, getRoadblocksDestroyed());
	
	if(getRoadblocksDestroyed() >= ROADBLOCKS_TO_DESTROY) then
		ScriptManager:removeTrigger("onEnemyUnitDestroyed");
		
		ScriptManager:setMissionStatus(missionIds.DESTROY_ROADBLOCKS, MissionStatus.ACCOMPLISHED);
		checkForVictory();
	else
		ScriptManager:runForPlayer(PLAYER_ID, "updateRoadblockMissionProgress");
	end
end

function updateRoadblockMissionProgress()
	Utils:showMissionProgressTwoVar(ScriptManager:getMissionProgress(missionIds.DESTROY_ROADBLOCKS), ROADBLOCKS_TO_DESTROY, Text.T_CAMP_X4_2_PRIMARY2_COUNTER);
end

-- #######################################-AI_ORDER-#######################################

function addAiOrders()
	local aiRadiusNormal = 2;
	local aiRadiusWide = 3;
	local aiRadiusArti = 4;
	local aiRadiusHowitzer = 6;
	
	ScriptManager:addOrder(enemySquadIds.DEFENDER_NORTHERN_FOREST, 2, 15, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_SOUTHERN_AGRICULTURES, 9, 2, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_ROADBLOCK_NORTH, 10, 17, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_ROADBLOCK_SOUTH, 14, 8, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_TANKFACTORY, 16, 22, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_PLATEAU, 20, 13, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_VILLAGE_SOUTH, 20, 3, -1, aiRadiusNormal, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.DEFENDER_VILLAGE_NORTH, 24, 21, -1, aiRadiusNormal, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_ONE, 11, 18, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_NORTHERN_ROADBLOCK_TWO, 12, 17, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_ONE, 14, 9, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.BUNKER_SOUTHERN_ROADBLOCK_TWO, 15, 7, -1, aiRadiusWide, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.MG_NEST_NORTHERN_VILLAGE, 23, 19, -1, aiRadiusWide, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.SNIPER_PLATEAU, 18, 12, -1, aiRadiusArti, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.SNIPER_SOUTHERN_VILLAGE, 23, 3, -1, aiRadiusArti, AiOrder.DEFEND);
	
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_NORTHERN_FOREST, 4, 18, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_AGRICULTURES, 10, 3, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_SOUTHERN_VILLAGE, 21, 3, -1, aiRadiusHowitzer, AiOrder.DEFEND);
	ScriptManager:addOrder(enemySquadIds.ARTILLERY_TANKFACTORY, 16, 23, -1, aiRadiusHowitzer, AiOrder.DEFEND);
end

-- #######################################-MISSIONS-#######################################

function startMission(missionId)
	ScriptManager:setMissionStatus(missionId, MissionStatus.IN_PROGRESS);
	
	if(missionId == missionIds.DESTROY_ENEMY_SPY_CARS) then
		ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_SPY_CARS, getEnemySpyCarsDestroyed());
	elseif(missionId == missionIds.DESTROY_ROADBLOCKS) then
		ScriptManager:setMissionProgress(missionIds.DESTROY_ROADBLOCKS, getRoadblocksDestroyed());
	elseif(missionId == missionIds.DESTROY_ENEMY_ARTILLERY) then
		ScriptManager:setMissionProgress(missionIds.DESTROY_ENEMY_ARTILLERY, getArtilleryDestroyed());
	end
end

function checkForVictory()
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_SPY_CARS) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_ROADBLOCKS) == MissionStatus.ACCOMPLISHED) then
		startVictoryCutscene();
	elseif(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_SPY_CARS) == MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_ROADBLOCKS) ~= MissionStatus.ACCOMPLISHED) then
		ScriptManager:runForPlayer(PLAYER_ID, "prepareSpyCarDestroyedCutscene");
	elseif(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_SPY_CARS) ~= MissionStatus.ACCOMPLISHED) and
		(ScriptManager:getMissionStatus(missionIds.DESTROY_ROADBLOCKS) == MissionStatus.ACCOMPLISHED) then
		ScriptManager:runForPlayer(PLAYER_ID, "prepareRoadblockAccomplishedCutscene");
	end
end

function showAttackedWarning(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );-- TODO: add templateDI @end
end

function stopAttackingHint(attacker, isAoe, defender, allUnitsHit, unitsHitCount)
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );-- TODO: add templateDI @end
end

-- #######################################-CUTSCENES-#######################################

function startIntroCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_INTRO_FLAVOR1, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_INTRO_FLAVOR2, 4);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(11, 12, 0.4, 2.5, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_PRIMARY1_FLAVOR1, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_PRIMARY1_FLAVOR2, 5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_PRIMARY1_FLAVOR3, 6);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 2.5, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY2_FLAVOR1, 5);
	ScriptManager:wait(0.5);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY2_FLAVOR2, 6);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_ENEMY_SPY_CARS);
	startMission(missionIds.DETECT_ENEMY_SPY_CARS);
	
	ScriptManager:wait(2);
	--[[
	ScriptManager:openGlobalAbilityMenu();
	ScriptManager:wait(2);
	ScriptManager:startHighlightingGlobalAbilityButton(GlobalAbility.RADAR);
	ScriptManager:wait(2);
	ScriptManager:stopHighlightingGlobalAbilityButton(GlobalAbility.RADAR);
	ScriptManager:wait(0.5);--]]
	
	Utils:enablePlayerInteraction();
end

function startRoadblockMissionCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx(14, 8, 0.7, 2, true);
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_PRIMARY2_FLAVOR1, 3);
	ScriptManager:moveCameraEx(11, 17, 0.7, 2, true);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_PRIMARY2_FLAVOR2, 4);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(15, 21, 0.7, 2, true)
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY3_FLAVOR1, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY3_FLAVOR2, 4);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY3_FLAVOR3, 5);
	
	ScriptManager:wait(0.5);
	ScriptManager:moveCameraEx(currentCamX, currentCamY, 0.7, 3, true);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_ROADBLOCKS);
	startMission(missionIds.CAPTURE_DESTROY_TANKFACTORY);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_VICTORY_FLAVOR1, 6);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_VICTORY_FLAVOR2, 3);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_VICTORY_FLAVOR3, 2);
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function prepareSpyCarDetectedCutscene()
	table.insert(queueTable, playSpyCarDetectedCutscene);
	Utils:cutsceneQueue();
end

function playSpyCarDetectedCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(getSpyCarCutsceneShown() < 1) then
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, true);
			ScriptManager:moveCameraEx(getCutsceneHighlightX(), getCutsceneHighlightY(), 0.7, 2, true);
			ScriptManager:showMarkerAt(getCutsceneHighlightX(), getCutsceneHighlightY());
		end
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_DETECTED_FLAVOR1, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_SIGHTED_FLAVOR2, 2);
		--[[
		ScriptManager:runAbility(PLAYER_ID, -1, -1, GlobalAbility.AIRSTRIKE, getCutsceneHighlightX(), getCutsceneHighlightY(), -1);
		ScriptManager:wait(3);
		--]]
		
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, false);
			Utils:hideAllMarkers();
		end
	else
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, true);
			ScriptManager:moveCameraEx(getCutsceneHighlightX(), getCutsceneHighlightY(), 0.7, 2, true);
			ScriptManager:showMarkerAt(getCutsceneHighlightX(), getCutsceneHighlightY());
		end
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_SIGHTED_FLAVOR3, 3);
		
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, false);
			Utils:hideAllMarkers();
		end
	end
	
	Utils:endCutscene();
	
	resetCutsceneHighlightPositions();
	incrementSpyCarCutsceneShown();
	
	if(ScriptManager:getMissionStatus(missionIds.DETECT_ENEMY_SPY_CARS) == MissionStatus.IN_PROGRESS) then
		updateDetectSpyCarMissionProgress();
	end
end

function prepareSpyCarDiscovoredCutscene()
	table.insert(queueTable, playSpyCarDiscovoredCutscene);
	Utils:cutsceneQueue();
end

function playSpyCarDiscovoredCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	if(getSpyCarCutsceneShown() < 1) then
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, true);
			ScriptManager:moveCameraEx(getCutsceneHighlightX(), getCutsceneHighlightY(), 0.7, 2, true);
			ScriptManager:showMarkerAt(getCutsceneHighlightX(), getCutsceneHighlightY());
		end
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_SIGHTED_FLAVOR1, 3);
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_SIGHTED_FLAVOR2, 2);
		
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:wait(0.5);
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, false);
			Utils:hideAllMarkers();
		end
	else
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, true);
			ScriptManager:moveCameraEx(getCutsceneHighlightX(), getCutsceneHighlightY(), 0.7, 2, true);
			ScriptManager:showMarkerAt(getCutsceneHighlightX(), getCutsceneHighlightY());
		end
		
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_SIGHTED_FLAVOR3, 3);
		
		if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
			ScriptManager:wait(0.5);
			ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, false);
			Utils:hideAllMarkers();
		end
	end
	
	Utils:endCutscene();
	
	resetCutsceneHighlightPositions();
	incrementSpyCarCutsceneShown();
end

function prepareArtilleryMissionCutscene()
	table.insert(queueTable, playArtilleryMissionCutscene);
	Utils:cutsceneQueue();
end

function playArtilleryMissionCutscene()
	Utils:startCutscene();
	
	if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
		ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, true);
		ScriptManager:moveCameraEx(getCutsceneHighlightX(), getCutsceneHighlightY(), 0.7, 2, true);
		ScriptManager:showMarkerAt(getCutsceneHighlightX(), getCutsceneHighlightY());
	end
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY1_FLAVOR1, 2);
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SECONDARY1_FLAVOR2, 5);
	
	if(getCutsceneHighlightX() ~= -1) and (getCutsceneHighlightY() ~= -1) then
		ScriptManager:wait(0.5);
		ScriptManager:revealFogOfWar(getCutsceneHighlightX(), getCutsceneHighlightY(), 1, false);
		Utils:hideAllMarkers();
	end
	
	Utils:endCutscene();
	resetCutsceneHighlightPositions();
	Utils:disablePlayerInteraction();
	
	startMission(missionIds.DESTROY_ENEMY_ARTILLERY);
	
	ScriptManager:wait(2);
	
	Utils:enablePlayerInteraction();
end

function prepareSpyCarDestroyedCutscene()
	table.insert(queueTable, playSpyCarDestroyedCutscene);
	Utils:cutsceneQueue();
end

function playSpyCarDestroyedCutscene()
	Utils:startCutscene();
	
	if(getEnemySpyCarsDestroyed() >= ENEMY_SPY_CARS_TO_DESTROY) then
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_DESTROYED_FLAVOR1, 3);
	else
		Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_SPY_CAR_DESTROYED_FLAVOR2, 3);
	end
	
	Utils:endCutscene();
	
	if(ScriptManager:getMissionStatus(missionIds.DESTROY_ENEMY_SPY_CARS) == MissionStatus.IN_PROGRESS) then
		updateDestroySpyCarMissionProgress();
	end
end

function prepareRoadblockAccomplishedCutscene()
	table.insert(queueTable, playRoadblockAccomplishedCutscene);
	Utils:cutsceneQueue();
end

function playRoadblockAccomplishedCutscene()
	local currentCamX, currentCamY = ScriptManager:getCurrentCameraPositionX(), ScriptManager:getCurrentCameraPositionY();
	
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration(Text.T_CAMP_X4_2_ROAD_BLOCK_DESTROYED_FLAVOR1, 4);
	
	Utils:endCutscene();
end

-- #######################################-END_GAME-#######################################

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle(Text.T_MISSION_VICTORY);
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end

function transitionToFail()
	ScriptManager:runForPlayer(PLAYER_ID, "missionFailed");
end

function missionFailed()
	Utils:disablePlayerInteraction();
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	ScriptManager:displaySubtitle(Text.T_MISSION_FAILED);
	ScriptManager:wait( 4 );
	Utils:hideDialogue();
	Utils:endGame();
end

-- #######################################-UNITS_AND_HELPER-#######################################

function reduceEnemyArtilleryActionPoints()
	for i = 1, #enemyArtilleryUnitIds do
		if(Unit:getUnitById(enemyArtilleryUnitIds[i]) ~= nil) then
			Unit:getUnitById(enemyArtilleryUnitIds[i]):setActionPoints(0);
		end
	end
end

function checkRadarInsideSpyCarRadius(radarTileX, radarTileY)
	for i = 1, #enemySpyCarUnitIds do
		if(enemySpyCarsRevealed[i] == spyCarStatus.NOT_REVEALED) then
			-- only works if spy car has an even y position on the map
			if(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX(), Unit:getUnitById(enemySpyCarUnitIds[i]):getY(), radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 2, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 2, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 2, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 2, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 3, Unit:getUnitById(enemySpyCarUnitIds[i]):getY(), radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 3, Unit:getUnitById(enemySpyCarUnitIds[i]):getY(), radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY(), radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY(), radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 1, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 3, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 1, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() - 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 2, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX(), Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 3, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() - 1, radarTileX, radarTileY) == true) or
				(checkRadarTileInsideNeighbouringTiles(Unit:getUnitById(enemySpyCarUnitIds[i]):getX() + 2, Unit:getUnitById(enemySpyCarUnitIds[i]):getY() + 1, radarTileX, radarTileY) == true) then
				enemySpyCarsRevealed[i] = 1;
				setCutsceneHighlightX(Unit:getUnitById(enemySpyCarUnitIds[i]):getX());
				setCutsceneHighlightY(Unit:getUnitById(enemySpyCarUnitIds[i]):getY());
				Utils:saveValuesIntoSavefileForExistingTable("enemySpyCarsRevealed", enemySpyCarsRevealed);
				return true;
			end
		else
			print("###################################################______ALREADY REVEALED!");
		end
	end
	
	return false;
end

function checkRadarTileInsideNeighbouringTiles(originTileX, originTileY, radarTileX, radarTileY)
	local thresholdFactor = 1;
	
	if(originTileY % 2 == 0) then
		thresholdFactor = thresholdFactor * (-1);
	end
	
	for i = -1, 1 do --y
		for j = -1, 1 do --x
			if((j == -1 * thresholdFactor) and (i == 1 * thresholdFactor)) or
				((j == -1 * thresholdFactor) and (i == -1 * thresholdFactor)) or
				((j == 0) and (i == 0)) then
				--placeholder for a continue statement (which does not exist in lua...)
			else
				if((originTileX + j == radarTileX) and (originTileY + i == radarTileY)) or
					((originTileX == radarTileX) and (originTileY == radarTileY)) then
					return true;
				end
			end
		end
	end

	return false;
end

function getEnemySpyCarStatus(spyCarId)
	for i = 1, #enemySpyCarUnitIds do
		if(spyCarId == enemySpyCarUnitIds[i]) then
			return enemySpyCarsRevealed[i];
		end
	end
end

function resetCutsceneHighlightPositions()
	setCutsceneHighlightX(-1);
	setCutsceneHighlightY(-1);
end

-- #######################################-GETTER_AND_SETTER-#######################################

function getEnemySpyCarsDestroyed()
	return enemySpyCarsDestroyed;
end

function setEnemySpyCarsDestroyed(value)
	enemySpyCarsDestroyed = value;
	
	if(enemySpyCarsDestroyed >= ENEMY_SPY_CARS_TO_DESTROY) then
		enemySpyCarsDestroyed = ENEMY_SPY_CARS_TO_DESTROY;
	end
	
	ScriptManager:storeValue("enemySpyCarsDestroyed", enemySpyCarsDestroyed);
end

function incrementEnemySpyCarsDestroyed()
	setEnemySpyCarsDestroyed(getEnemySpyCarsDestroyed() + 1);
end

function getEnemySpyCarsDetected()
	return enemySpyCarsDetected;
end

function setEnemySpyCarsDetected(value)
	enemySpyCarsDetected = value;
	
	if(enemySpyCarsDetected >= ENEMY_SPY_CARS_TO_DETECT) then
		enemySpyCarsDetected = ENEMY_SPY_CARS_TO_DETECT;
	end
	
	ScriptManager:storeValue("enemySpyCarsDetected", enemySpyCarsDetected);
end

function incrementEnemySpyCarsDetected()
	setEnemySpyCarsDetected(getEnemySpyCarsDetected() + 1);
end

function getRoadblocksDestroyed()
	return roadblocksDestroyed;
end

function setRoadblocksDestroyed(value)
	roadblocksDestroyed = value;
	
	if(roadblocksDestroyed >= ROADBLOCKS_TO_DESTROY) then
		roadblocksDestroyed = ROADBLOCKS_TO_DESTROY;
	end
	
	ScriptManager:storeValue("roadblocksDestroyed", roadblocksDestroyed);
end

function incrementRoadblocksDestroyed()
	setRoadblocksDestroyed(getRoadblocksDestroyed() + 1);
end

function getArtilleryDestroyed()
	return artilleryDestroyed;
end

function setArtilleryDestroyed(value)
	artilleryDestroyed = value;
	
	if(artilleryDestroyed >= ENEMY_ARTILLERIES_TO_DESTROY) then
		artilleryDestroyed = ENEMY_ARTILLERIES_TO_DESTROY;
	end
	
	ScriptManager:storeValue("artilleryDestroyed", artilleryDestroyed);
end

function incrementArtilleryDestroyed()
	setArtilleryDestroyed(getArtilleryDestroyed() + 1);
end

function getNorthernRoadblockUnitsDestroyed()
	return northernRoadblockUnitsDestroyed;
end

function setNorthernRoadblockUnitsDestroyed(value)
	northernRoadblockUnitsDestroyed = value;
	
	if(northernRoadblockUnitsDestroyed >= NUMBER_OF_ROADBLOCK_UNITS_NORTH) then
		northernRoadblockUnitsDestroyed = NUMBER_OF_ROADBLOCK_UNITS_NORTH;
	end
	
	ScriptManager:storeValue("northernRoadblockUnitsDestroyed", northernRoadblockUnitsDestroyed);
end

function incrementNorthernRoadblockUnitsDestroyed()
	setNorthernRoadblockUnitsDestroyed(getNorthernRoadblockUnitsDestroyed() + 1);
end

function getSouthernRoadblockUnitsDestroyed()
	return southernRoadblockUnitsDestroyed;
end

function setSouthernRoadblockUnitsDestroyed(value)
	southernRoadblockUnitsDestroyed = value;
	
	if(southernRoadblockUnitsDestroyed >= NUMBER_OF_ROADBLOCK_UNITS_SOUTH) then
		southernRoadblockUnitsDestroyed = NUMBER_OF_ROADBLOCK_UNITS_SOUTH;
	end
	
	ScriptManager:storeValue("southernRoadblockUnitsDestroyed", southernRoadblockUnitsDestroyed);
end

function incrementSouthernRoadblockUnitsDestroyed()
	setSouthernRoadblockUnitsDestroyed(getSouthernRoadblockUnitsDestroyed() + 1);
end

function getSpyCarCutsceneShown()
	return spyCarCutsceneShown;
end

function setSpyCarCutsceneShown(value)
	spyCarCutsceneShown = value;
	
	ScriptManager:storeValue("spyCarCutsceneShown", spyCarCutsceneShown);
end

function incrementSpyCarCutsceneShown()
	setSpyCarCutsceneShown(getSpyCarCutsceneShown() + 1);
end

function getCutsceneHighlightX()
	return cutsceneHighlightX;
end

function setCutsceneHighlightX(value)
	cutsceneHighlightX = value;
	
	ScriptManager:storeValue("cutsceneHighlightX", cutsceneHighlightX);
end

function getCutsceneHighlightY()
	return cutsceneHighlightY;
end

function setCutsceneHighlightY(value)
	cutsceneHighlightY = value;
	
	ScriptManager:storeValue("cutsceneHighlightY", cutsceneHighlightY);
end

-- #######################################-TESTING-#######################################

function testing()
	ScriptManager:spawnUnit(PLAYER_ID, Units.SHORTSIGHTED_GOD, 		18, 18, 42);
end

function removeSquads()
	--Utils:removeSquad( );
end

function showParameters(selectedUnit)
	Utils:printUnitInfo(selectedUnit);
end

-- END