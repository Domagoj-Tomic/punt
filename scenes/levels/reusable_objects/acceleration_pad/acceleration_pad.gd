extends Node3D
class_name AccelerationPad


@export_range(0, 5000, 100, "or_greater") var disable_air_control_milliseconds: int = 5000
@export var impulse: float = 25.0
@export var radius: float = 0.5


func _ready() -> void:
	$Area3D/CollisionShape3D.shape.radius = radius


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Pawn:
		return

	var pawn: Pawn = body
	pawn.velocity = impulse * -global_transform.basis.z


	if disable_air_control_milliseconds > 0:
		pawn.movement_manager.disable_air_control(disable_air_control_milliseconds)
