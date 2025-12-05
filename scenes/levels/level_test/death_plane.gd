extends Area3D
class_name DeathPlane


var level: Level


func _ready() -> void:
	if get_parent() is Level:
		level = get_parent()


func _on_body_entered(body: Node3D) -> void:
	if body is Pawn:
		if body.has_node("PlayerController"):
			level.respawn(body)
