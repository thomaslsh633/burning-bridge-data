require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"

missionIds = {
	destroyHQ = 1,
	destroyAC = 2,
};

missions = {
	{ missionIds.destroyHQ, true, Text.T_MISSION_DESTROY_BASE,	100, FactionId.ALLIES },
	{ missionIds.destroyAC, true, Text.T_MISSION_DESTROY_ACS,	100, FactionId.AXIS },
	-- costs gold --> reward the player with xp equal to the gold he has to spend
};

function onGameStart()
	Utils:createMissionForFaction( missions );
	setTriggers();
	storeValues();
	
	ScriptManager:setMissionStatus( missionIds.destroyHQ, MissionStatus.IN_PROGRESS );
	ScriptManager:setMissionStatus( missionIds.destroyAC, MissionStatus.IN_PROGRESS );
	
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME,  8, 6, -1 )
	ScriptManager:spawnUnitWithTransporter( 0, Units.L_SHIP_LCT, Units.L_INFANTRY_FLAME, 32, 6, -1 )
end

function storeValues()
	ScriptManager:storeValue( "AC", 2 );
end

function setTriggers()
	-- trigger for main building / unit
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.X_BUILDING_HQ_NOTCAPTURABLE, -1, "HQDestroyed", "HQDestroyed" );
	ScriptManager:addOnUnitDestroyedTrigger( -1, Units.L_SHIP_AC,					-1, "ACDestroyed", "ACDestroyed" );
end

function HQDestroyed()
	local alliedPlayer = ScriptManager:getPlayerByFactionID( FactionId.ALLIES );
	ScriptManager:endMultiplayerGame( alliedPlayer );
end

function ACDestroyed()
	ScriptManager:storeValue( "AC", ScriptManager:getValue( "AC" ) - 1 );
	
	if ScriptManager:getValue( "AC" ) <= 0 then
		local axisPlayer = ScriptManager:getPlayerByFactionID( FactionId.AXIS );
		ScriptManager:endMultiplayerGame( axisPlayer );
	end
end