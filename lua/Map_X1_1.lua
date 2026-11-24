require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	holdLine	= 1,
	destroyLCTs	= 2,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.holdLine,		true,	Text.T_CAMP_X1_1_PRIMARY1,		200 },
	{ missionIds.destroyLCTs,	false,	Text.T_CAMP_X1_1_SECONDARY1,	  0 }, -- xp bonus for each one destroyed
};

enemySquadIds = {
	topWave1	=  1,
	topWave21	=  2,
	topWave22	=  3,
	topWave21	=  4,
	topWave31	=  5,
	topWave42	=  6,
	topWave43	=  7,
	topWave41	=  8,
	topWave5	=  9,
	topWave61	= 10,
	topWave62	= 11,
	topWave71	= 12,
	topWave8	= 13,
	topWave91	= 14,
	topWave92	= 15,
	topWave101	= 16,
	topWave102	= 17,
	
	midWave1	= 18,
	midWave21	= 19,
	midWave31	= 20,
	midWave32	= 21,
	midWave33	= 22,
	midWave41	= 23,
	midWave5	= 24,
	midWave61	= 25,
	midWave71	= 26,
	midWave72	= 27,
	midWave73	= 28,
	midWave8	= 29,
	
	botWave1	= 30,
	botWave21	= 31,
	botWave22	= 32,
	botWave31	= 33,
	botWave41	= 34,
	botWave42	= 35,
	botWave43	= 36,
	botWave5	= 37,
	botWave61	= 38,
	botWave62	= 39,
	botWave71	= 40,
	botWave8	= 41,
	botWave91	= 42,
	botWave92	= 43,
	botWave101	= 44,
	botWave102	= 45,
	
	planeWave1	= 46,
	planeWave2	= 47,
	planeWave3	= 48,
	planeWave4	= 49,
	planeWave51	= 50,
	planeWave52	= 51,
	planeWave53	= 52,
	planeWave6	= 53,
	planeWave7	= 54,
	planeWave8	= 55,
	planeWave9	= 56,
	planeWave10	= 57,
	
	ac	= 58,
	bs1 = 59,
	bs2 = 60,
};

wave2 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_MG, 4, 6, enemySquadIds.midWave21 },
	{ Units.L_INFANTRY_MG, 3, 6, enemySquadIds.topWave21 },
	{ Units.L_INFANTRY_AT, 2, 5, enemySquadIds.topWave22 },
	{ Units.L_INFANTRY_MG, 4, 5, enemySquadIds.botWave21 },
	{ Units.L_INFANTRY_AT, 4, 4, enemySquadIds.botWave22 },
}

wave3 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_AT,		4, 6, enemySquadIds.midWave31 },
	{ Units.L_TRUCK_MG,			3, 6, enemySquadIds.midWave32 },
	{ Units.L_INFANTRY_FLAME,	4, 5, enemySquadIds.midWave33 },
	{ Units.L_INFANTRY_MG,		2, 5, enemySquadIds.topWave31 },
	{ Units.L_INFANTRY_MG,		4, 4, enemySquadIds.botWave31 },
}

wave4 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_MG,		4, 6, enemySquadIds.midWave41 },
	{ Units.L_TRUCK_MG,			3, 6, enemySquadIds.topWave42 },
	{ Units.L_INFANTRY_AT,		2, 5, enemySquadIds.topWave43 },
	{ Units.L_INFANTRY_SNIPER,	2, 4, enemySquadIds.topWave41 },
	{ Units.L_INFANTRY_MG,		4, 5, enemySquadIds.botWave41 },
	{ Units.L_INFANTRY_AT,		4, 4, enemySquadIds.botWave42 },
	{ Units.L_TANK_LIGHT,		3, 3, enemySquadIds.botWave43 },
}

wave5 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_TANK_MEDIUM,	4, 6, enemySquadIds.midWave5 },
	{ Units.L_TANK_LIGHT,	3, 6, enemySquadIds.topWave5 },
	{ Units.L_TANK_LIGHT,	4, 5, enemySquadIds.botWave5 },
}

wave6 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_MG,		4, 6, enemySquadIds.midWave61 },
	{ Units.L_INFANTRY_FLAME,	3, 6, enemySquadIds.topWave61 },
	{ Units.L_INFANTRY_AT,		2, 5, enemySquadIds.topWave62 },
	{ Units.L_INFANTRY_MG,		4, 5, enemySquadIds.botWave61 },
	{ Units.L_INFANTRY_AT,		4, 4, enemySquadIds.botWave62 },
}

wave7 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_AT,		4, 6, enemySquadIds.midWave71 },
	{ Units.L_TANK_LIGHT,		3, 6, enemySquadIds.midWave72 },
	{ Units.L_INFANTRY_MG,		4, 5, enemySquadIds.midWave73 },
	{ Units.L_INFANTRY_MG,		2, 5, enemySquadIds.topWave71 },
	{ Units.L_INFANTRY_FLAME,	4, 4, enemySquadIds.botWave71 },
}

wave8 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_TANK_LIGHT,	4, 6, enemySquadIds.midWave8 },
	{ Units.L_TANK_MEDIUM,	3, 6, enemySquadIds.topWave8 },
	{ Units.L_TANK_MEDIUM,	4, 5, enemySquadIds.botWave8 },
}

wave9 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_AT,		2, 5,	enemySquadIds.topWave91 },
	{ Units.L_INFANTRY_FLAME,	3, 6,	enemySquadIds.topWave92 },
	{ Units.L_INFANTRY_AT,		4, 4,	enemySquadIds.botWave91 },
	{ Units.L_INFANTRY_FLAME,	4, 5,	enemySquadIds.botWave92 },
}

wave10 = { -- unitTemplateId, tileX, tileY, squadId
	{ Units.L_INFANTRY_AT,		2, 5, 	enemySquadIds.topWave101},
	{ Units.L_INFANTRY_FLAME,	3, 6,	enemySquadIds.topWave102},
	{ Units.L_INFANTRY_AT,		4, 4, 	enemySquadIds.botWave101},
	{ Units.L_INFANTRY_FLAME,	4, 5,	enemySquadIds.botWave102},
}

furtherLandingsTop = { { 10, 27 }, { 12, 25 }, { 16, 25 }, };
furtherLandingsBot = { { 21, 14 }, { 20, 17 }, { 21, 20 }, };

acId		= 4;
bs1Id		= 3;
bs2Id		= 2;
hqId		= 7;
holdLineMin	= 4;


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:gainGold( 0, 1250 );
	
	Utils:setIsAttackable( acId, false );
	Utils:setIsAttackable( bs1Id, false );
	Utils:setIsAttackable( bs2Id, false );
	
	ScriptManager:addOrder( enemySquadIds.ac,	 2,  3, -1, 2, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bs1,	 2, 18, -1, 9, AiOrder.DEFEND );
	ScriptManager:addOrder( enemySquadIds.bs2,	14,  3, -1, 9, AiOrder.DEFEND );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	ScriptManager:storeValue("unitIdOfPlaneAtDropZoneBot", -1 );
	ScriptManager:storeValue("unitIdOfPlaneAtDropZoneMid", -1 );
	ScriptManager:storeValue("unitIdOfPlaneAtDropZoneTop", -1 );
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, Units.X_BUILDING_HQ , -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, Units.X_BUILDING_HQ , -1,	"transitionToFail",		"transitionToFail" );
	
	--bunker destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.X_ARTILLERY_COAST_SE,		 -1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.X_ARTILLERY_COAST_SW,		 -1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.N_EMPLACEMENT_BUNKER,		 -1, "bunkerDestroyed", "bunkerDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( 0, Units.N_EMPLACEMENT_BUNKERTOWER, -1, "bunkerDestroyed", "bunkerDestroyed" );
	
	--LCT destroyed
	ScriptManager:addOnUnitDestroyedTrigger( 1, Units.L_SHIP_LCT, -1, "LCTDestroyed", "LCTDestroyed" );
	
	--Spawn waves for 10 rounds. Then Victory
	ScriptManager:addOnTurnStartTrigger( 1, -1, -1, "onEnemyTurnStart", "onEnemyTurnStart" );
	
	-- trigger for better lct pathing
	ScriptManager:addOnAiCalculationTrigger( false, "onAiCalculated", "onAiCalculated" );
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	local unit, unitId, orderId;
	
	Utils:startCutscene();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_INTRO_FLAVOR1 );
	ScriptManager:revealFogOfWar( 5, 9, 8, true );
	ScriptManager:moveCameraEx( 7, 9, 0.5 ,5, true );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_INTRO_FLAVOR2 )
	
	unit	= ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 4, 6, enemySquadIds.midWave1 );
	unitId	= unit:getId();
	ScriptManager:moveUnitEx( unitId, 8, 9,true );
	
	midWaveOrders( enemySquadIds.midWave1, 9, 15 );
	
	unit	= ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 3, 6, enemySquadIds.topWave1 );
	unitId	= unit:getId();
	ScriptManager:moveUnitEx( unitId, 3, 12, true );
	
	orderId = ScriptManager:addOrder( enemySquadIds.topWave1, 6, 27, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
	ScriptManager:addOrder( enemySquadIds.topWave1, 6, 29, -1, 2, AiOrder.DEFEND );
	
	unit	= ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, Units.L_INFANTRY_MG, 4, 5, enemySquadIds.botWave1 );
	unitId	= unit:getId();
	ScriptManager:moveUnitEx( unitId, 10, 5, true );
	orderId = ScriptManager:addOrder( enemySquadIds.botWave1, 21, 7, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
	ScriptManager:addOrder( enemySquadIds.botWave1, 23, 8, -1, 2, AiOrder.DEFEND );
	
	unit	= ScriptManager:spawnUnit( 1, Units.L_PLANE_LIGHT, 3, 5, enemySquadIds.planeWave1 );
	unitId	= unit:getId();
	ScriptManager:moveUnitEx( unitId, 8, 15, true );
	ScriptManager:addOrder( enemySquadIds.planeWave1, 12, 15,- 1, 1, AiOrder.MOVE );
	ScriptManager:addOrder( enemySquadIds.planeWave1, 12, 15, -1, 3, AiOrder.DEFEND );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_INTRO_FLAVOR3 );
	ScriptManager:showMarkerAt(  8, 9 );
	ScriptManager:showMarkerAt(  3,12 );
	ScriptManager:showMarkerAt( 10, 5 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_INTRO_FLAVOR4 );
	ScriptManager:wait( 5 );
	Utils:hideAllMarkers();
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_INTRO_FLAVOR5 );
	ScriptManager:moveCameraEx( 10, 13, 0.7, 3, true );
	ScriptManager:revealFogOfWar( 5, 9, 8, false );
	Utils:hideDialogue();
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds.holdLine,	MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.destroyLCTs,	MissionStatus.IN_PROGRESS );
	
	Utils:setMissionProgress( missionIds.holdLine,		7,  7 )
	Utils:setMissionProgress( missionIds.destroyLCTs,	0, 44 );
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.L_TANK_HEAVY, 10, 17, 0 );
end

function removeSquads()
	--Utils:removeSquad(  );
end


function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN

function bunkerDestroyed()
	ScriptManager:setMissionProgress(missionIds.holdLine,ScriptManager:getMissionProgress( missionIds.holdLine ) - 1 );
	ScriptManager:runForPlayer( 0, "prepareBunkerMissionFailed" );
end

function prepareBunkerMissionFailed()
	table.insert( queueTable, startBunkerMissionFailed );
	Utils:cutsceneQueue();
end

function startBunkerMissionFailed()
	if ScriptManager:getMissionProgress( missionIds.holdLine ) < holdLineMin then
		Utils:setMissionStatus( missionIds.holdLine, MissionStatus.FAILED );
		transitionToFail();
	end
end

function LCTDestroyed()
	ScriptManager:setMissionProgress(missionIds.destroyLCTs,ScriptManager:getMissionProgress( missionIds.destroyLCTs ) + 1 );
end

function onAiCalculated( squadId, currentOrderMessageData, allOrderMessageDataArray )
	if currentOrderMessageData ~= nil then
		if currentOrderMessageData:getOrderType() == AiOrder.MOVE then -- only continue if still in LCT
			local totalErrors = currentOrderMessageData:getErrorCount();
			
			if totalErrors > 0 then
				for i = 0, totalErrors - 1 do -- -1 cause for example with 2 errors they are @ pos 0 & 1, so there is no pos 2
					local error = currentOrderMessageData:getError( i );
					
					if	error == OrderErrorCodes.NO_PATH_FOUND or			-- no path to target
						error == OrderErrorCodes.PATH_EMPTY or				-- path blocked by units
						error == OrderErrorCodes.CAN_NOT_UNLOAD or			-- is on the beach but has no valid unload pos ( cause blocked by units )
						error == OrderErrorCodes.NO_NEW_POS_CALCULATED then	-- has not moved since last turn
						--[[
							if the initial landing position the unit gets is blocked, it moves further along the coast to the next ( up to three times )
							as i dont have a function to get the current target position of the unit and dont want to check bigger areas
							i save the squadId with a number: not saved yet / -1 = still on the way to initial position
							1 - 3 = on the way to the first/second/third new position
						]]
						local saveName	= tostring( squadId );
						local saveValue	= ScriptManager:getValue( saveName );
						
						if squadId <= 17 then -- top
							furtherLandingOrders( squadId, furtherLandingsTop, saveName, saveValue );
						
						elseif squadId <= 29 then -- mid
							-- midw with even squadId move to the right/upper side of the mid island, so they should move to top if way is blocked
							if squadId % 2 == 0 then
								furtherLandingOrders( squadId, furtherLandingsTop, saveName, saveValue );
							
							-- mid with uneven squadId move to the left/bottom side of the mid island, so they should move to bot if way is blocked
							else
								furtherLandingOrders( squadId, furtherLandingsBot, saveName, saveValue );
							end
						
						elseif squadId <= 45 then -- bot
							furtherLandingOrders( squadId, furtherLandingsBot, saveName, saveValue );
						end
						
						break;
					end
				end
			end
		end
	end
end

function furtherLandingOrders( squadId, landingPosTable, saveName, saveValue )
	ScriptManager:removeAllOrders( squadId );
		
	if saveValue == -1 then
		topBotWaveOrders( squadId, landingPosTable[1][1], landingPosTable[1][2] );
		ScriptManager:storeValue( saveName, 1 );
	
	elseif saveValue == 1 then
		topBotWaveOrders( squadId, landingPosTable[2][1], landingPosTable[2][2] );
		ScriptManager:storeValue( saveName, 2 );
	
	elseif saveValue == 2 then
		topBotWaveOrders( squadId, landingPosTable[3][1], landingPosTable[3][2] );
		ScriptManager:storeValue( saveName, -1 );
	end
end

function midWaveOrders( squadId, movePosX, movePosY )
	local southernBridge		 = Unit:getUnitById( 0 );
	local southernBridgePlayerId = southernBridge:getPlayerId();
	local northernBridge		 = Unit:getUnitById( 8 );
	local northernBridgePlayerId = northernBridge:getPlayerId();
	
	local orderId = ScriptManager:addOrder( squadId, movePosX, movePosY, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
	
	if southernBridgePlayerId == -1 then
		ScriptManager:addOrder( squadId, 12, 15, -1, 3, AiOrder.DEFEND );
		
	else
		orderId = ScriptManager:addOrder( squadId, 12, 15, -1, 4, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
	end
		
	if northernBridgePlayerId == -1 then
		ScriptManager:addOrder( squadId, 12, 15, -1, 3, AiOrder.DEFEND );
	
	else
		orderId = ScriptManager:addOrder( squadId, 17, 19, -1, 3, AiOrder.ATTACK );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_CAPTURE );
		
		orderId = ScriptManager:addOrder( squadId, 23, 28, -1, 1, AiOrder.MOVE );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
		ScriptManager:addOrder( squadId, 23, 29, -1, 1, AiOrder.DEFEND );
	end
end

function topBotWaveOrders( squadId, landPosX, landPosY )
	local orderId = ScriptManager:addOrder( squadId, landPosX, landPosY, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_MOVE_TO_COAST_AND_UNLOAD );
	
	orderId = ScriptManager:addOrder( squadId, 23, 29, -1, 2, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:addOrder( squadId, 23, 29, -1, 2, AiOrder.DEFEND );
end

function planeWave( templateId, squadId, attackPosX, attackPosY )
	ScriptManager:spawnUnit( 1, templateId, 3, 5, squadId );
	
	local orderId = ScriptManager:addOrder( squadId, attackPosX, attackPosY, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	
	orderId = ScriptManager:addOrder( squadId, 23, 29, -1, 3, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:addOrder( squadId, 23, 29, -1, 2, AiOrder.DEFEND );
end

function transportPlaneWave( transportedTemplateId, squadId, spawnPosX, spawnPosY, movePosX, movePosY )
	ScriptManager:spawnUnitWithTransporter( 1, Units.L_PLANE_TRANSPORT, transportedTemplateId, spawnPosX, spawnPosY, squadId );
	local orderId = ScriptManager:addOrder( squadId, movePosX, movePosY, -1, 1, AiOrder.MOVE );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_UNLOAD_AFTER_MOVEMENT );
end

function onEnemyTurnStart()
	-- Spawns a preset of units at the allied aircraft carrier and gives them orders to first attack a specific zone at the beach and then the German HQ.  
	local currentRound = ScriptManager:getCurrentRound();
	local orderId;
	
	if currentRound == 0 then
		for i = 1, #wave2 do
			spawnWave( wave2[i] );
		end
		
		midWaveOrders( enemySquadIds.midWave21, 15, 11 );
		
		topBotWaveOrders( enemySquadIds.topWave21, 9, 27 );
		topBotWaveOrders( enemySquadIds.topWave22, 9, 27 );
		
		topBotWaveOrders( enemySquadIds.botWave21, 21, 10 );
		topBotWaveOrders( enemySquadIds.botWave22, 21, 10 );
		
		planeWave( Units.L_PLANE_LIGHT, enemySquadIds.planeWave2, 8, 19 );
		
	elseif currentRound == 1 then
		for i = 1, #wave3 do
			spawnWave( wave3[i] );
		end
		
		midWaveOrders( enemySquadIds.midWave31,  9, 15 );
		midWaveOrders( enemySquadIds.midWave32, 11, 11 );
		midWaveOrders( enemySquadIds.midWave33,  9, 15 );
		
		topBotWaveOrders( enemySquadIds.topWave31, 3, 29 );
		
		topBotWaveOrders( enemySquadIds.botWave31, 23, 4 );
		
		planeWave( Units.L_PLANE_LIGHT, enemySquadIds.planeWave3, 24, 7 );
	
	elseif currentRound == 2 then
		for i = 1, #wave4 do
			spawnWave( wave4[i])
		end
		
		midWaveOrders( enemySquadIds.midWave41, 15, 11 );
		
		topBotWaveOrders( enemySquadIds.topWave41, 6, 26 );
		topBotWaveOrders( enemySquadIds.topWave42, 6, 26 );
		topBotWaveOrders( enemySquadIds.topWave43, 6, 26 );
		
		topBotWaveOrders( enemySquadIds.botWave41, 23, 4 );
		topBotWaveOrders( enemySquadIds.botWave42, 23, 4 );
		topBotWaveOrders( enemySquadIds.botWave43, 23, 4 );
		
		planeWave( Units.L_PLANE_LIGHT, enemySquadIds.planeWave4, 12, 15 );
		
	elseif currentRound == 3 then
		for i = 1, #wave5 do
			spawnWave( wave5[i])
		end
		
		midWaveOrders( enemySquadIds.midWave5, 9, 15 );
		
		topBotWaveOrders( enemySquadIds.topWave5, 9, 27 );
		
		topBotWaveOrders( enemySquadIds.botWave5, 21, 10 );
		
		transportPlaneWave( Units.L_INFANTRY_MG, enemySquadIds.planeWave51, 3, 5, 24, 20 );
		transportPlaneWave( Units.L_INFANTRY_MG, enemySquadIds.planeWave52, 3, 4, 13, 16 );
		transportPlaneWave( Units.L_INFANTRY_AT, enemySquadIds.planeWave53, 2, 3, 17, 30 );
	
	elseif currentRound == 4 then
		for i = 1, #wave6 do
			spawnWave( wave6[i] );
		end
		
		midWaveOrders( enemySquadIds.midWave61, 11, 11 );
		
		topBotWaveOrders( enemySquadIds.topWave61, 9, 27 );
		topBotWaveOrders( enemySquadIds.topWave62, 9, 27 );
		
		topBotWaveOrders( enemySquadIds.botWave61, 21, 10 );
		topBotWaveOrders( enemySquadIds.botWave62, 21, 10 );
		
		planeWave( Units.L_PLANE_HEAVY, enemySquadIds.planeWave6, 8, 29 );
	
	elseif currentRound == 5 then
		for i = 1, #wave7 do
			spawnWave( wave7[i])
		end
		
		midWaveOrders( enemySquadIds.midWave71,  9, 15 );
		midWaveOrders( enemySquadIds.midWave72, 15, 11 );
		midWaveOrders( enemySquadIds.midWave73,  9, 15 );
		
		topBotWaveOrders( enemySquadIds.topWave71, 3, 29 );
		
		topBotWaveOrders( enemySquadIds.botWave71, 23, 4 );
		
		planeWave( Units.L_PLANE_HEAVY, enemySquadIds.planeWave7, 24, 7 );
	
	elseif currentRound == 6 then
		for i = 1, #wave8 do
			spawnWave( wave8[i])
		end
		
		midWaveOrders( enemySquadIds.midWave8, 15, 11 );
		
		topBotWaveOrders( enemySquadIds.topWave8, 6, 26 );
		
		topBotWaveOrders( enemySquadIds.botWave8, 23, 4 );
		
		planeWave( Units.L_PLANE_BOMBER, enemySquadIds.planeWave8, 23, 29 );
	
	elseif currentRound == 7 then
		for i = 1, #wave9 do
		  spawnWave( wave9[i] )
		end
		
		topBotWaveOrders( enemySquadIds.topWave91, 6, 26 );
		topBotWaveOrders( enemySquadIds.topWave92, 6, 26 );
		
		topBotWaveOrders( enemySquadIds.botWave91, 21, 10 );
		topBotWaveOrders( enemySquadIds.botWave92, 21, 10 );
		
		planeWave( Units.L_PLANE_HEAVY, enemySquadIds.planeWave9, 23, 29 );
		
	elseif currentRound == 8 then
		for i = 1, #wave10 do
			spawnWave( wave10[i])
		end
		
		topBotWaveOrders( enemySquadIds.topWave101, 6, 26 );
		topBotWaveOrders( enemySquadIds.topWave102, 6, 26 );
		
		topBotWaveOrders( enemySquadIds.botWave101, 21, 10 );
		topBotWaveOrders( enemySquadIds.botWave102, 21, 10 );
		
		planeWave( Units.L_PLANE_BOMBER, enemySquadIds.planeWave10, 23, 29 );
	
	elseif currentRound == 9 then
		ScriptManager:runForPlayer( 0, "prepareVictoryCutscene" );
	end
end

function spawnWave( spawnData )
	ScriptManager:spawnUnitWithTransporter( 1, Units.L_SHIP_LCT, spawnData[1], spawnData[2], spawnData[3], spawnData[4] );
end


-- END
-- BEGIN Victory


function prepareVictoryCutscene()
	table.insert( queueTable, startVictoryCutscene );
	Utils:cutsceneQueue();
end

function startVictoryCutscene()
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionIds.holdLine, MissionStatus.ACCOMPLISHED );
	
	local progress = ScriptManager:getMissionProgress( missionIds.destroyLCTs );
	if progress > 0 then 
		Utils:setMissionStatus(		missionIds.destroyLCTs, MissionStatus.ACCOMPLISHED );
		ScriptManager:setMissionXp( missionIds.destroyLCTs, progress * 5 ); 
	end
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
	Utils:startCutscene();
	
	ScriptManager:moveCameraEx( 23, 29, 0.7, 5, false );
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR1 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR2 );
	ScriptManager:wait( 3 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR3) ;
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR4 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR5 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR6 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR7 );
	ScriptManager:wait( 5 );
	Utils:hideDialogue();
	
	ScriptManager:displaySubtitle( Text.T_CAMP_X1_1_VICTORY_FLAVOR8 );
	ScriptManager:wait( 3 );
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