require "lua/Units"
-- various useful functions, ~fst!

Utils = {}
Utils.___index = Utils

-- blocks all possible player input
function Utils.disablePlayerInteraction()
	ScriptManager:blockUI( true );
	--ScriptManager:disableEndTurnButton();
end

-- player can do stuff in the game again
function Utils.enablePlayerInteraction()
	--ScriptManager:enableEndTurnButton();
	ScriptManager:blockUI( false );
end

-- creates all mission from a table. table format: missionId, primary ( bool ), textkey, xp
function Utils.createMissions( class_table, missionContent )
	for i = 1, #missionContent do
		local data = missionContent[i];
		--print( string.format( "Created mission: %s", data[3] ) );
		ScriptManager:createMission( data[1], data[2], data[3] );
		ScriptManager:setMissionXp(	 data[1], data[4] );
	end
end

-- creates all mission from a table. table format: missionId, primary ( bool ), textkey, xp
function Utils.createMissionForFaction( class_table, missionContent )
	for i = 1, #missionContent do
		local data = missionContent[i];
		--print( string.format( "Created mission: %s", data[3] ) );
		ScriptManager:createMissionForFaction(	data[1], data[2], data[3], data[5] );
		ScriptManager:setMissionXp(				data[1], data[4] );
	end
end

-- increases the mission progress by 1
function Utils.incrementMissionProgress( class_table, missionId )
	updateMissionProgress( missionId, 1 );
end

-- decreases the mission progress by 1
function Utils.decrementMissionProgress( class_table, missionId )
	updateMissionProgress( missionId, -1 );
end

function updateMissionProgress( missionId, value )
	ScriptManager:setMissionProgress( missionId, ScriptManager:getMissionProgress( missionId ) + value );
end

-- shows progress of do x/y type missions
function Utils.showMissionProgress( class_table, missionProgress, textKey )
	Utils:disablePlayerInteraction();
	
	ScriptManager:preparePopupText();
	ScriptManager:addPopupTextParameter( "x", missionProgress );
	Utils:displaySubtitleWithDuration( textKey, 2 );
	
	Utils:enablePlayerInteraction();
end

-- shows progress fo do x/y type missions where both x & y are unknown / variable
function Utils.showMissionProgressTwoVar( class_table, missionProgress, endValue, textKey )
	Utils:disablePlayerInteraction();
	
	ScriptManager:preparePopupText();
	ScriptManager:addPopupTextParameter( "x", missionProgress );
	ScriptManager:addPopupTextParameter( "y", endValue );
	
	Utils:displaySubtitleWithDuration( textKey, 2 );
	
	Utils:enablePlayerInteraction();
end

-- blocks player input, updates a mission status, waits 2 seconds and enables user input again
function Utils.setMissionStatus( class_table, missionId, missionStatus )
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus( missionId, missionStatus );
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

-- blocks player input, updates a mission status & progress, waits 2 seconds and enables user input again
function Utils.setMissionStatusAndProgress( class_table, missionId, missionStatus, missionProgress, maxValue )
	Utils:disablePlayerInteraction();
	
	ScriptManager:setMissionStatus(		 missionId, missionStatus );
	ScriptManager:setMissionProgress(	 missionId, missionProgress );
	ScriptManager:setMaxMissionProgress( missionId, maxValue );
	ScriptManager:wait( 2 );
	
	Utils:enablePlayerInteraction();
end

-- sets mission progress and max progress
function Utils.setMissionProgress( class_table, missionId, missionProgress, maxValue )
	ScriptManager:setMissionProgress(	 missionId, missionProgress );
	ScriptManager:setMaxMissionProgress( missionId, maxValue );
end

-- loads a otherwise table from single values in the save file; format: "saveName_*counter*"
function Utils.loadValuesFromSavefileIntoEmptyTable( class_table, saveName )
	local value = 0;
	local returnTable = {};
	local searchNumber = ScriptManager:getValue( string.format( "%s_highest", saveName ) );
	if searchNumber <= 0 then
		print( "search index invalid" );
	
	else
		for i = 1, searchNumber do
			value = ScriptManager:getValue( string.format( "%s_%i", saveName, i ) );
			
			if value ~= nil and value ~= -1 then
				print( string.format("%i inserted", value ) );
				table.insert( returnTable, value );
			end
		end
	end
	
	return returnTable;
end

-- adds a single value to table and saves ( only works if table fits the EMPTY TABLE functions! )
function Utils.addValueToTableAndSave( class_table, value, saveName, saveTable )
	table.insert( saveTable, value );
	
	ScriptManager:storeValue( string.format( "%s_%i", saveName, value ), value );
	local highest = ScriptManager:getValue( string.format( "%s_highest", saveName ) );
	
	if value > highest then
		ScriptManager:storeValue( string.format( "%s_highest", saveName ), value );
	end
	
	return saveTable;
end

-- removes a single value to table and saves ( only works if table fits the EMPTY TABLE functions! )
function Utils.removeValueFromTableAndSave( class_table, value, saveName, saveTable )
	local found = false;
	for i = 1, #saveTable do
		if saveTable[i] == value then
			table.remove( saveTable, i );
			ScriptManager:deleteValue( string.format( "%s_%i", saveName, value ) );
			
			found = true;
			
			break;
		end
	end
	
	-- i do not update the highest number / check if the removed number was the highest because it does not break anything and
	-- looking for / updating it is more effort than just searching a few entries more than needed. on a table save its updated anyways
	
	if found == false then
		print( "ERROR, value was not found. The table has not been changed" );
	end
	
	return saveTable;
end

-- saves all values from a table into single save file entries by their value
function Utils.saveValuesIntoSavefileForEmptyTable( class_table, saveName, table )
	-- highest number used to know exactly how far to search when loading the table
	local highestNumber = 0;
	for i = 1, #table do
		-- need to save the ids in the name cause otherwise there might get holes into the coutn if i just go 1++
		ScriptManager:storeValue( string.format( "%s_%i", saveName, table[i] ), table[i] );
		if table[i] > highestNumber then
			highestNumber = table[i];
		end
	end
	ScriptManager:storeValue( string.format( "%s_highest", saveName ), highestNumber );
end

-- loads an existing table from single values in the save file; format: "saveName_*counter*"
function Utils.loadValuesFromSavefileIntoExistingTable( class_table, saveName, saveTable )
	local value = 0;
	
	for i = 1, #saveTable do
		value = ScriptManager:getValue( string.format( "%s_%i", saveName, i ) );
		
		if value ~= nil and value ~= -1 then
			saveTable[i] = value;
			--print( string.format("%i loaded into slot %i", value, i ) );
		else
			break;			
		end
	end
	
	return saveTable;
end

-- saves all values from a table into single save file entries sorting by order ( 1,2,3,...)
function Utils.saveValuesIntoSavefileForExistingTable( class_table, saveName, table )
	for i = 1, #table do
		ScriptManager:storeValue( string.format( "%s_%i", saveName, i ), table[i] );
	end
end

function Utils.antiRush()
	ScriptManager:wait( 1 );
end

function Utils.hideDialogue()
	ScriptManager:dismissSubtitle();
	Utils:antiRush();
end

function Utils.hideAllMarkers()
	ScriptManager:removeAllMarkers();
	ScriptManager:hideFinger();
end

-- starts cutscene and waits 1 second
function Utils.startCutscene()
	ScriptManager:startCutscene();
	Utils:antiRush();
end

-- displays textkey, waits "duration" seconds and hides it
function Utils.displaySubtitleWithDuration( class_table, textkey, duration )
	ScriptManager:displaySubtitle( textkey );
	ScriptManager:wait( duration );
	Utils:hideDialogue();
end

-- checks if mission is still in progress and accomplish if it is
function Utils.missionCheckerAccomplish( class_table, missionId )
	if  ScriptManager:getMissionStatus( missionId ) ==	MissionStatus.IN_PROGRESS  then
		ScriptManager:setMissionStatus( missionId, MissionStatus.ACCOMPLISHED );
	end
end

-- waits 1 second and ends the cutscene
function Utils.endCutscene()
	Utils:antiRush();
	ScriptManager:stopCutscene();
end

function Utils.endGame()
	ScriptManager:endGame();
end

-- shows the unitId, squadId and playerId of given unit
function Utils.printUnitInfo( class_table, unit )	
	print( string.format(	"unitId: %i; squadID: %i; templateId: %i; hp: %i;", 
							unit:getId(), unit:getSquadId(), unit:getTemplateId(), unit:getHealth() ) );
end

-- adds onEnterTile trigger in a circle around the x & y coordinates + one on the x & y
function Utils.addOnEnterCircleTrigger(class_table, posX, posY, radius, playerId, templateId, instanceId, stopUnit, callbackName, triggerId )
	local xyDiff = posY % 2;
	local  rDiff = radius % 2;
	local x, y;
	
	-- topLeft
	if rDiff == 0 then
		x = posX - math.floor( radius / 2 );
	else
		x = posX - math.floor( radius / 2 ) + xyDiff - 1;
	end
	for i = 0, radius -1 do
		print( "@" .. x + i .. " | " .. posY + radius );
		ScriptManager:addOnEnterTileTrigger( x + i, posY + radius, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	end
	
	--topRight
	if rDiff == 0 then
		x = posX + math.floor( radius / 2 );
	else
		x = posX + math.floor( radius / 2 ) + xyDiff;
	end
	for i = 0, radius -1 do
		y = posY + radius - i
		print( "@" .. x .. " | " .. y );
		ScriptManager:addOnEnterTileTrigger( x, y, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
		
		if y % 2 == 1 then
			x = x + 1;
		end
	end
	
	-- right
	x = posX + radius;
	for i = 0, radius -1 do
		y = posY - i;
		print( "@" .. x .. " | " .. y );
		ScriptManager:addOnEnterTileTrigger( x, y, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
		
		if y % 2 == 0 then
			x = x - 1;
		end
	end
	
	-- botRight
	if rDiff == 0 then
		x = posX + math.floor( radius / 2 );
	else
		x = posX + math.floor( radius / 2 ) + xyDiff;
	end
	for i = 0, radius -1 do
		print( "@" .. x - i .. " | " .. posY - radius );
		ScriptManager:addOnEnterTileTrigger( x - i, posY - radius, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	end
	
	-- botLeft
	if rDiff == 0 then
		x = posX - math.floor( radius / 2 );
	else
		x = posX - math.floor( radius / 2 ) + xyDiff - 1;
	end
	for i = 0, radius -1 do
		y = posY - radius + i
		print( "@" .. x .. " | " .. y );
		ScriptManager:addOnEnterTileTrigger( x, y, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
		
		if y % 2 == 0 then
			x = x - 1;
		end
	end
	
	-- left
	x = posX - radius;
	for i = 0, radius -1 do
		y = posY + i;
		print( "@" .. x .. " | " ..  y );
		ScriptManager:addOnEnterTileTrigger( x, y, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
		
		if y % 2 == 1 then
			x = x + 1;
		end
	end
end

-- adds onEnterTile trigger in a circle around the x & y coordinates + one on the x & y
function Utils.addOnEnterAreaTrigger(class_table, posX, posY, radius, playerId, templateId, instanceId, stopUnit, callbackName, triggerId )
	local xyDiff = posY % 2;
	local  rDiff = radius % 2;
	local x;
	
	-- center
	if posX > 0 and posY > 0 then
		ScriptManager:addOnEnterTileTrigger( posX, posY, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
		print( string.format( "trigger @ %i | %i", posX, posY ) );
	
	else
		print( "invalid trigger pos @ " .. posX .. " | " .. posY .. " trigger has not been created for that position" )
	end
	
	-- topLeft
	if rDiff == 0 then
		x = posX - math.floor( radius / 2 );
	else
		x = posX - math.floor( radius / 2 ) + xyDiff - 1;
	end
	createSector( x, posY + radius, radius, 1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	
	--topRight
	if rDiff == 0 then
		x = posX + math.floor( radius / 2 );
	else
		x = posX + math.floor( radius / 2 ) + xyDiff;
	end
	createSector( x, posY + radius, radius, -1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	
	-- right
	createSector( posX + 1, posY, radius, 1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	
	-- botRight
	x = posX + xyDiff;
	createSector( x, posY - 1, radius, -1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	
	-- botLeft
	x = posX + xyDiff - radius;
	createSector( x, posY - 1, radius, 1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
	
	-- left
	if rDiff == 0 then
		x = posX - math.floor( radius / 2 ) + xyDiff - 1;
	else
		x = posX - math.floor( radius / 2 ) - 1;
	end
	createSector( x, posY + radius - 1, radius, -1, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
end

function createSector( posX, posY, radius, direction, playerId, templateId, instanceId, stopUnit, callbackName, triggerId )
	local xyDiff;
	local indicator;
	
	-- 1 == triangle facing down; -1 = triangle facing up
	if direction == 1 then
		indicator = radius - 1;
		
	elseif direction == -1 then
		indicator = 0;
	end
	
	for y = posY, posY - radius + 1, -1 do
		for i = 0, indicator, direction do
			if posX + i > 0 and y > 0 then
				ScriptManager:addOnEnterTileTrigger( posX + i, y, playerId, templateId, instanceId, stopUnit, callbackName, triggerId );
				print( string.format( "trigger @ %i | %i", posX + i, y ) );
			
			else
				print( "invalid trigger pos @ " .. posX + i .. " | " .. y .. " trigger has not been created for that position" )
			end
		end
		
		indicator = indicator - 1;
		
		xyDiff = y % 2;
		if xyDiff == 1 then
			posX = posX + 1;
		end
	end
end

-- moves camera to a unit and shows marker ( without fow reveal! )
function Utils.highlightUnit( class_table, posX, posY, camMoveDuration, shouldBlock, markerSize )
	ScriptManager:moveCameraEx( posX, posY, 0.8, camMoveDuration, shouldBlock );
	
	if markerSize == 1 then
		ScriptManager:showScaledMarkerAt( posX, posY, 1.3875, true, true );
		
	elseif markerSize == 2 then
		ScriptManager:showScaledMarkerAt( posX, posY, 1.75, true, true );
	
	else
		ScriptManager:showMarkerAt( posX, posY );
	end
end

-- reveals fow and marks a unit
function Utils.markUnit( class_table, posX, posY, revealRadius, markDuration, markerSize )
	ScriptManager:revealFogOfWar( posX, posY, revealRadius, true );
	--TODO: if unit is on a bridge, the marker will be under the bridge. if that should change, new function needed
	if markerSize == 1 then
		ScriptManager:showScaledMarkerAt( posX, posY, 1.3875, true, true );
		
	elseif markerSize == 2 then
		ScriptManager:showScaledMarkerAt( posX, posY, 1.75, true, true );
	
	else
		ScriptManager:showMarkerAt( posX, posY, true, true );
	end
	
	ScriptManager:wait( markDuration );
	
	ScriptManager:hideMarkerAt( posX, posY );
	ScriptManager:revealFogOfWar( posX, posY, revealRadius, false );
end

-- stealths all units in given table
function Utils.camouflageSquad( class_table, unitIdTable )
	for i = 1, #unitIdTable do
		ScriptManager:camouflageUnit( unitIdTable[i] );
	end
end

-- standard attack order for units
function Utils.attackOrder( class_table, squadId, posX, posY, radius )
	local orderId = ScriptManager:addOrder( squadId, posX, posY, -1, radius, AiOrder.ATTACK );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
	
	ScriptManager:addOrder( squadId, posX, posY, -1, radius, AiOrder.DEFEND );
end

-- checks if the squad has waypoints left, if not adds new ones
function Utils.checkWaypoints( class_table, squadId, mainOrderData, allMainOrderData, waypointTable )
	if allMainOrderData:count() <= 0 then
		Utils:addWaypoints( squadId, waypointTable );
	end
end

-- adds multiple waypoints as orders to a squad
function Utils.addWaypoints( class_table, squadId, waypointTable )
	for i = 1, #waypointTable do
		local orderId = ScriptManager:addOrder( squadId, waypointTable[i][1], waypointTable[i][2], -1, 1, AiOrder.MOVE );
		ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_HOLD_FIRE )
	end
end

-- get the coordinates of the next free surrounding tile or nil if there is no free tile
function Utils.getNextFreeNeighbouringHexTile(class_table, originTileX, originTileY)
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
				if(Unit:getUnitAt(originTileX + j, originTileY + i) == nil) then
					return originTileX + j, originTileY + i;
				end
			end
		end
	end

	return 0, 0;
end

-- table order: playerId, templateID, tileX, tileY, squadId, returns unitId
function Utils.spawnUnitFromTable( class_table, spawnData )
	local unit = ScriptManager:spawnUnit( spawnData[1], spawnData[2], spawnData[3], spawnData[4], spawnData[5] );
	
	return unit:getId();
end
 
function Utils.spawnUnitFromShortTable( class_table, playerId, squadId, restDataTable )
	local unit = ScriptManager:spawnUnit( playerId, restDataTable[1], restDataTable[2], restDataTable[3], squadId );
	
	return unit:getId();
end

-- spawn a unit from a table inside a transportUnitTemplateID
-- table order: playerId, templateID, tileX, tileY, squadId, returns unitId
function Utils.spawnUnitInTransporter( class_table, spawnData, transportUnitTemplateId )
	local transporter = ScriptManager:spawnUnitWithTransporter( spawnData[1], transportUnitTemplateId, spawnData[2], 
																spawnData[3], spawnData[4], spawnData[5] );
	local transportId = transporter:getId();
	-- store the unitId into saveFile in order to retrieve & unload it later on
	ScriptManager:storeValue( "transportedUnit", ScriptManager:getUnitIdFromTransporterByIndex( transportId, 0 ) );
	
	return transportId;
end

-- unloads unitInTransporterId from transporterId
function Utils.moveTransporterAndUnloadIt(  class_table, transporterId, unitInTransporterId, 
											movePosX, movePosY, unloadPosX, unloadPosY )
	ScriptManager:moveUnitEx( transporterId, movePosX, movePosY, true );
	ScriptManager:unloadUnitFromTransporterEx( transporterId, unitInTransporterId, unloadPosX, unloadPosY, true );
end

-- removes multiple units using a table with their ids
function Utils.removeSquad( class_table, squadIds )
	for i = 1, #squadIds do
		ScriptManager:removeUnitEx( squadIds[i], false );
	end
end

-- sets health of killedUnit to 1, then attacker attacks killedUnit and kills it
function Utils.killUnit( class_table, attackerUnitId, killedUnitId )
	Unit:getUnitById( killedUnitId ):setHealth( 1 );
	ScriptManager:attackUnitEx( attackerUnitId, killedUnitId, true );
end

function Utils.setIsAttackable( class_table, unitId, isAttackable )
	local unit = Unit:getUnitById( unitId );
	unit:setIsAttackable( isAttackable );
end

function Utils.setCanBeCaptured( class_table, unitId, isCaptureable )
	local unit = Unit:getUnitById( unitId );
	unit:setCanBeCaptured( isCaptureable );
end

function Utils.checkForAoe( class_table, attacker, isAoe, defender, allUnitsHit, unitsHitCount )
	if isAoe == 0 then
		-- no aoe, so there is no table to return, and trigger can be used like normally ( with attacker & defender )
		return -1, -1;
	
	else
		local unitTable = {};
		
		if unitsHitCount > 0 then
			--print( allUnitsHit:count() );
			
			for i = 0, allUnitsHit:count() - 1, 1 do
				local unit = tolua.cast( allUnitsHit:objectAtIndex( i ), "Unit" );
				table.insert( unitTable, unit );
				--print( string.format( "unit %i was hit", unit:getId() ) );
			end
			
			-- aoe, at least one unit was hit, all units are in unitTable, dont specificly check for a defender as he is within the table
			-- only check for defender if you really need the one unit that attacked back ( which is not rly important imho )
			return 1, unitTable;
		
		else
			--print( "no one hit" );
			-- aoe, but no one was hit, so dont check for a defender
			return 0, -1		
		end
	end
end

function Utils.attackedWarning( class_table, attacker, isAoe, defender, allUnitsHit, unitsHitCount, warningFunctionName, neededTemplateId )
	local attackerTemplateId = attacker:getTemplateId();
	
	if attackerTemplateId ~= Units.N_MINE_LAND then
		local hitDefine, unitTable = Utils:checkForAoe( attacker, isAoe, defender, allUnitsHit, unitsHitCount );
		
		if hitDefine == -1 then -- no aoe
			warningFunctionName( defender );
		
		elseif hitDefine == 1 then -- multiple units hit
			local templateId;
			for i = 1, #unitTable do
				if unitTable[i]:getTemplateId() == neededTemplateId then
					warningFunctionName( unitTable[i] );
				end
			end
		end
	end
end

-- i can't remove the trigger after first attack so i need a var to check it
alreadyTriggered =  0;
defenderId		 = -1;

--protect message. message varies depending on unit. needs onunithasattackedtrigger
function protectBuildingOrUnit( defender )
	defenderId = defender:getId()
	templateId = defender:getTemplateId();
	
	if alreadyTriggered == 0 then
		alreadyTriggered = 1;
		ScriptManager:runForPlayer( 0, "prepareProtectIt" );
	end
end

function prepareProtectIt()
	alreadyTriggered = 0;
	table.insert( queueTable, protectIt );
	Utils:cutsceneQueue();
end

function protectIt()
	local unit = Unit:getUnitById( defenderId );
	local markerSize = 0
	
	if unit ~= nil then
		if unit:getPlayerId() == 0 then
			Utils:disablePlayerInteraction();
			
			-- check if it's a building or unit and show the right text
			if  templateId == Units.L_BUILDING_AIRFIELD or templateId == Units.L_BUILDING_HQ or
				templateId == Units.X_BUILDING_AIRFIELD or templateId == Units.X_BUILDING_HQ or templateId == Units.N_BUILDING_CRATES then
				ScriptManager:displaySubtitle( Text.T_MISSION_BUILDING_ATTACKED_WARNING );
				
			else
				ScriptManager:displaySubtitle( Text.T_MISSION_UNIT_ATTACKED_WARNING );
				
				if  templateId == Units.L_SHIP_BS or templateId == Units.N_BRIDGE_L or templateId == Units.N_BRIDGE_M or templateId == Units.X_ARTILLERY_GUSTAF then
					markerSize = 1;
				
				elseif templateId == Units.L_SHIP_AC then
					markerSize = 2;				
				end
			end
			
			Utils:highlightUnit( unit:getX(), unit:getY(), 2, true, markerSize );
			
			ScriptManager:wait( 2 );
			Utils:hideAllMarkers();
			Utils:hideDialogue();
			
			Utils:enablePlayerInteraction();
		end
	end
end

function stopAttackingBuilding( defender )
	local defenderX = defender:getX();
	local defenderY = defender:getY();
	local unit = Unit:getUnitAt( defenderX, defenderY );
	
	if unit ~= nil and unit:getIsHidden() == false then
		Utils:disablePlayerInteraction();
		
		ScriptManager:displaySubtitle( Text.T_MISSION_BUILDING_ATTACKED_BY_PLAYER );
		
		Utils:highlightUnit( defenderX, defenderY, 2, true, 0 );
		ScriptManager:wait( 2 );
		Utils:hideAllMarkers();
		Utils:hideDialogue();
		
		Utils:enablePlayerInteraction();
	end
end

-- queue functions
queueTable		= {};
showedScenes	= {};
cutsceneActive	= 0;

-- queues multiple cutscenes and plays one after another,
function Utils.cutsceneQueue( class_table )
	--print( "Cutscenes left = "..#queueTable);
	--print( "Cutscene is active = "..cutsceneActive );
	local cutscene		= nil;
	local alreadySeen	= false;
	
	Utils:disablePlayerInteraction();
	ScriptManager:wait( 0.75 ); -- ensures that all counters are done before playing the cutscene
	Utils:enablePlayerInteraction();
	
	if #queueTable > 0 and cutsceneActive == 0 then -- check to start the function only once
		Utils:disablePlayerInteraction();
		
		cutscene = queueTable[1]; -- get cutscene
		
		--check if cutscene was already played before
		if #showedScenes > 0 then
			for i = 1, #showedScenes do
				if showedScenes[i] == cutscene then
					alreadySeen = true;
					break;
				end
			end
		end
		
		-- only show the cutscene if it has not been seen this turn
		if alreadySeen == false then
			cutsceneActive = 1;
			
			cutscene(); -- play cutscene
			table.insert( showedScenes, cutscene );
		end
		
		table.remove( queueTable, 1 ); -- remove cutscene
		
		cutsceneActive = 0;
		transitionToCutsceneQueue();-- repeat and check if there are more subtitles to play left
	else
		showedScenes = {};
	end
end

function transitionToCutsceneQueue()	
	Utils:enablePlayerInteraction();
	
	ScriptManager:dismissSubtitle();
	Utils:cutsceneQueue();
end

-- controller functions
controllerButtonPressedCount	= 0;
controllerButtonPressesNeeded	= 0;

-- shows a graphic with highlighted face button that stays visible until buttonConstant has been buttonpressesNeeded times pressed
function Utils.showControllerButtonGfx( class_table, buttonConstant, buttonPressesNeeded, tileX, tileY, enableCursor )
	ScriptManager:showControllerButtonAtTile( buttonConstant, tileX, tileY, 0.2 );
	
	controllerButtonPressesNeeded = buttonPressesNeeded;
	
	if enableCursor then
		ScriptManager:addOnControllerButtonReleasedTrigger( buttonConstant, "removeControllerButtonGfxEnabler", "removeControllerButtonGfx" );
	
	else
		ScriptManager:addOnControllerButtonReleasedTrigger( buttonConstant, "removeControllerButtonGfxDisable", "removeControllerButtonGfx" );
	end
end

function removeControllerButtonGfxEnable()
	removeControllerButtonGfx();
	ScriptManager:setControllerCursorEnabled( true );
end

function removeControllerButtonGfxDisable()
	removeControllerButtonGfx()
	ScriptManager:setControllerCursorEnabled( false );
end

function removeControllerButtonGfx()
	controllerButtonPressedCount = controllerButtonPressedCount + 1;
	--print( string.format( "button %i x pressed; %i presses needed", controllerButtonPressedCount, controllerButtonPressesNeeded ) );
	
	if controllerButtonPressedCount >= controllerButtonPressesNeeded then
		ScriptManager:hideControllerButton();
		ScriptManager:removeTrigger( "removeControllerButtonGfx" );
		
		controllerButtonPressedCount	= 0;
		controllerButtonPressesNeeded	= 0;
	end
end

function Utils.cursorOverUnitSinglePressDisable( class_table, tileX, tileY, enableCursor )
	cursorOver();
	showControllerButtonGfx( ControllerButton.FACE_DOWN, 1, tileX, tileY, 0.2, enableCursor );
end

function Utils.cursorOverUnitDoublePressDisable( class_table, tileX, tileY, enableCursor )
	cursorOver();
	showControllerButtonGfx( ControllerButton.FACE_DOWN, 2, tileX, tileY, 0.2, enableCursor );
end

function cursorOver()
	Utils:hideAllMarkers();
	ScriptManager:setControllerCursorEnabled( false );
	ScriptManager:removeTrigger( "cursorOverUnit" ); -- TODO: always name the triggers like this or it won't work!
end

function Utils.cleanupController( class_table )
	ScriptManager:removeTrigger( "cursorOverUnit" );
	ScriptManager:hideControllerButton();
end

function Utils.checkControllerAndHideButton( class_table )
	if ScriptManager:isControllerConnected() then
		ScriptManager:hideControllerButton();
	end
end

function Utils.onControllerConnect( class_table )
	ScriptManager:setControllerCursorEnabled( true );
	ScriptManager:hideFinger();
end

function Utils.onControllerDisconnect( class_table )
	ScriptManager:hideControllerButton();
end

-- enables the tile, marks it and depending on controller or not adds the finger or cursor tile trigger
function Utils.tutorialAttackOrMovePreparation( class_table, targetPosX, targetPosY )
	ScriptManager:disableAllTilesExcept( targetPosX, targetPosY );
	ScriptManager:showMarkerAt( targetPosX, targetPosY );
	
	if ScriptManager:isControllerConnected() then
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitDoublePressDisable", "cursorOverUnit" );
		ScriptManager:setControllerCursorEnabled( true );
	
	else
		ScriptManager:moveFingerToTile( targetPosX, targetPosY );
		ScriptManager:loopFingerClicks( 1.5 );
	end
end

-- enables the tile, marks it and depending on controller or not adds cursor tile trigger
function Utils.tutorialAttackOrMovePreparationNoFinger( class_table, targetPosX, targetPosY )
	Utils:tutorialAttackOrMovePreparationScaleMarker( targetPosX, targetPosY, 1 );
end

-- enables the tile, marks it and depending on controller or not adds cursor tile trigger
function Utils.tutorialAttackOrMovePreparationScaleMarker( class_table, targetPosX, targetPosY, markerScale )
	ScriptManager:disableAllTilesExcept( targetPosX, targetPosY );
	ScriptManager:showScaledMarkerAt( targetPosX, targetPosY, markerScale );
	
	if ScriptManager:isControllerConnected() then
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitDoublePressDisable", "cursorOverUnit" );
		ScriptManager:setControllerCursorEnabled( true );
	end
end

-- enables the tile, marks it and depending on controller or not adds cursor tile trigger
function Utils.tutorialAttackOrMovePreparationAddTile( class_table, targetPosX, targetPosY, needsMarker )
	ScriptManager:enableAdditionalTile( targetPosX, targetPosY );
	
	if needsMarker then
		ScriptManager:showMarkerAt( targetPosX, targetPosY );
	end
	
	if ScriptManager:isControllerConnected() then
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitDoublePressDisable", "cursorOverUnit" );
		ScriptManager:setControllerCursorEnabled( true );
	end
end

-- enables the tile, marks it and depending on controller or not adds the finger or cursor tile trigger
function Utils.tutorialSelectionPreparation( class_table, targetPosX, targetPosY )
	ScriptManager:disableAllTilesExcept( targetPosX, targetPosY );
	ScriptManager:showMarkerAt( targetPosX, targetPosY );
	
	
	if ScriptManager:isControllerConnected() then		
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitSinglePressDisable", "cursorOverUnit" );
	
	else		
		ScriptManager:showFingerAtTile( targetPosX, targetPosY, 1.5 );
		ScriptManager:loopFingerClicks( 1.5 );
	end
end

-- enables the tile, marks it and depending on controller or not addscursor tile trigger
function Utils.tutorialSelectionPreparationNoFinger( class_table, targetPosX, targetPosY )
	Utils:tutorialSelectionPreparationScaleMarker( targetPosX, targetPosY, 1 );
end

function Utils.tutorialSelectionPreparationScaleMarker( class_table, targetPosX, targetPosY, markerScale )
	ScriptManager:disableAllTilesExcept( targetPosX, targetPosY );
	ScriptManager:showScaledMarkerAt( targetPosX, targetPosY, markerScale );
	
	if ScriptManager:isControllerConnected() then		
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitSinglePressDisable", "cursorOverUnit" );
	end
end

-- enables the tile, marks it and depending on controller or not addscursor tile trigger
function Utils.tutorialSelectionPreparationAddTile( class_table, targetPosX, targetPosY, needsMarker )
	ScriptManager:enableAdditionalTile( targetPosX, targetPosY );
	
	if needsMarker then
		ScriptManager:showMarkerAt( targetPosX, targetPosY );
	end
	
	if ScriptManager:isControllerConnected() then		
		ScriptManager:addOnControllerSelectedTileTrigger( targetPosX, targetPosY, "cursorOverUnitSinglePressDisable", "cursorOverUnit" );
	end
end

--enables & unblocks an ability button and highlight it ( = wobble )
function Utils.tutorialEnableAndHighlightButton( class_table, interactionButton )
	ScriptManager:unblockInteractionButton( 			interactionButton );
	ScriptManager:startHighlightingInteractionButton(	interactionButton );
	ScriptManager:enableInteractionButton(				interactionButton );
end

--shows and block an interaction button
function Utils.tutorialEnableAndBlockButton( class_table, interactionButton )
	ScriptManager:enableInteractionButton(	interactionButton );
	ScriptManager:blockInteractionButton( 	interactionButton );
end

-- disables an ability button
function Utils.tutorialDisableButton( class_table, interactionButton )
	ScriptManager:stopHighlightingInteractionButton( interactionButton );
	ScriptManager:disableInteractionButton(			 interactionButton );
end

-- blocks an ability button
function Utils.tutorialBlockButton( class_table, interactionButton )
	ScriptManager:stopHighlightingInteractionButton( interactionButton );
	ScriptManager:blockInteractionButton( 			 interactionButton );	
end

-- used at the beginning of every function to block the player and remove subtitles / controller gfx / marker
function Utils.tutorialFunctionInit( class_table, triggerName, removeSubtitle, removeMarker )
	ScriptManager:disableAllTilesExcept( 0, 0 );
	ScriptManager:removeTrigger( triggerName );
	Utils:cleanupController();
	
	if removeSubtitle then
		ScriptManager:dismissSubtitle();
	end
	
	if removeMarker then
		ScriptManager:removeAllMarkers();
	end
end

function checkTileForCaptureBlockingUnits( tileX, tileY )
	local returnValue = 0;
	local neighborUnit = Unit:getUnitAt( tileX, tileY )
	
	if neighborUnit ~= nil then
		local neighborUnitPlayerId = neighborUnit:getPlayerId()
		if neighborUnitPlayerId == 1 then
			local neighborUnitTemplateId = neighborUnit:getTemplateId()
			if neighborUnitTemplateId ~= Units.L_PLANE_BOMBER
			or neighborUnitTemplateId ~= Units.L_PLANE_HEAVY
			or neighborUnitTemplateId ~= Units.L_PLANE_LIGHT
			or neighborUnitTemplateId ~= Units.L_PLANE_SCOUT
			or neighborUnitTemplateId ~= Units.L_PLANE_TRANSPORT
			or neighborUnitTemplateId ~= Units.X_PLANE_BOMBER
			or neighborUnitTemplateId ~= Units.X_PLANE_HEAVY
			or neighborUnitTemplateId ~= Units.X_PLANE_LIGHT
			or neighborUnitTemplateId ~= Units.X_PLANE_SCOUT
			or neighborUnitTemplateId ~= Units.X_PLANE_TRANSPORT then
				returnValue = 1
			end
		end
	end
	
	return returnValue
end
-- checks if target unit can be captured ( true = capturable ) ( false = not capturable )
function Utils.checkIfBuildingIsCapturable( class_table, unitId )
	local unit = Unit:getUnitById( unitId )
	
	if unit ~= nil then
		local unitX = unit:getX()
		local unitY = unit:getY()
		
		local xx = unitY % 2 -1
		
		local tile1 = checkTileForCaptureBlockingUnits( unitX + xx,		unitY + 1 )
		local tile2 = checkTileForCaptureBlockingUnits( unitX + xx + 1, unitY + 1 )
		local tile3 = checkTileForCaptureBlockingUnits( unitX + xx,		unitY - 1)
		local tile4 = checkTileForCaptureBlockingUnits( unitX + xx + 1, unitY + 1)
		local tile5 = checkTileForCaptureBlockingUnits( unitX + 1,		unitY )
		local tile6 = checkTileForCaptureBlockingUnits( unitX - 1,		unitY )
			
		local sum = tile1 + tile2 + tile3 + tile4 + tile5 + tile6;
		
		if sum == 0 then
			return true
		
		else
			return false
		end
	
	else
		print( "error: unit is nil" )
		return false
	end
end