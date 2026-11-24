require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	reachBridge			= 1,
	destroyDefenders	= 2,
	repairBridge		= 3,
	destroyArty			= 4,
	keepTanks			= 5,
	useRadar			= 6,
	destroyEnemy		= 7,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.reachBridge,		true,	Text.T_CAMP_L2_1_PRIMARY1,		 50 },
	{ missionIds.destroyDefenders,	true,	Text.T_CAMP_L2_1_PRIMARY2,		100 },
	{ missionIds.repairBridge,		true,	Text.T_CAMP_L2_1_PRIMARY3,		125 },
	{ missionIds.destroyEnemy,		true,	Text.T_CAMP_L2_1_PRIMARY5,		100 },
	{ missionIds.destroyArty,		false,	Text.T_CAMP_L2_1_PRIMARY4,		 50 }, -- was primary before
	{ missionIds.keepTanks,			false,	Text.T_CAMP_L2_1_SECONDARY1,	 75 },
	{ missionIds.useRadar,			false,	Text.T_CAMP_L2_1_SECONDARY2,	 50 },
};

enemySquadIds = {
	bridgeDefense		=  1,
	ambush				=  2,
	arty1				=  3,
	arty2				=  4,
	villageDefense		=  5,
	finalSquad			=  6,
	attackWave			= 15,
};

bridgeDefenseIds	= { 14, 15, 16, 17, 18, 19, 20 };
artyPos				= { { 16, 14 }, { 16, 13 } };
villageDefenseIds	= { 24, 25, 26, 27 };

enemyAmbushUnits = {
	{ Units.X_INFANTRY_MG,		0, 11 },
	{ Units.X_TANK_DESTROYER,	0, 12 },
	{ Units.X_INFANTRY_FLAME,	0, 13 },
	{ Units.X_INFANTRY_MG,		0, 14 },
};

spawnAttackers				= 0;
lastAttackersSpawnedInRound	= 0;
attackWaveRespawnInterval	= 4;
numberOfWavesSpawned		= 0;

bridgeAttackers1 =  {
	{ Units.X_INFANTRY_MG,		6, 0 },	
	{ Units.X_TANK_DESTROYER,	7, 0 },
};

bridgeAttackers2 =  {
	{ Units.X_INFANTRY_MG,		0, 5 },	
	{ Units.X_INFANTRY_FLAME,	0, 6 },
	{ Units.X_TRUCK_MG,			0, 7 },
};

bridgeAttackers3 =  {
	{ Units.X_INFANTRY_MG,		6, 0 },
	{ Units.X_TANK_HEAVY,		7, 0 },
};

bridgeAttackers4 =  {
	{ Units.X_INFANTRY_MG,		0, 5 },	
	{ Units.X_INFANTRY_AT,		0, 6 },
	{ Units.X_INFANTRY_SNIPER,	0, 7 },
};

defendersToDestroy	= #bridgeDefenseIds;
bridgeId			= 0;
depotId				= 1;
bridgeMaxHp			= 1200;

finalSquad = {
	{ Units.X_TANK_MEDIUM,		16, 19 },
	{ Units.X_ARTILLERY_MORTAR,	17, 19 },
	{ Units.X_INFANTRY_MG,		16, 20 },
	{ Units.X_INFANTRY_MG,		17, 20 },
	{ Units.X_INFANTRY_AT,		18, 18 },
};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	addAiOrders();
	
	Utils:setIsAttackable( bridgeId, false );
	ScriptManager:disableInteractionButton( InteractionButton.TRANSFORM )
	
	ScriptManager:disableGlobalAbilityButton(	GlobalAbility.PARATROOPER );
	ScriptManager:enableGlobalAbilityButton(	GlobalAbility.PARATROOPER_NO_ENGI );
	ScriptManager:blockGlobalAbilityButton(		GlobalAbility.BLIMB );
	
	ScriptManager:removeReinforcementsFromBase( depotId, Units.L_INFANTRY_ENGINEER );
	
	ScriptManager:gainGold( 0, 1200 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue( "defendersToDestroy",				defendersToDestroy );
	ScriptManager:storeValue( "spawnAttackers",					spawnAttackers );
	ScriptManager:storeValue( "lastAttackersSpawnedInRound",	lastAttackersSpawnedInRound );
	ScriptManager:storeValue( "numberOfWavesSpawned",			numberOfWavesSpawned );
	
	ScriptManager:storeValue( "ambushTrigger",		0 );
	ScriptManager:storeValue( "nearBridgeTrigger",	0 );
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- enemy wave spawn
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart", false );
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.L_BUILDING_HQ,	-1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_BUILDING_HQ,	-1,	"transitionToFail",		"transitionToFail" );
	
	-- trigger for reaching bridge
	Utils:addOnEnterAreaTrigger( 9, 8, 1, 0, -1, -1, true, "startReachedBridgeCutscene", "startReachedBridgeCutscene" );

	-- trigger for paratrooper and on enter tile triggers
	ScriptManager:addOnUnitCreatedTrigger( 0, -1, "onUnitCreated", "onUnitCreated" );
	
	-- trigger for clearing bridge area
	ScriptManager:addOnUnitSightedTrigger(		 1, -1, -1, true,	"onEnemySighted",		"onEnemySighted" );
	ScriptManager:addOnUnitHasAttackedTrigger(	-1, -1, -1,			"onEnemyHasAttacked",	"onEnemyHasAttacked" );
	ScriptManager:addOnUnitDestroyedTrigger(	 1, -1, -1,			"onEnemyDestroyed",		"onEnemyDestroyed" );
	
	for x = 1, 9 do
		ScriptManager:addOnEnterTileTrigger( x, 11, 0, -1, -1, false, "enemyAmbushTriggered", "enemyAmbushTriggered" );
	end
	
	-- trigger for bridge repair
	ScriptManager:addOnBridgeRepairTrigger( -1, -1, -1, "onBridgeRepaired", "onBridgeRepaired" );	
	
	-- trigger for keeping tanks
	for i = 7, 8 do --if the ids of the heavy tanks change ( which should not! ) then change it here too!
		ScriptManager:addOnUnitDestroyedTrigger(	0, Units.L_TANK_HEAVY, i, "onHeavyTankDestroyed",	"onHeavyTankDestroyed" );
	end
end

function loadValues()
	defendersToDestroy			= ScriptManager:getValue( "defendersToDestroy" );
	spawnAttackers				= ScriptManager:getValue( "spawnAttackers" );
	lastAttackersSpawnedInRound	= ScriptManager:getValue( "lastAttackersSpawnedInRound" );
	numberOfWavesSpawned		= ScriptManager:getValue( "numberOfWavesSpawned" );
end

function addAiOrders()
	ScriptManager:addOrder( enemySquadIds.bridgeDefense,	 7,  6, -1, 3, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.villageDefense,	17, 12, -1, 3, AiOrder.DEFEND );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_INTRO_FLAVOR1, 6 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_INTRO_FLAVOR2 );
	Utils:antiRush()
	ScriptManager:moveCameraEx( 11, 8, 0.7, 5, true );
	Utils:hideDialogue();
	
	-- for testers that they know why rubberboats are disabled, l2_3 text is correct
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_3_INTRO_FLAVOR2 );
	Utils:antiRush()
	ScriptManager:revealFogOfWar( 11, 8, 2, true );
	ScriptManager:wait( 3 );
	ScriptManager:revealFogOfWar( 11, 8, 2, false );
	Utils:antiRush()
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_INTRO_FLAVOR3 );
	ScriptManager:moveCameraEx( 3, 19, 0.7, 5, true );
	Utils:antiRush()
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_INTRO_FLAVOR4 );
	ScriptManager:wait( 1 );
	
	ScriptManager:showMarkerAt( 4, 18 );
	ScriptManager:showMarkerAt( 4, 19 );
	ScriptManager:wait( 4 );
	ScriptManager:removeAllMarkers();
	Utils:antiRush()
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_INTRO_END_1, 2 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.reachBridge, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.keepTanks,	MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.destroyDefenders,	0, defendersToDestroy );
	Utils:setMissionProgress( missionIds.destroyArty,		0, #artyPos );
	Utils:setMissionProgress( missionIds.destroyEnemy,		0, #finalSquad );
	
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.L_INFANTRY_ENGINEER,	9, 8, 42 );
end

function removeSquads()
	Utils:removeSquad( bridgeDefenseIds );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN Unit Stuff


function onUnitCreated( createdUnit )
	local posX = createdUnit:getX();
	local posY = createdUnit:getY();
	
	if posX >= 8 and posX <= 10 and posY >= 7 and posY <= 9 then -- not 100 % the same as on enter area but i dont really care about it
		if ScriptManager:getValue( "nearBridgeTrigger" ) == 0 then
			startReachedBridgeCutscene( posX, posY, 0, createdUnit:getTemplateId() );
		end
	
	elseif posX <= 9 and posY <= 11 then -- ambush
		if ScriptManager:getValue( "ambushTrigger" ) == 0 then
			enemyAmbushTriggered( 0, 0, 0, createdUnit:getTemplateId() );
		end
	end
end

function onEnemySighted( seeingUnit, seenUnit )
	if seenUnit:getSquadId() == enemySquadIds.bridgeDefense then
		ScriptManager:removeTrigger( "onEnemyHasAttacked" );
		ScriptManager:removeTrigger( "onEnemySighted" );
		
		ScriptManager:runForPlayer( 0, "prepareClearBridgeCutscene" );
	end
end

function onEnemyHasAttacked( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	local hitDefine, unitTable = Utils:checkForAoe( attacker, isAoe, defender, allUnitsHit, unitsHitCount );
	
	-- if a unit was hit
	if hitDefine ~= 0 then
		-- 0 for first parameter cause i only check for the second parameter in onEnemySighted
		if attacker:getPlayerId() == 1 then
			onEnemySighted( 0, attacker )
			
		else
			onEnemySighted( 0, defender )
		end
	end
end

function prepareClearBridgeCutscene()
	table.insert( queueTable, startClearbridgeCutscene );
	Utils:cutsceneQueue();
end

function startClearbridgeCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY2_FLAVOR1, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY2_FLAVOR2, 3 );
	
	Utils:endCutscene();
	if ScriptManager:getMissionStatus( missionIds.destroyDefenders ) == MissionStatus.NOT_STARTED then
		Utils:setMissionStatus( missionIds.destroyDefenders,  MissionStatus.IN_PROGRESS );
	end
end

function onEnemyDestroyed( unit )
	local squadId = unit:getSquadId();
	
	-- the guys defending the bridge
	if squadId == enemySquadIds.bridgeDefense or squadId == enemySquadIds.ambush then
		Utils:incrementMissionProgress( missionIds.destroyDefenders );
		ScriptManager:runForPlayer( 0, "prepareDestroyDefenderseProgress" );
	
	-- the guys attacking the bridge from the other side of the river
	elseif	squadId == enemySquadIds.arty1 or squadId == enemySquadIds.arty2 then
		Utils:incrementMissionProgress( missionIds.destroyArty );
		ScriptManager:runForPlayer( 0, "prepareDestroyArtyProgress" );
		
	elseif squadId == enemySquadIds.finalSquad then
		Utils:incrementMissionProgress( missionIds.destroyEnemy );
		ScriptManager:runForPlayer( 0, "prepareDestroyEnemyProgress" );
	end
end

function prepareDestroyDefenderseProgress()
	table.insert( queueTable, showDestroyDefendersProgress );
	Utils:cutsceneQueue();
end

function showDestroyDefendersProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyDefenders ) >= defendersToDestroy then
		Utils:setMissionStatus( missionIds.destroyDefenders, MissionStatus.ACCOMPLISHED );
		Utils:startCutscene();
		
		Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_1, 3 );
		
		if ScriptManager:getMissionStatus( missionIds.reachBridge ) == MissionStatus.ACCOMPLISHED then
			-- if bridge was already approached, start repair mission
			repairBridgeCutsceneContent();
		
		else -- if bridge mission still open, go there now
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY2_FLAVOR3, 5 );
			
			Utils:endCutscene();
		end
		
	else
		Utils:showMissionProgressTwoVar( ScriptManager:getMissionProgress( missionIds.destroyDefenders ), 
										 defendersToDestroy, Text.T_CAMP_L2_1_PRIMARY2_COUNTER );
	end
end

function prepareDestroyArtyProgress()
	table.insert( queueTable, showDestroyArtyProgress );
	Utils:cutsceneQueue();
end

function showDestroyArtyProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyArty ) >= #artyPos then
		Utils:setMissionStatus(missionIds.destroyArty, MissionStatus.ACCOMPLISHED );
		Utils:displaySubtitleWithDuration( Text.T_SUBTITLE_PRAISE_2, 4 );
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyArty ), Text.T_CAMP_L2_1_PRIMARY4_COUNTER );
	end
end

function prepareDestroyEnemyProgress()
	table.insert( queueTable, showDestroyEnemyProgress );
	Utils:cutsceneQueue();
end

function showDestroyEnemyProgress()
	if ScriptManager:getMissionProgress( missionIds.destroyEnemy ) >= #finalSquad then
		Utils:setMissionStatus( missionIds.destroyEnemy, MissionStatus.ACCOMPLISHED );
		startVictoryCutscene();
	
	else
		Utils:showMissionProgress( ScriptManager:getMissionProgress( missionIds.destroyEnemy ), Text.T_CAMP_L2_1_PRIMARY5_COUNTER );
	end
end

function enemyAmbushTriggered( tileX, tileY, playerId, unitTemplateId, unitId )
	if unitTemplateId ~= Units.L_PLANE_SCOUT then
		ScriptManager:removeTrigger( "enemyAmbushTriggered" );
		ScriptManager:storeValue( "ambushTrigger", 1 );
		
		ScriptManager:runForPlayer( 1, "spawnEnemyAmbush" );
	end
end

function spawnEnemyAmbush()
	local unit;
	for i = 1, #enemyAmbushUnits do
		unit = ScriptManager:spawnUnit( 1, enemyAmbushUnits[i][1], enemyAmbushUnits[i][2], enemyAmbushUnits[i][3], enemySquadIds.ambush );
	end
	
	defendersToDestroy =  defendersToDestroy + #enemyAmbushUnits;
	ScriptManager:storeValue( "defendersToDestroy", defendersToDestroy );
	ScriptManager:setMaxMissionProgress( missionIds.destroyDefenders, defendersToDestroy );
	
	local orderId = ScriptManager:addOrder( enemySquadIds.ambush, 6, 8, -1, 4, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	ScriptManager:addOrder( enemySquadIds.ambush, 6, 8, -1, 3, AiOrder.DEFEND );
	
	ScriptManager:runForPlayer( 0, "prepareAmbushCutscene" );
end

function prepareAmbushCutscene()
	table.insert( queueTable, startAmbushCutscene );
	Utils:cutsceneQueue();
end

function startAmbushCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY2_FLAVOR4, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY2_FLAVOR5, 3 );
	
	Utils:endCutscene();
	if ScriptManager:getMissionStatus( missionIds.destroyDefenders ) == MissionStatus.NOT_STARTED then
		Utils:setMissionStatus( missionIds.destroyDefenders,  MissionStatus.IN_PROGRESS );
	end
end

function onHeavyTankDestroyed()
	 ScriptManager:removeTrigger( "onHeavyTankDestroyed" );
	 ScriptManager:runForPlayer( 0, "preparePortectTankFailure" );
end

function preparePortectTankFailure()
	table.insert( queueTable, startProtectTankFailure );
	Utils:cutsceneQueue();
end

function startProtectTankFailure()
	Utils:setMissionStatus( missionIds.keepTanks, MissionStatus.FAILED );
end

function onEnemyTurnStart()
	if spawnAttackers == 1 then
		--check if a wave spawns this round
		if lastAttackersSpawnedInRound + attackWaveRespawnInterval <= ScriptManager:getCurrentRound() then
			
			--define which wave will spawn
			local indicator = numberOfWavesSpawned % 4;
			local waveTable;
			
			if indicator == 1 then
				waveTable = bridgeAttackers1;
				
			elseif indicator == 2 then
				waveTable = bridgeAttackers1;
				
			elseif indicator == 3 then
				waveTable = bridgeAttackers1;
				
			else
				waveTable = bridgeAttackers1;
			end
			
			local squadId = enemySquadIds.attackWave + numberOfWavesSpawned;
			
			for i = 1, #waveTable do
				Utils:spawnUnitFromShortTable( 1, squadId, waveTable[i] );
			end
			
			local orderId = ScriptManager:addOrder( squadId, 7, 8, -1, 3, AiOrder.ATTACK );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
			ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
			
			ScriptManager:addOrder( squadId, 7, 8, -1, 3, AiOrder.DEFEND );
			
			numberOfWavesSpawned = numberOfWavesSpawned + 1;
			ScriptManager:storeValue( "numberOfWavesSpawned", numberOfWavesSpawned );
			
			lastAttackersSpawnedInRound = ScriptManager:getCurrentRound();
			ScriptManager:storeValue( "lastAttackersSpawnedInRound", lastAttackersSpawnedInRound );
		end
	end
end


-- END Unit stuff
-- BEGIN Bridge Stuff


function startReachedBridgeCutscene( tileX, tileY, playerId, unitTemplateId, unitId )
	if unitTemplateId ~= Units.L_PLANE_SCOUT then
		ScriptManager:removeTrigger( "startReachedBridgeCutscene" );
		ScriptManager:storeValue( "nearBridgeTrigger", 1 );
		
		local engineer = ScriptManager:spawnUnit( 1, Units.X_INFANTRY_ENGINEER, 15, 10, 0 );
		local engiId = engineer:getId();
		
		Utils:setMissionStatus( missionIds.reachBridge, MissionStatus.ACCOMPLISHED );
		Utils:startCutscene();
		
		ScriptManager:moveCameraEx( 13, 8, 0.7, 2, true );
		ScriptManager:revealFogOfWar( 12, 8, 3, true );
		
		ScriptManager:moveUnitEx( engiId, 13, 8, true );
		Utils:antiRush();
		
		ScriptManager:detonateBridge( engiId, bridgeId, false );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY3_FLAVOR1 );
		ScriptManager:wait( 3 );
		
		ScriptManager:moveUnitEx( engiId, 15, 10, false );
		
		ScriptManager:revealFogOfWar( 12, 8, 3, false );
		Utils:antiRush();
		
		ScriptManager:moveCameraEx( tileX, tileY, 0.7, 2, true );
		Utils:antiRush();
		Utils:hideDialogue();
		
		ScriptManager:removeUnitEx( engiId, false );
		
		if ScriptManager:getMissionStatus( missionIds.destroyDefenders ) == MissionStatus.ACCOMPLISHED then
			-- if defenders already cleared, start repair mission
			repairBridgeCutsceneContent();
		
		else -- if defender mission still open, destroy them first to continue
			Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY3_FLAVOR2, 5 );
			
			Utils:endCutscene();
		end
	end
end

function repairBridgeCutsceneContent()
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY3_FLAVOR3 );
	ScriptManager:moveCameraEx( 5, 20, 0.7, 5, true );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY3_FLAVOR4 );
	ScriptManager:wait( 2 );
	
	ScriptManager:spawnUnits( 0, Units.L_INFANTRY_ENGINEER, 5, 20, 0, 2 );
	ScriptManager:addReinforcementsToBase( depotId, Units.L_INFANTRY_ENGINEER );
	
	ScriptManager:disableGlobalAbilityButton(	GlobalAbility.PARATROOPER_NO_ENGI );
	ScriptManager:enableGlobalAbilityButton(	GlobalAbility.PARATROOPER );
	
	Utils:hideDialogue();
	
	Utils:endCutscene();
	
	spawnAttackers = 1;
	ScriptManager:storeValue( "spawnAttackers", spawnAttackers );
	
	Utils:setMissionStatus( missionIds.repairBridge, MissionStatus.IN_PROGRESS );
end

function onBridgeRepaired( engi, bridge)
	if ScriptManager:getMissionStatus( missionIds.destroyArty ) == MissionStatus.NOT_STARTED then
		ScriptManager:runForPlayer( 1, "artyAttack" );
	end
	
	local bridgeHp = bridge:getHealth();
	
	if bridgeHp == bridgeMaxHp then
		ScriptManager:removeTrigger( "onBridgeRepaired" );
		Utils:setMissionStatus( missionIds.repairBridge, MissionStatus.ACCOMPLISHED );
		
		ScriptManager:disableInteractionButton( InteractionButton.DETONATE_BRIDGE );
		
		spawnAttackers = 0;
		ScriptManager:storeValue( "spawnAttackers", spawnAttackers );
		
		for i = 1, #finalSquad do
			Utils:spawnUnitFromShortTable( 1, enemySquadIds.finalSquad, finalSquad[i] );
		end
				
		Utils:attackOrder( enemySquadIds.finalSquad, 13, 8, 3 );
		
		Utils:startCutscene();
		
		ScriptManager:displaySubtitle( Text.T_MISSION_REINFORCEMENTS_ENEMY );
		ScriptManager:moveCameraEx(		16, 19, 0.7, 3, true );
		ScriptManager:revealFogOfWar(	16, 19, 2, true );
		
		ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY5_FLAVOR1 );
		ScriptManager:wait( 2 );
		ScriptManager:revealFogOfWar( 16, 19, 2, false );
		
		ScriptManager:moveCameraEx( 13, 8 , 0.7, 3, true );
		Utils:hideDialogue();
		
		Utils:endCutscene()
		Utils:setMissionStatus( missionIds.destroyEnemy, MissionStatus.IN_PROGRESS );
	end
end

function artyAttack()
	ScriptManager:runForPlayer( 0, "prepareCrossRiverCutscene" );
end

function prepareCrossRiverCutscene()
	table.insert( queueTable, startCrossRiverCutscene );
	Utils:cutsceneQueue();
end

function startCrossRiverCutscene()
	local engi = Unit:getUnitAt( 9, 8 );
	local engiId;
	
	if engi ~= nil then
		engiId = engi:getId();
	end
	
	local arty1 = ScriptManager:spawnUnit( 1, Units.X_ARTILLERY_EXTRARANGE, artyPos[1][1], artyPos[1][2], enemySquadIds.arty1 );
	local arty2 = ScriptManager:spawnUnit( 1, Units.X_ARTILLERY_EXTRARANGE, artyPos[2][1], artyPos[2][2], enemySquadIds.arty2 );
	
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 9, 8, 0.7, 3, false );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY4_FLAVOR1, 3 );
	
	--only attack if engi is alive and visible
	if ScriptManager:hasSmoke( 9, 8 ) == false and engi ~= nil then
		ScriptManager:attackUnitEx( arty1:getId(), engiId, true );
		ScriptManager:attackUnitEx( arty2:getId(), engiId, true );
		Utils:antiRush();
	end
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY4_FLAVOR2 );
	ScriptManager:moveCameraEx( 16, 12, 0.7, 5, true );
	Utils:antiRush();
	Utils:hideDialogue();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_PRIMARY4_FLAVOR3, 4 );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_L2_1_PRIMARY4_FLAVOR4 );
	ScriptManager:moveCameraEx( 9, 8, 0.7, 5, true );
	Utils:antiRush();
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	ScriptManager:gainGold( 0, 500 );
	ScriptManager:setMissionStatus( missionIds.destroyArty,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.useRadar,	MissionStatus.IN_PROGRESS );
	
	-- trigger for radar
	ScriptManager:addOnRadarTrigger( GlobalAbility.RADAR, 0, -1, -1, "onRadarUsed", "onRadarUsed" );
	
	ScriptManager:enableInteractionButton( InteractionButton.TRANSFORM );
	
	for i = enemySquadIds.arty1, enemySquadIds.arty2 do
		local orderId = ScriptManager:addOrder( i, 8, 8, -1, 2, AiOrder.DEFEND );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_ONLY_ATTACK_IN_AREA );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CONTINUE_TO_ATTACK );
	end
	ScriptManager:setAiAttackPriority( Units.L_INFANTRY_ENGINEER, 10, true );
	
	Utils:enablePlayerInteraction();
end

function onRadarUsed( tileX, tileY, enemiesDetected )	
	if enemiesDetected then
		local diffX, diffY, diff;
		local radarRadius	= 4; -- if target is further away, the radar missed and the mission will not get accomplished
		local targetX		= artyPos[1][1];-- same for both
		local targetY1		= artyPos[1][2];
		local targetY2		= artyPos[2][2];
		
		diffX = math.abs( targetX - tileX );
		
		if diffX <= radarRadius then
			diffY = math.abs( targetY1 - tileY );
			
			if diffX + diffY <= radarRadius then
				radarMissionDone()
				
			else
				diffY = math.abs( targetY2 - tileY );
				
				if diffX + diffY <= radarRadius then
					radarMissionDone()
				end
			end
		end
	end
end

function radarMissionDone()
	ScriptManager:removeTrigger( "onRadarUsed" );
	Utils:setMissionStatus( missionIds.useRadar, MissionStatus.ACCOMPLISHED );
end


-- END Bridge Stuff
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_VICTORY_FLAVOR1, 3 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_VICTORY_FLAVOR2, 4 );
	Utils:displaySubtitleWithDuration( Text.T_CAMP_L2_1_VICTORY_FLAVOR3, 3 );
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	victoryEndGame();
end

function victoryEndGame()
	Utils:hideDialogue(); -- remove possible texts on the screens
	
	Utils:missionCheckerAccomplish( missionIds.keepTanks );
	
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