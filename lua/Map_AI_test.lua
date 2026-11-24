require "lua/Constants"
require "lua/Utils"
require "lua/Text"
require "lua/Units"
require "math"


function onGameStart()
	--ScriptManager:addOnTurnStartTrigger(1,1,-1,"test", "test");
	
	-- squadId tileX tileY unitId targetRadius type 
	--local orderId = ScriptManager:addOrder(0, -1, -1, 1, 2, AiOrder.ATTACK );
	--ScriptManager:disableComponent(0,ComponentType.MOVEMENT,0);
        ScriptManager:addOrder(1, 12,19,-1, 1, AiOrder.MOVE);
end

function test()
	--ScriptManager:transformUnit( 0, 6, 37, 0, true );
	--local rubberboat = Unit:getUnitAt( 6, 37 ):getId();
	--Utils:moveTransporterAndUnloadIt( rubberboat, 0, 6, 37, 7, 37 );
	--ScriptManager:attackUnitEx(0,1,false);
	--local orderId = ScriptManager:addOrder( 0, -1, -1, 1, 2, AiOrder.ATTACK ); -- attack HQ
	--ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_KILL_ALL_AT_WAY );
	--ScriptManager:enableOrderFlag( orderId, AiOrderFlag.FLAG_SEARCH_AREA_AFTER_ATTACK );
end

-- END Defeated