extends CharacterBody3D
class_name Pawn

# Pawn: movement, physics, state, animations
# TODO: fix (un)crouch while moving

#region Character Export Group

@export_group("Character")
@export var base_speed : float = 10.0
@export var sprint_speed : float = 20.0
@export var crouch_speed : float = 3.0
@export var acceleration : float = 10.0
@export var jump_velocity : float = 6
@export_range(0, 10, 1, "or_greater") var extra_jumps : int = 1

# These input-related settings are preserved for server-side or AI use but input reading is done by PlayerController.
@export var immobile : bool = false

#endregion

#region Nodes Export Group

@export_group("Nodes")
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D

# keep the CrouchCeilingDetection node as it is referenced in state logic
# expect a child node named "CrouchCeilingDetection" in the Pawn scene

#endregion

#region Feature Settings Export Group

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = false
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
@export var jump_animation : bool = true
@export var pausing_enabled : bool = true
@export var gravity_enabled : bool = true
@export var dynamic_gravity : bool = false

#endregion

#region Member Variable Initialization

# movement state
var speed : float = base_speed
var current_speed : float = 0.0
var state : String = "normal"
var low_ceiling : bool = false
var was_on_floor : bool = true
var jumps_remaining : int

var RETICLE : Control

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var HEAD : Node3D = $Head
@onready var CAMERA : Camera3D = $Head/Camera
@onready var GUNSOCKET : GunSocket = $Head/GunSocket

# Input-forwarded state (set every frame by PlayerController)
var desired_input_dir : Vector2 = Vector2.ZERO
var input_jump_pressed : bool = false
var input_jump_just_pressed : bool = false
var input_sprint_pressed : bool = false
var input_crouch_pressed : bool = false

# The yaw of the head (radians) provided by PlayerController
var head_yaw : float = 0.0

#endregion


func _ready():
	call_deferred("initialise_pawn")


func _physics_process(delta):
	if dynamic_gravity:
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor() and gravity and gravity_enabled:
		velocity.y -= gravity * delta

	handle_jumping()

	# movement uses forwarded input and head_yaw
	var moving = desired_input_dir != Vector2.ZERO
	handle_movement(delta, desired_input_dir, head_yaw)

	# update head yaw dependent state (ceiling detection)
	low_ceiling = $CrouchCeilingDetection.is_colliding()

	handle_state(moving)

	if dynamic_fov and CAMERA:
		update_camera_fov()

	if view_bobbing:
		play_headbob_animation(moving)

	if jump_animation:
		play_jump_animation()

	# debug values
	update_debug_menu_per_tick()

	was_on_floor = is_on_floor()


func initialise_pawn():
	initialize_animations()
	check_nodes()
	enter_normal_state()
	if not find_children("", "PlayerController").is_empty():
		find_children("", "PlayerController")[0].set_head(HEAD)


func check_nodes():
	if not $CrouchCeilingDetection:
		push_error("Pawn requires a child node named 'CrouchCeilingDetection' for ceiling checks.")


#region Movement & Jumping

func handle_jumping():
	if is_on_floor():
		jumps_remaining = extra_jumps + 1

	if not jumping_enabled:
		return

	if continuous_jumping and is_on_floor():
		if input_jump_pressed and jumps_remaining > 0 and not low_ceiling:
			if jump_animation:
				JUMP_ANIMATION.play("jump", 0.25)
			velocity.y += jump_velocity
			jumps_remaining -= 1
	else:
		if input_jump_just_pressed and jumps_remaining > 0 and not low_ceiling:
			if jump_animation:
				JUMP_ANIMATION.play("jump", 0.25)
			velocity.y += jump_velocity
			jumps_remaining -= 1


func handle_movement(delta, input_dir: Vector2, head_y: float):
	# convert input_dir from local to world using head yaw
	var direction = input_dir.rotated(-head_y)
	direction = Vector3(direction.x, 0.0, direction.y)

	if !in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

	# call move_and_slide here to actually apply the velocity.
	move_and_slide()


#endregion


#region State Handling

func handle_state(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if input_sprint_pressed and state != "crouching":
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				if input_sprint_pressed and state == "normal":
					enter_sprint_state()
				if input_sprint_pressed:
					pass
			elif state == "sprinting":
				enter_normal_state()

	if crouch_enabled:
		# Controller handles toggle/hold semantics
		if crouch_mode == 0:
			if input_crouch_pressed and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		elif crouch_mode == 1:
			# Controller should forward the "just pressed" behavior; here we treat input_crouch_pressed as a toggle signal set when the button was just pressed
			# Simple implementation: toggle if input_crouch_pressed is true
			if input_crouch_pressed:
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()


func enter_normal_state():
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed

#endregion


#region Animations

func initialize_animations():
	if HEADBOB_ANIMATION:
		HEADBOB_ANIMATION.play("RESET")
	if JUMP_ANIMATION:
		JUMP_ANIMATION.play("RESET")
	if CROUCH_ANIMATION:
		CROUCH_ANIMATION.play("RESET")

func play_headbob_animation(moving):
	if not HEADBOB_ANIMATION:
		return

	if moving and is_on_floor():
		var use_headbob_animation : String = "walk"
		match state:
			"normal","crouching":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"

		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true

		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2))
	else:
		if HEADBOB_ANIMATION.current_animation == "sprint" or HEADBOB_ANIMATION.current_animation == "walk":
			HEADBOB_ANIMATION.speed_scale = 1
			HEADBOB_ANIMATION.play("RESET", 1)

func play_jump_animation():
	if !was_on_floor and is_on_floor():
		if CAMERA:
			var facing_direction : Vector3 = CAMERA.get_global_transform().basis.x
			var facing_direction_2D : Vector2 = Vector2(facing_direction.x, facing_direction.z).normalized()
			var velocity_2D : Vector2 = Vector2(velocity.x, velocity.z).normalized()
			var side_landed : int = round(velocity_2D.dot(facing_direction_2D))

			if side_landed > 0:
				JUMP_ANIMATION.play("land_right", 0.25)
			elif side_landed < 0:
				JUMP_ANIMATION.play("land_left", 0.25)
			else:
				JUMP_ANIMATION.play("land_center", 0.25)


#endregion


#region Reticle & Camera Helpers

func change_reticle(reticle):
	if RETICLE:
		RETICLE.queue_free()
	if reticle:
		RETICLE = load(reticle).instantiate()
		RETICLE.character = self
		if has_node("UserInterface"):
			$UserInterface.add_child(RETICLE)

func update_camera_fov():
	if not CAMERA:
		return
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)

func get_pawn_velocity() -> Vector3:
	return velocity

#endregion


#region Debug
func update_debug_menu_per_tick():
	current_speed = Vector3.ZERO.distance_to(get_pawn_velocity())
	if has_node("UserInterface/DebugPanel"):
		$UserInterface/DebugPanel.add_property("Speed", snappedf(current_speed, 0.001), 1)
		$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
		var cv : Vector3 = get_pawn_velocity()
		var vd : Array[float] = [
			snappedf(cv.x, 0.001),
			snappedf(cv.y, 0.001),
			snappedf(cv.z, 0.001)
		]
		var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
		$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)

func update_debug_menu_per_frame_from_controller(fps, status):
	# Called by Controller to feed per-frame values (controller has Input)
	if has_node("UserInterface/DebugPanel"):
		$UserInterface/DebugPanel.add_property("FPS", fps, 0)
		$UserInterface/DebugPanel.add_property("State", status, 4)

#endregion
