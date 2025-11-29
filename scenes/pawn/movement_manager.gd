extends Node
class_name PawnMovementManager


var pawn: Pawn

#region Character Export Group

@export_group("Character")
@export var base_speed : float = 10.0
@export var sprint_speed : float = base_speed * 2
@export var crouch_speed : float = 3.0
@export var acceleration : float = 10.0
@export var jump_velocity : float = 7.0
## How soon can the "no air control" debuff be cleared by touching the ground, in milliseconds
@export_range(0, 1000, 100, "or_greater") var no_air_control_recovery_time : int = 500
## Horizontal speed at which the "no air control" debuff is cleared
@export_range(0, 10, 1, "or_greater") var no_air_control_recovery_speed : float = 2.0
## Grace period (milliseconds) after leaving a platform during which a jump input still registers.
@export_range(0, 1000, 50) var coyote_time: int = 200
## Grace period (milliseconds) before landing during which a jump input still registers.
@export_range(0, 1000, 50) var jump_buffer : int = 100
## Value of 0 disables jumping, values greater than 1 allow air jumps.
@export var number_of_jumps : int = 2
## Scale factor for horizontal acceleration when the pawn is in the air.[br]
## 0.0 = no aerial control (can't change horizontal velocity in the air).[br]
## 1.0 = full control (same horizontal acceleration as on ground).
@export_range(0, 1, 0.05) var air_control : float = 0.15
## While in air, horizontal velocity will be multiplied by (1 - horizontal_damping * delta) each frame. [br]
## This is [i]not[/i] the same as linear damping used elswhere in the engine.
@export_range(0, 1, 0.05) var horizontal_damping : float = 0.1

#endregion

#region Feature Settings Export Group

@export_group("Feature Settings")
@export var sprint_enabled : bool = false
@export var crouch_enabled : bool = true
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
var _buffer_deadline : int
var _valid_states : Array[String] = ["normal", "crouching", "sprinting"]
var _no_air_control_until: int:
	set(value):
		_no_air_control_until = value
		_no_air_control_timestamp = Time.get_ticks_msec()
var _no_air_control_timestamp: int

var RETICLE : Control

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var HEAD : Node3D
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

	pawn.ready.connect(_assign_component_variables)

	$CrouchCeilingDetection.add_exception(pawn)


func _assign_component_variables():
	HEAD = pawn.Head
	animation_manager = pawn.get_node("AnimationManager")
	player_controller = pawn.player_controller


func manage_pawn_movement(delta):
	if override_gravity:
		gravity = custom_gravity
	else:
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not pawn.is_on_floor():
		pawn.velocity.y -= gravity * delta

	handle_jumping(delta)

	var moving = desired_input_dir != Vector2.ZERO
	handle_movement(delta, desired_input_dir, pawn.head_yaw)

	_handle_head_rotation()

	_low_ceiling = $CrouchCeilingDetection.is_colliding()

	handle_state(moving)

	if view_bobbing:
		animation_manager.play_headbob_animation(moving)




func handle_jumping(delta: float):
	if number_of_jumps == 0: return

	var _jmp =func ():
		pawn.pawn_jumped.emit()
		pawn.velocity.y = max(pawn.velocity.y + jump_velocity, jump_velocity)
		_jumps_remaining -= 1

	if number_of_jumps == 0:
		return

	if pawn.is_on_floor():
		if pawn._air_time_ms > 0:
			pawn.pawn_landed.emit()
		pawn._air_time_ms = 0
		_jumps_remaining = number_of_jumps
		if input_jump_just_pressed:
			_jmp.call()
		elif _buffer_deadline > Time.get_ticks_msec():
			_jmp.call()
			_buffer_deadline = 0
	else:
		if pawn._air_time_ms >= coyote_time and _jumps_remaining == number_of_jumps:
			_jumps_remaining -= 1	# remove a jump when falling off ledge
		pawn._air_time_ms += delta
		if input_jump_just_pressed: # air jump
			if _jumps_remaining > 0:
				_jmp.call()
				_handle_no_air_control(true)
			else:
				_buffer_deadline = jump_buffer + Time.get_ticks_msec()


func handle_movement(delta, input_dir: Vector2, head_y: float):
	# convert input_dir from local to world using head yaw
	var direction = input_dir.rotated(-head_y)
	direction = Vector3(direction.x, 0.0, direction.y)

	if pawn.is_on_floor():
		pawn.velocity.x = lerp(pawn.velocity.x, direction.x * _current_max_speed, acceleration * delta)
		pawn.velocity.z = lerp(pawn.velocity.z, direction.z * _current_max_speed, acceleration * delta)
	else:
		if _no_air_control_until < Time.get_ticks_msec() and direction.length() > 0:
			pawn.velocity.x = lerp(pawn.velocity.x, direction.x * base_speed, acceleration * delta * air_control)
			pawn.velocity.z = lerp(pawn.velocity.z, direction.z * base_speed, acceleration * delta * air_control)
		pawn.velocity.x *= 1 - horizontal_damping * delta
		pawn.velocity.z *= 1 - horizontal_damping * delta

	_handle_no_air_control()
	pawn.move_and_slide()


func _handle_no_air_control(clear:bool = false):
	if clear:
		_no_air_control_until = 0
	elif Vector2(pawn.velocity.x, pawn.velocity.z).length() <= no_air_control_recovery_speed:
				_no_air_control_until = 0
	elif pawn._air_time_ms > 0:
		if pawn.is_on_floor():
			if _no_air_control_timestamp < no_air_control_recovery_time + Time.get_ticks_msec():
				_no_air_control_until = 0


func _handle_head_rotation():
	if not HEAD:
		return

	HEAD.rotation_degrees.y -= look_input.x
	HEAD.rotation_degrees.x -= look_input.y

	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func disable_air_control(duration_ms: int):
	_no_air_control_until = duration_ms + Time.get_ticks_msec()


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
