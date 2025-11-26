extends CharacterBody3D
class_name Pawn

# Pawn: movement, physics, state, animations


signal pawn_jumped
signal pawn_landed
signal pawn_changed_state(old_state: String)

#region Character Export Group

@export var input_enabled : bool = true
@export var mass : float = 100
@export var impulse_scale: float = 1.0
@export var physics_material: PhysicsMaterial

#endregion

#region Member Variable Initialization

var _air_time: float = 0

@onready var Head : Node3D = $Head
@onready var Camera : Camera3D = $Head/Camera
@onready var Gunsocket : GunSocket = $Head/GunSocket

# The yaw of the head (radians) provided by PlayerController
var head_yaw : float = 0.0

var movement_manager: PawnMovementManager
var health_manager: PawnHealthManager
var animation_manager: PawnAnimationManager
var debug_tool: PawnDebugTool

#endregion


func _ready():
	call_deferred("initialise_pawn")
	movement_manager = $MovementManager
	health_manager = $HealthManager
	animation_manager = $AnimationManager
	debug_tool = $DebugTool


func _physics_process(delta):
	if input_enabled:
		movement_manager.manage_pawn_movement(delta)
	health_manager.manage_pawn_health(delta)
	debug_tool.update_debug_menu_per_tick()


func initialise_pawn():
	check_nodes()
	movement_manager.enter_state("normal")


func check_nodes():
	if not $MovementManager/CrouchCeilingDetection:
		push_error("Pawn requires a child node named 'CrouchCeilingDetection' for ceiling checks.")
	if not $MovementManager:
		push_error("MovementManager missing.")
	if not $HealthManager:
		push_error("HealthManager missing.")
	if not $AnimationManager:
		push_error("AnimationManager missing.")
	if not $DebugTool:
		push_error("DebugTool missing.")
