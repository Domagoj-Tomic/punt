@abstract extends Node3D
class_name Gun


signal equipped(equipper)
signal unequipped()

@export_file(".tscn") var gui_addon_path: String
@export var muzzle_path: NodePath = NodePath("Mesh/Chamber/Muzzle")


var gui_addon: Control
var owning_character: Pawn = null
var is_firing: bool = false:
	get:
		return is_firing
	set(value):
		if is_firing == value:
			return
		is_firing = value
		if is_firing:
			_on_start_firing()
		else:
			_on_stop_firing()


@onready var muzzle: Marker3D = get_node_or_null(muzzle_path) as Marker3D


func _ready() -> void:
	var err_string = "A gun must have a muzzle set."
	if get_node_or_null(muzzle_path) is not Marker3D: push_error(err_string)

	_refresh_onready_nodes()

	if gui_addon_path:
		gui_addon = load(gui_addon_path).instantiate()


func _refresh_onready_nodes() -> void:
	muzzle = get_node_or_null(muzzle_path) as Marker3D


func _on_start_firing() -> void:
	pass


func _on_stop_firing() -> void:
	pass


func notify_equipped(equipper: Pawn) -> void:
	owning_character = equipper

	await get_tree().process_frame
	if equipper.player_controller and gui_addon:
		equipper.player_controller.Camera.add_child(gui_addon)

	emit_signal("equipped", equipper)


func notify_unequipped() -> void:
	if owning_character.player_controller and gui_addon:
		owning_character.player_controller.Camera.remove_child(gui_addon)
	owning_character = null

	emit_signal("unequipped")


func get_muzzle_global_position() -> Vector3:
	return muzzle.global_position if muzzle else global_position
