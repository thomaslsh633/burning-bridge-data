ComponentType = {
	ROTATION		=  0,
	MOVEMENT		=  1,
	ATTACK_HANDLER	=  2,
	ATTACK			=  3,
	DEALER			=  4,
	CAPTURE			=  5,
	SUPPLY			=  6,
	SUPPLIER		=  7,
	SUPPLYABLE		=  8,
	FORTIFY			=  9,
	CAMOUFLAGE		= 10,
	MINE_LAYER		= 11,
	DISARM_MINE		= 12,
	DETECT_MINE		= 13,
	BUILDER			= 14,
	HUD				= 15,
	BRIDGE_HANDLER	= 16,
	TRANSFORM		= 17,
	SELFDESTROY		= 18,
}
AiState = {
	WAIT				= 0,
	ATTACK				= 1,
	DEFEND				= 2,
	RETREAT				= 3,
	SCOUTING			= 4,
	AIRPLANE			= 5,
	ATTACK_AGGRESSIVE	= 6,
	PASSIVE				= 7,
	MOVE				= 8,
	MOVE_AGGRESSIVE		= 9,
}

AiOrder = {
	ATTACK				= 0,
	DEFEND				= 1,
	MOVE				= 2,
}

AiOrderFlag = {
  FLAG_HOLD_FIRE				=  0,
  FLAG_RUN_SILENT				=  1,
  FLAG_SEARCH_BETTER_POSITION	=  2,
  FLAG_AVOID_ENEMY				=  3,
  FLAG_STACK_TOGETHER			=  4, -- stay together when moving
  FLAG_IS_IMPORTANT				=  5, -- if enabled, request backup, if not, request retreat
  FLAG_SNEAK_ATTACK				=  6,
  FLAG_KILL_ALL_AT_WAY			=  7, -- attack all the enemies on the way to target pos / id
  FLAG_ATTACK_ALL_IN_RANGE		=  8, -- dont follow enemy if retreat, only attack what they can from their position
  FLAG_MOVE_TO_COAST_AND_UNLOAD	=  9,
  FLAG_SEARCH_AREA_AFTER_ATTACK	= 10,
  FLAG_CAPTURE					= 11,
  FLAG_ONLY_ATTACK_IN_AREA		= 12,
  FLAG_CONTINUE_TO_ATTACK		= 13,
  FLAG_UNLOAD_AFTER_MOVEMENT	= 14,
  FLAG_DONT_MOVE                = 15,
}

InteractionButton = {
	NONE					=   -1,
	SUPPLY					=    0, -- to disable a Supply button add the index of the component (SUPPLY + 1 for the SECOND Component MAX 10 Components)
	FORTIFY					=   11,
	CAMOUFLAGE				=   12,
	TRANSPORT				=   13,
	ATTACK					=   14,
	ROTATE					=   15,
	INSTANT_SUPPLY_SINGLE	=   16,
	INSTANT_SUPPLY_FULL		=   17,
	SONAR					=   18,
	RUN_SILENT				=   19,
	LAY_MINES				=   20,
	DETECT_MINES			=   21,
	DISARM_MINE				=   22,
	REPAIR_BRIDGE			=   23,
	DETONATE_BRIDGE			=   24,
	SELFDESTROY				=   25,
	SMOKEMORTAR				=   26,
	TRANSPORT_UNLOAD_1		=   27,
	TRANSPORT_UNLOAD_2		=   28,
	TRANSPORT_UNLOAD_3		=   29,
	TRANSPORT_UNLOAD_4		=   30,
	TRANSPORT_UNLOAD_5		=   31,
	CARRIER_SUPPLY			=   50,
	CARRIER_UNLOAD			=   51,
	FOLDING_INFANTRY		=  123,
	FOLDING_TANKS			=  124,
	FOLDING_AIR				=  125,
	FOLDING_SEA				=  126,
	CARRIER_SUPPLY_1		=  567,
	CARRIER_SUPPLY_2		=  568,
	CARRIER_SUPPLY_3		=  579,
	CARRIER_SUPPLY_4		=  570,
	CARRIER_SUPPLY_5		=  571,
	SELECTION_WHEEL_AIR		=  600,
	SELECTION_WHEEL_GROUND	=  601,
	SELECTION_WHEEL_SUB		=  602,
	REINFORCEMENT			= 1000, -- to disable a Reinforcement button add the template id of the specific unit (REINFORCEMENT + templateId)
	BUILDER					= 2000, -- for mg nest building ( and other units the engineer might be able to build )
	TRANSFORM				= 3000, -- to disable a Transform button add the index of the component (TRANSFORM + 1 for the SECOND Component)
}

MissionStatus = {
	NOT_STARTED		= 0,
	IN_PROGRESS		= 1,
	FAILED			= 2,
	ACCOMPLISHED	= 3,
} 

FaceDirection = {
	SOUTHEAST	= 0,
	EAST		= 1,
	NORTHEAST	= 2,
	NORTHWEST	= 3,
	WEST		= 4,
	SOUTHWEST	= 5,
};

ControllerButton = {
	DPAD_UP		=  1,
	DPAD_DOWN	=  2,
	DPAD_LEFT	=  3,
	DPAD_RIGHT	=  4,
	FACE_UP		=  5,
	FACE_DOWN	=  6,
	FACE_LEFT	=  7,
	FACE_RIGHT	=  8,
	SHOULDER_L1	=  9,
	SHOULDER_R1	= 10,
	THUMB_LEFT	= 11,
	THUMB_RIGHT	= 12,
	SELECT		= 13,
	START		= 14,
	MODE		= 15,
}

GlobalAbility = {
	MENU				= 101,
	AIRSTRIKE			= 400017114,
	AIRSTRIKE_TUT		= 407835912,
	PARATROOPER			= 82221529,
	PARATROOPER_NO_ENGI	= 597123728,
	SUPPLY_CRATE		= 723629854,
	BLIMB				= 183051582,
	RADAR				= 1390634067,
}

FactionId = {
	AXIS	= 761145918,
	ALLIES	= 1695956604,
}

OrderErrorCodes = {
	CAN_NOT_MOVE			= 0,
	PATH_EMPTY				= 1,
	NO_PATH_FOUND			= 2,
	NOT_IN_TARGET_AREA		= 3,
	NO_TARGET_AVAILABLE		= 4,
	NO_NEW_POS_CALCULATED	= 5,
	CAN_NOT_UNLOAD			= 6,
}