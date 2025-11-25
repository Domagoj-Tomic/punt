extends Node
class_name PawnAnimationManager


@export_group("Nodes")
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer

@export_group("Feature Settings")
@export var jump_animation : bool = true

var pawn: Pawn
var Camera: Camera3D
var movement_manager: PawnMovementManager


func _ready() -> void:
	if self.get_parent() is Pawn:
			pawn = get_parent()
	else:
		push_error("Direct parent must be a Pawn")

	if HEADBOB_ANIMATION:
		HEADBOB_ANIMATION.play("RESET")
	if JUMP_ANIMATION:
		JUMP_ANIMATION.play("RESET")
	if CROUCH_ANIMATION:
		CROUCH_ANIMATION.play("RESET")

	Camera = pawn.get_node("Head/Camera")
	movement_manager = pawn.get_node("MovementManager")

	pawn.pawn_jumped.connect(_play_jump_animation)
	pawn.pawn_landed.connect(_play_landing_animation)
	pawn.pawn_changed_state.connect(_animate_change_in_state)


func _animate_change_in_state(old_state: String, new_state: String):
	if new_state == "crouching":
		CROUCH_ANIMATION.play("crouch")
	if old_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")


func _play_landing_animation():
	if pawn.Camera:
		var facing_direction : Vector3 = Camera.get_global_transform().basis.x
		var facing_direction_2D : Vector2 = Vector2(facing_direction.x, facing_direction.z).normalized()
		var velocity_2D : Vector2 = Vector2(pawn.velocity.x, pawn.velocity.z).normalized()
		var side_landed : int = round(velocity_2D.dot(facing_direction_2D))

		if side_landed > 0:
			JUMP_ANIMATION.play("land_right", 0.25)
		elif side_landed < 0:
			JUMP_ANIMATION.play("land_left", 0.25)
		else:
			JUMP_ANIMATION.play("land_center", 0.25)


func _play_jump_animation():
	JUMP_ANIMATION.play("jump", 0.25)


func play_headbob_animation(moving):
	if not HEADBOB_ANIMATION:
		return

	if moving and pawn.is_on_floor():
		var use_headbob_animation : String = "walk"
		match movement_manager._state:
			"normal","crouching":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"

		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true

		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (movement_manager._current_max_speed / movement_manager.base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2))
	else:
		if HEADBOB_ANIMATION.current_animation == "sprint" or HEADBOB_ANIMATION.current_animation == "walk":
			HEADBOB_ANIMATION.speed_scale = 1
			HEADBOB_ANIMATION.play("RESET", 1)
