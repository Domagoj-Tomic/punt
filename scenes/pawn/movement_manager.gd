extends Node
class_name PawnMovementManager


var pawn: Pawn

#region Character Export Group

@export_group("Character")
@export var base_speed : float = 10.0
@export var sprint_speed : float = base_speed * 2
@export var crouch_speed : float = 3.0
@export var acceleration : float = 10.0
@export var jump_velocity : float = 7
@export_range(0, 10, 1, "or_greater") var extra_jumps : int = 1

#endregion

#region Feature Settings Export Group

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export_range(0, 1, 0.1, "or_greater") var air_control : float = 1
@export var sprint_enabled : bool = false
@export var crouch_enabled : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
## If true, custom gravity will be applied. Othervise, project default will be used.
@export var override_gravity : bool = true
## Only works if override_gravity = true
@export var custom_gravity : float = 15

#endregion

#region Member Variable Initialization

# movement state
var _current_max_speed : float = base_speed
var _state : String = "normal"
var _low_ceiling : bool = false
var _jumps_remaining : int
var _valid_states : Array[String] = ["normal", "crouching", "sprinting"]

var RETICLE : Control

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var HEAD : Node3D
var CAMERA : Camera3D
var animation_manager : PawnAnimationManager
var player_controller: PlayerController

# Input-forwarded state (set every frame by PlayerController)
var desired_input_dir : Vector2 = Vector2.ZERO
var input_jump_pressed : bool = false
var input_jump_just_pressed : bool = false
var input_sprint_pressed : bool = false
var input_crouch_pressed : bool = false
var look_input : Vector2

# The yaw of the head (radians) provided by PlayerController
var head_yaw : float = 0.0

#endregion


func _ready() -> void:
	if self.get_parent() is Pawn:
		pawn = get_parent()
	else:
		push_error("Direct parent must be a Pawn")

	HEAD = pawn.get_node("Head")
	CAMERA = pawn.get_node("Head/Camera")
	animation_manager = pawn.get_node("AnimationManager")
	if pawn.has_node("PlayerController"):
		player_controller = pawn.get_node("PlayerController")

	$CrouchCeilingDetection.add_exception(pawn)


func manage_pawn_movement(delta):
	if override_gravity:
		gravity = custom_gravity
	else:
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not pawn.is_on_floor():
		pawn.velocity.y -= gravity * delta

	handle_jumping()

	var moving = desired_input_dir != Vector2.ZERO
	handle_movement(delta, desired_input_dir, pawn.head_yaw)

	handle_head_rotation()

	_low_ceiling = $CrouchCeilingDetection.is_colliding()

	handle_state(moving)

	if view_bobbing:
		animation_manager.play_headbob_animation(moving)

	if pawn.is_on_floor():
		if pawn.air_time > 0:
			pawn.pawn_landed.emit()
		pawn.air_time = 0
	else:
		pawn.air_time += delta


func handle_jumping():
	if pawn.is_on_floor():
		_jumps_remaining = extra_jumps + 1

	if not jumping_enabled:
		return

	if continuous_jumping and pawn.is_on_floor():
		if input_jump_pressed and _jumps_remaining > 0 and not _low_ceiling:
			pawn.pawn_jumped.emit()
			pawn.velocity.y = max(pawn.velocity.y + jump_velocity, jump_velocity)
			_jumps_remaining -= 1
	else:
		if input_jump_just_pressed and _jumps_remaining > 0 and not _low_ceiling:
			pawn.pawn_jumped.emit()
			pawn.velocity.y = max(pawn.velocity.y + jump_velocity, jump_velocity)
			_jumps_remaining -= 1


func handle_movement(delta, input_dir: Vector2, head_y: float):
	# convert input_dir from local to world using head yaw
	var direction = input_dir.rotated(-head_y)
	direction = Vector3(direction.x, 0.0, direction.y)

	if pawn.is_on_floor():
		pawn.velocity.x = lerp(pawn.velocity.x, direction.x * _current_max_speed, acceleration * delta)
		pawn.velocity.z = lerp(pawn.velocity.z, direction.z * _current_max_speed, acceleration * delta)
	else:
		pawn.velocity.x = lerp(pawn.velocity.x, direction.x * base_speed, acceleration * delta * air_control)
		pawn.velocity.z = lerp(pawn.velocity.z, direction.z * base_speed, acceleration * delta * air_control)

	pawn.move_and_slide()


func handle_head_rotation():
	if not HEAD:
		return

	HEAD.rotation_degrees.y -= look_input.x
	HEAD.rotation_degrees.x -= look_input.y

	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))


#region State Handling

func handle_state(moving):
	if sprint_enabled:
		if input_sprint_pressed:
			if moving and not _low_ceiling:
				enter_state("sprinting")
			else:
				enter_state("normal")
		elif _state != "crouching":
			enter_state("normal")

	if crouch_enabled:
		if input_crouch_pressed:
			if _state != "sprinting":
				enter_state("crouching")
		else:
			if _state != "sprinting" and not _low_ceiling:
				enter_state("normal")


func enter_state(new_state):
	if not _valid_states.has(new_state):
		push_error("Invalid state.")
	if new_state != _state:
		pawn.pawn_changed_state.emit(_state, new_state)
		_state = new_state
		match new_state:
			"normal":		_current_max_speed = base_speed
			"crouching":	_current_max_speed = crouch_speed
			"sprinting":	_current_max_speed = sprint_speed

#endregion
