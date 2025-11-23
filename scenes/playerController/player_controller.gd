extends Node3D
class_name PlayerController

# PlayerController: input, camera, head rotation, UI toggles, reticle setup.

#region Controller Export Group

@export_group("Controller")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var GUNSOCKET : GunSocket

@export_group("Controls")
@export var controls : Dictionary = {
	LEFT = "move_left",
	RIGHT = "move_right",
	FORWARD = "move_forward",
	BACKWARD = "move_backward",
	JUMP = "jump",
	CROUCH = "crouch",
	SPRINT = "sprint",
	PAUSE = "menu",
	WEAPON1 = "select_weapon_1",
	WEAPON2 = "select_weapon_2",
	WEAPON3 = "select_weapon_3",
	FIRE = "fire"
}

@export_file var default_reticle

@export var mouse_sensitivity : float = 0.1
@export var invert_camera_x_axis : bool = false
@export var invert_camera_y_axis : bool = false

@export var pausing_enabled : bool = true

@export_subgroup("Controller Specific")
@export var controller_support : bool = false
@export var controller_controls : Dictionary = {
	LOOK_LEFT = "look_left",
	LOOK_RIGHT = "look_right",
	LOOK_UP = "look_up",
	LOOK_DOWN = "look_down"
}
@export_range(0.001, 1, 0.001) var look_sensitivity : float = 0.035

#endregion

# Local
var mouseInput : Vector2 = Vector2.ZERO
var pawn : Pawn = null

func _ready():
	# expects the controller to be a direct child of the Pawn node
	pawn = get_parent()
	if not pawn:
		push_error("PlayerController expects to be child of Pawn (CharacterBody3D).")
		return

	owner = pawn

	if CAMERA:
		pawn.CAMERA = CAMERA

	# move head rotation from pawn to HEAD if pawn had rotation set
	if HEAD:
		HEAD.rotation.y = pawn.rotation.y
		pawn.rotation.y = 0.0

	if GUNSOCKET:
		pawn.GUNSOCKET = GUNSOCKET

	# set the default reticle via pawn API
	if default_reticle:
		if pawn.has_method("change_reticle"):
			pawn.change_reticle(default_reticle)

	# initialize pawn animations, etc.
	if pawn.has_method("initialize_animations"):
		pawn.initialize_animations()

	check_controls()

	# if running in web, avoid accumulated input
	if OS.get_name() == "Web":
		Input.set_use_accumulated_input(false)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta):
	if pausing_enabled:
		handle_pausing()

	# update debug per-frame info on the pawn's UI
	if pawn:
		var fps = Performance.get_monitor(Performance.TIME_FPS)
		var status = pawn.state
		if not pawn.is_on_floor():
			status += " in the air"
		if pawn.has_method("update_debug_menu_per_frame_from_controller"):
			pawn.update_debug_menu_per_frame_from_controller(fps, status)


func _physics_process(_delta):
	if not pawn:
		return

	# gather inputs and forward to pawn
	var input_dir = Vector2.ZERO
	if not pawn.immobile:
		input_dir = Input.get_vector(controls.BACKWARD, controls.FORWARD, controls.LEFT, controls.RIGHT)

	# forward basic flags to pawn
	pawn.desired_input_dir = input_dir
	pawn.input_jump_pressed = Input.is_action_pressed(controls.JUMP)
	pawn.input_jump_just_pressed = Input.is_action_just_pressed(controls.JUMP)
	pawn.input_sprint_pressed = Input.is_action_pressed(controls.SPRINT)
	pawn.input_crouch_pressed = Input.is_action_pressed(controls.CROUCH)

	if GUNSOCKET:
		GUNSOCKET.input_fire_pressed = Input.is_action_pressed("fire")

	# update pawn with head yaw for movement transform
	if HEAD:
		pawn.head_yaw = HEAD.rotation.y

	# after forwarding inputs, handle head rotation locally (mouse/controller)
	handle_head_rotation()


func handle_head_rotation():

	if not HEAD:
		return

	# mouse-based rotation using mouseInput set in _unhandled_input
	if invert_camera_x_axis:
		HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity

	if invert_camera_y_axis:
		HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity

	# controller-sticks
	if controller_support:
		var controller_view_rotation = Input.get_vector(controller_controls.LOOK_DOWN, controller_controls.LOOK_UP, controller_controls.LOOK_RIGHT, controller_controls.LOOK_LEFT) * look_sensitivity
		if invert_camera_y_axis:
			HEAD.rotation.x += controller_view_rotation.x * -1
		else:
			HEAD.rotation.x += controller_view_rotation.x

		if invert_camera_x_axis:
			HEAD.rotation.y += controller_view_rotation.y * -1
		else:
			HEAD.rotation.y += controller_view_rotation.y

	# reset mouse delta after applying it
	mouseInput = Vector2(0,0)

	# clamp vertical rotation
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# update pawn head yaw for movement calculations (already done each physics tick, but ensure sync)
	if pawn:
		pawn.head_yaw = HEAD.rotation.y


func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput = event.relative
	elif event is InputEventKey:
		if event.is_released():
			# Toggle debug menu on F7
			if event.keycode == 4194338: # F7
				if pawn.has_node("UserInterface/DebugPanel"):
					pawn.get_node("UserInterface/DebugPanel").visible = !pawn.get_node("UserInterface/DebugPanel").visible


func handle_pausing():
	if Input.is_action_just_pressed(controls.PAUSE):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func check_controls():
	if !InputMap.has_action(controls.JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		if pawn:
			pawn.jumping_enabled = false
	if !InputMap.has_action(controls.LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		if pawn:
			pawn.immobile = true
	if !InputMap.has_action(controls.RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		if pawn:
			pawn.immobile = true
	if !InputMap.has_action(controls.FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		if pawn:
			pawn.immobile = true
	if !InputMap.has_action(controls.BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		if pawn:
			pawn.immobile = true
	if !InputMap.has_action(controls.PAUSE):
		push_error("No control mapped for pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(controls.CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		if pawn:
			pawn.crouch_enabled = false
	if !InputMap.has_action(controls.SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		if pawn:
			pawn.sprint_enabled = false


func set_head(head : Node3D):
	HEAD = head
	CAMERA = head.get_node("Camera")
	GUNSOCKET = head.get_node("GunSocket")
