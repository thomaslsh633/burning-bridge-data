require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
		= 1,
		= 2,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.,	true,	"tmp: ",	100 },
	{ missionIds.,	false,	"tmp: ",	 50 },
};

enemySquadIds = {

};


-- BEGIN Init


function onGameStart()
	Utils:createMissions( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:gainGold( 0, 1500 );
	
	-- start intro cutscene
	ScriptManager:sleep( 0, "startIntroCutscene" ); -- without sleep player turn popup shows
end

function storeValues()
	
end

function setTriggers()
	-- load all non-constant values at the when the player loads a game
	ScriptManager:addOnGameResumeTrigger( "loadValues", "loadValues", false )
	
	-- trigger for main building / unit
	ScriptManager:addOnUnitHasAttackedTrigger(	1, , -1,	"showAttackedWarning",	"showAttackedWarning" );
	ScriptManager:addOnUnitHasAttackedTrigger(	0, , -1,	"stopAttackingHint",	"stopAttackingHint" );
	ScriptManager:addOnUnitDestroyedTrigger(	0, , -1,	"transitionToFail",		"transitionToFail" );
	
	-- triggers for ai
	ScriptManager:addOnAiCalculationTrigger( true, "addAiOrders", "addAiOrders" );
end

function loadValues()
	
end

function addAiOrders( squadId, mainOrderData, allMainOrderData )
	if allMainOrderData:count() <= 0 then
		print( "squad #" .. squadId .. " needs new orders" );
		
		if squadId == enemySquadIds.topCrates then
			print( "received");
			ScriptManager:addOrder();--TODO
		
		elseif squadId == enemySquadIds.botCrates then
			print( "received");
		
		end
	end
end


-- END Init
-- BEGIN Intro Cutscene


function startIntroCutscene()
	Utils:startCutscene();
	
	--TODO
	
	Utils:endCutscene();
	Utils:disablePlayerInteraction();
	
	startTheMission();
end

function startTheMission()
	ScriptManager:setMissionStatus( missionIds., MissionStatus.IN_PROGRESS );
	Utils:enablePlayerInteraction();
	
	--TODO: remove this function!
	--testing();
	--removeSquads();
	--ScriptManager:addOnUnitSelectedTrigger( 1, -1, -1, "showParameters", "showParameters", false );
end

function testing()
	ScriptManager:spawnUnit( 0, Units.ALMIGHTY_GOD, 		1, 1, 42 );
	ScriptManager:spawnUnit( 0, Units.NOTSOMIGHTY_POKEY,	2, 1, 42 );
end

function removeSquads()
	--Utils:removeSquad(  );
end

function showParameters( selectedUnit )
	Utils:printUnitInfo( selectedUnit );
end


-- END Intro Cutscene
-- BEGIN


-- insert missionstuff here


-- END
-- BEGIN Victory


function startVictoryCutscene()
	Utils:startCutscene();
	
	--TODO
	
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
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, protectBuildingOrUnit );-- TODO: add templateDI @end
end

function stopAttackingHint( attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	-- TODO: add template id of protecing unit as last parameter
	Utils:attackedWarning( attacker, isAoe, defender, allUnitsHit, unitsHitCount, stopAttackingBuilding  );-- TODO: add templateDI @end
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