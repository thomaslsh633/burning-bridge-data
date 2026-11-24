require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


-- mission stuff
missionIds = {
	destroyUnits	 = 1,
	destroyBuildings = 2,
};

-- missionId, primary( boolean ), textkey, xpReward
missions = {
	{ missionIds.destroyUnits,		true,	Text.T_MULTIPLAYER_GOAL_DESTROYALL,	 0 },
	{ missionIds.destroyBuildings,	true,	Text.T_MULTIPLAYER_GOAL_DESTROYBASE, 0 },
};

alliedPlayer = -1;
axisPlayer	 = -1;

function onGameStart()
	Utils:createMissions( missions );
	
	getPlayers();
	
	ScriptManager:setMissionStatus( missionIds.destroyUnits,	 MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.destroyBuildings, MissionStatus.IN_PROGRESS );
	
	--[[
	-- trigger for checking missions
	ScriptManager:addOnUnitDestroyedTrigger( alliedPlayer,	-1, -1, "checkDestroyedX", "checkDestroyedX" ); -- also accounts for building destruction
	ScriptManager:addOnUnitDestroyedTrigger( axisPlayer,	-1, -1, "checkDestroyedL", "checkDestroyedL" ); -- also accounts for building destruction
	
	ScriptManager:addOnBunkerClearedTrigger( alliedPlayer,	-1, -1, "checkUnitMissionX", "checkUnitMissionX" );
	ScriptManager:addOnBunkerClearedTrigger( axisPlayer,	-1, -1, "checkUnitMissionL", "checkUnitMissionL" );
	
	ScriptManager:addOnUnitCapturedTrigger( alliedPlayer,	-1, -1, "checkBuildingMissionX", "checkBuildingMissionX" );
	ScriptManager:addOnUnitCapturedTrigger( axisPlayer,		-1, -1, "checkBuildingMissionL", "checkBuildingMissionL" );
	]]
	-- trigger for mission end checks
	ScriptManager:addOnUnitDestroyedTrigger( alliedPlayer,	-1, -1, "checkForEndX", "checkForEndX" );
	ScriptManager:addOnUnitDestroyedTrigger( axisPlayer,	-1, -1, "checkForEndL", "checkForEndL" );
	
	ScriptManager:addOnUnitCapturedTrigger( axisPlayer,		-1, -1, "checkForEndX", "checkForEndX" );
	ScriptManager:addOnUnitCapturedTrigger( alliedPlayer,	-1, -1, "checkForEndL", "checkForEndL" );
	
	ScriptManager:addOnBunkerClearedTrigger( alliedPlayer,	-1, -1, "checkForEndX", "checkForEndX" );
	ScriptManager:addOnBunkerClearedTrigger( axisPlayer,	-1, -1, "checkForEndL", "checkForEndL" );
	
	-- trigger for getting back players
	ScriptManager:addOnTurnStartTrigger( -1, -1, -1, "getPlayers", "getPlayers" );
end

function getPlayers()
	axisPlayer	 = ScriptManager:getPlayerByFactionID( FactionId.AXIS );
	alliedPlayer = ScriptManager:getPlayerByFactionID( FactionId.ALLIES );
end

--[[ BEGIN Mission Updates


function checkDestroyedX( unit )
	if checkDestroyed( unit ) then
		checkBuildingMissionX();
	
	else
		checkUnitMissionX();
	end
end

function checkDestroyedL( unit )
	if checkDestroyed( unit ) then
		checkBuildingMissionL();
	
	else
		checkUnitMissionL();
	end
end

function checkDestroyed( unit )
	local templateId = unit:getTemplateId();
	
	-- if destroyed unit is a building, return true
	if	templateId == Units.L_BUILDING_AIRFIELD		or templateId == Units.L_BUILDING_HQ or
		templateId == Units.X_BUILDING_AIRFIELD		or templateId == Units.X_BUILDING_HQ or
		templateId == Units.N_BUILDING_TANKFACTORY	or templateId == Units.N_BUILDING_CRATES or
		templateId == Units.N_BRIDGE_L				or templateId == Units.N_BRIDGE_M or
		templateId == Units.N_BRIDGE_RAIL then
		return true;
	
	else
		return false
	end
end

function checkBuildingMissionX()

end

function checkBuildingMissionL()

end

function checkBuildingMission()

end


-- END Mission Updates]]
-- BEGIN End Checks


function checkForEndX()
	checkForEnd( alliedPlayer );
end

function checkForEndL()
	checkForEnd( axisPlayer );
end

function checkForEnd( playerId )
	
	if ScriptManager:noUnitsLeftExt( { playerId, Units.N_MINE_LAND,		Units.N_BRIDGE_L,			Units.N_BRIDGE_M,			Units.N_BRIDGE_RAIL,
												 Units.N_BRIDGE_RAIL,	Units.N_EMPLACEMENT_METAL,	Units.N_EMPLACEMENT_WIRE } ) then
		local winner = 0;
		
		if playerId == 0 then
			winner = 1;
		end
		
		ScriptManager:endMultiplayerGame( winner );
	end
end


-- END End Checks