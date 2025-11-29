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
@export_file var reticle_resource: String = "res://scenes/player_controller/reticles/reticle_0.tscn"
@export var mouse_sensitivity : float = 0.125
@export var invert_camera_x_axis : bool = false
@export var invert_camera_y_axis : bool = false
@export var toggle_crouch : bool = false
@export var toggle_sprint : bool = false
@export var pausing_enabled : bool = true

@export_subgroup("Gamepad Specific")
@export var gamepad_support : bool = false
@export var gamepad_controls : Dictionary = {
	LOOK_LEFT = "look_left",
	LOOK_RIGHT = "look_right",
	LOOK_UP = "look_up",
	LOOK_DOWN = "look_down"
}
@export_range(0.001, 1, 0.001) var look_sensitivity : float = 0.035

@export_category("Camera")
@export_range(60, 120) var fov: float = 75
@export var sprint_dynamic_fov: bool = true
@export_range(0, 40) var max_dynamic_fov_delta: float = 10

#endregion


var pawn : Pawn
var movement_manager: PawnMovementManager
var debug_tool: PawnDebugTool
var Head : Node3D
var Camera : Camera3D
var Gunsocket : GunSocket
var RemoteTransform : RemoteTransform3D
var mouse_input : Vector2 = Vector2.ZERO
var reticle : Control
var split_screen_viewport: SplitScreenViewport = ViewportManager.request_viewport()


func _init(new_pawn: Pawn):
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
	if split_screen_viewport != null:
		Camera = split_screen_viewport.camera
		RemoteTransform.remote_path = RemoteTransform.get_path_to(Camera)
	else:
		Camera = Head.get_node("Camera")
	process_mode = Node.PROCESS_MODE_ALWAYS
	pawn.possessed(self)


func _ready():
	if reticle_resource:
		change_reticle(reticle_resource)

	# initialize pawn animations, etc.
	if pawn.has_method("initialize_animations"):
		pawn.initialize_animations()

	# if running in web, avoid accumulated input
	if OS.get_name() == "Web":
		Input.set_use_accumulated_input(false)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	pawn.possessed(self)


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

	#_update_subviewport_camera_position()



func _physics_process(_delta):

	if not pawn or !pawn.input_enabled or not movement_manager:
		return

	# gather inputs and forward to pawn
	var input_dir = Vector2.ZERO
	input_dir = Input.get_vector(controls.BACKWARD, controls.FORWARD, controls.LEFT, controls.RIGHT)

	# forward basic flags to pawn
	if movement_manager:
		movement_manager.desired_input_dir = input_dir
		movement_manager.input_jump_pressed = Input.is_action_pressed(controls.JUMP)
		movement_manager.input_jump_just_pressed = Input.is_action_just_pressed(controls.JUMP)

	if toggle_crouch:
		if Input.is_action_just_pressed(controls.CROUCH):
			movement_manager.input_crouch_pressed = !movement_manager.input_crouch_pressed
	else:
		movement_manager.input_crouch_pressed = Input.is_action_pressed(controls.CROUCH)

	if toggle_sprint:
		if Input.is_action_just_pressed(controls.SPRINT):
			movement_manager.input_sprint_pressed = !movement_manager.input_sprint_pressed
	else:
		movement_manager.input_sprint_pressed = Input.is_action_pressed(controls.SPRINT)

	Gunsocket.input_fire_pressed = Input.is_action_pressed("fire")

	# update pawn with head yaw for movement transform
	if Head:
		pawn.head_yaw = Head.rotation.y

	movement_manager.look_input = mouse_input
	# reset mouse delta after applying it
	mouse_input = Vector2(0,0)

	# controller
	if gamepad_support:
		var controller_input = Input.get_vector(gamepad_controls.LOOK_DOWN, gamepad_controls.LOOK_UP, gamepad_controls.LOOK_RIGHT, gamepad_controls.LOOK_LEFT) * look_sensitivity

		if invert_camera_x_axis:
			controller_input.x *= -1
		if invert_camera_y_axis:
			controller_input.y *= -1

		movement_manager.look_input = controller_input

	if sprint_dynamic_fov and movement_manager._state == "sprinting":
		Camera.fov = lerp(Camera.fov, fov + max_dynamic_fov_delta, 0.05)
	else:
		Camera.fov = lerp(Camera.fov, fov, 0.05)


func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input.x = event.relative.x * mouse_sensitivity
		mouse_input.y = event.relative.y * mouse_sensitivity
		if invert_camera_x_axis:
			mouse_input.x *= -1
		if invert_camera_y_axis:
			mouse_input.y *= -1
	elif event is InputEventKey:
		if event.is_released():
			# Toggle debug menu on F7
			if event.keycode == 4194338: # F7
				if pawn.has_node("UserInterface/DebugPanel"):
					pawn.get_node("UserInterface/DebugPanel").visible = !pawn.get_node("UserInterface/DebugPanel").visible


func handle_pausing():
	if Input.is_action_just_pressed(controls.PAUSE):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func change_reticle(new_reticle_path: String = ""):
	reticle = load(new_reticle_path).instantiate()
	reticle.character = pawn
	if pawn.has_node("UserInterface"):
		pawn.get_node("UserInterface").add_child(reticle)
