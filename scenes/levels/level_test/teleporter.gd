extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is Pawn:
		var pawn: Pawn = body
		pawn.global_position = $Destination.global_position
		pawn.Head.global_rotation = $Destination.global_rotation
		pawn.velocity = Vector3.ZERO
