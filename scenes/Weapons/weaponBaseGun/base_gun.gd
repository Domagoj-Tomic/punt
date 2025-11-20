extends Node3D
class_name BaseGun


signal equipped(equipper)
signal unequipped()


@export var chamber_path: NodePath = NodePath("Mesh/Chamber")
@export var muzzle_path: NodePath = NodePath("Mesh/Chamber/Muzzle")


var owning_character: CharacterBody3D = null
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


@onready var chamber: Marker3D = get_node_or_null(chamber_path) as Marker3D
@onready var muzzle: Marker3D = get_node_or_null(muzzle_path) as Marker3D


func _ready() -> void:
	_refresh_onready_nodes()


func _refresh_onready_nodes() -> void:
	chamber = get_node_or_null(chamber_path) as Marker3D
	muzzle = get_node_or_null(muzzle_path) as Marker3D


func _on_start_firing() -> void:
	pass


func _on_stop_firing() -> void:
	pass


func notify_equipped(equipper: CharacterBody3D) -> void:
	owning_character = equipper
	emit_signal("equipped", equipper)


func notify_unequipped() -> void:
	owning_character = null
	emit_signal("unequipped")


# Safe position helpers (fallback to this node's global position if markers missing)
func get_chamber_global_position() -> Vector3:
	return chamber.global_position if chamber else global_position

func get_muzzle_global_position() -> Vector3:
	return muzzle.global_position if muzzle else global_position
