extends Area3D
class_name DeathPlane


func _on_body_entered(body: Node3D) -> void:
	if body is Pawn:
		if body.has_node("PlayerController"): pass
			#get_tree().quit()
