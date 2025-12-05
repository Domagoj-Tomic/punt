extends Node3D
class_name PlayerController

# PlayerController: input, Camera, head rotation, UI toggles, reticle setup.


#region Controller Export Group

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
@export_file var reticle_resource: String = "res://scenes/player/player_controller/reticles/reticle_0.tscn"
@export var mouse_sensitivity : float = 0.125
@export var invert_camera_x_axis : bool = false
@export var invert_camera_y_axis : bool = false
@export var toggle_crouch : bool = false
@export var toggle_sprint : bool = false
@export var pausing_enabled : bool = true

@export_subgroup("Gamepad Specific")
@export var gamepad_controls : Dictionary = {
	LOOK_LEFT = "look_left",
	LOOK_RIGHT = "look_right",
	LOOK_UP = "look_up",
	LOOK_DOWN = "look_down"
}
@export_range(1, 10) var gamepad_look_sensitivity : float = 3

@export_category("Camera")
@export_range(60, 120) var fov: float = 75
@export var sprint_dynamic_fov: bool = true
@export_range(0, 40) var max_dynamic_fov_delta: float = 10

#endregion

var player: PlayerData
var pawn : Pawn
var movement_manager: PawnMovementManager
var debug_tool: PawnDebugTool
var Head : Node3D
var Camera : Camera3D
var Gunsocket : GunSocket
var RemoteTransform : RemoteTransform3D
var mouse_input : Vector2 = Vector2.ZERO
var joy_input : Vector2 = Vector2.ZERO
var reticle : Control
var input: DeviceInput


func _init(new_pawn: Pawn, new_player: PlayerData):
	name = "PlayerController"
	player = new_player
	pawn = new_pawn
	if pawn.player_controller:
		pawn.remove_child(pawn.player_controller)
		pawn.player_controller.queue_free()
	pawn.add_child(self)
	owner = pawn
	Head = pawn.Head
	Gunsocket = pawn.Gunsocket
	RemoteTransform = pawn.RemoteTransform
	movement_manager = pawn.movement_manager
	debug_tool = pawn.debug_tool
	if player.subviewport != null:
		Camera = player.subviewport.camera
		RemoteTransform.remote_path = RemoteTransform.get_path_to(Camera)
		change_reticle()
	process_mode = Node.PROCESS_MODE_ALWAYS
	pawn.possessed(self)
	input  = DeviceInput.new(player.device_id)


func _ready():
	if pawn.has_method("initialize_animations"):
		pawn.initialize_animations()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta):
	if pausing_enabled:
		handle_pausing()

	# update debug per-frame info on the pawn's UI
	if pawn:
		var fps = Performance.get_monitor(Performance.TIME_FPS)
		var status = movement_manager._state
		if not pawn.is_on_floor():
			status += " in the air"
		if debug_tool.has_method("update_debug_menu_per_frame_from_controller"):
			debug_tool.update_debug_menu_per_frame_from_controller(fps, status)



func _physics_process(_delta):
	if not pawn or !pawn.input_enabled or not movement_manager:
		return

	# gather inputs and forward to pawn
	var input_dir = Vector2.ZERO
	input_dir = input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)

	movement_manager.desired_input_dir = input_dir
	movement_manager.input_jump_pressed = input.is_action_pressed(controls.JUMP)
	movement_manager.input_jump_just_pressed = input.is_action_just_pressed(controls.JUMP)

	if toggle_crouch:
		if input.is_action_just_pressed(controls.CROUCH):
			movement_manager.input_crouch_pressed = !movement_manager.input_crouch_pressed
	else:
		movement_manager.input_crouch_pressed = input.is_action_pressed(controls.CROUCH)

	if toggle_sprint:
		if input.is_action_just_pressed(controls.SPRINT):
			movement_manager.input_sprint_pressed = !movement_manager.input_sprint_pressed
	else:
		movement_manager.input_sprint_pressed = input.is_action_pressed(controls.SPRINT)

	# weapons
	Gunsocket.input_fire_pressed = input.is_action_pressed("fire")
	if input.is_action_just_pressed("select_weapon_1"):
		Gunsocket.equip_weapon_by_index(0)
	if input.is_action_just_pressed("select_weapon_2"):
		Gunsocket.equip_weapon_by_index(1)
	if input.is_action_just_pressed("select_weapon_3"):
		Gunsocket.equip_weapon_by_index(2)

	# update pawn with head yaw for movement transform
	pawn.head_yaw = Head.rotation.y

	if sprint_dynamic_fov and movement_manager._state == "sprinting":
		Camera.fov = lerp(Camera.fov, fov + max_dynamic_fov_delta, 0.05)
	else:
		Camera.fov = lerp(Camera.fov, fov, 0.05)

	# controller
	var controller_input: Vector2 = input.get_vector(gamepad_controls.LOOK_LEFT, gamepad_controls.LOOK_RIGHT, gamepad_controls.LOOK_UP, gamepad_controls.LOOK_DOWN)
	controller_input *= gamepad_look_sensitivity
	if invert_camera_x_axis:
		controller_input.x *= -1
	if invert_camera_y_axis:
		controller_input.y *= -1

	# apply look input then reset input delta
	movement_manager.look_input = mouse_input
	movement_manager.look_input += controller_input
	mouse_input = Vector2(0,0)


func _unhandled_input(event : InputEvent):
	if player.device_id == -1:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_input.x = event.relative.x * mouse_sensitivity
			mouse_input.y = event.relative.y * mouse_sensitivity
			if invert_camera_x_axis:
				mouse_input.x *= -1
			if invert_camera_y_axis:
				mouse_input.y *= -1
	if event is InputEventKey:
		if event.is_released():
			# Toggle debug menu on F7
			if event.keycode == 4194338: # F7
				pawn.debug_tool.debug_panel.visible = !pawn.debug_tool.debug_panel.visible


func handle_pausing():
	if input.is_action_just_pressed(controls.PAUSE):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func change_reticle():
	if reticle_resource:
		reticle = load(reticle_resource).instantiate()
		reticle.character = pawn
		Camera.add_child(reticle)
