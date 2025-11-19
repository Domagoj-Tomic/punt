extends RigidBody3D
class_name Projectile

var shooter: Pawn = null

func init(shooter_node: Pawn):
	shooter = shooter_node
	call_deferred("_add_shooter_exceptions")

func _add_shooter_exceptions() -> void:
	if not shooter:
		return
	_recurse_add_exceptions(shooter)

func _recurse_add_exceptions(node: Node) -> void:
	if node == self:
		return
	if node is CollisionObject3D:
		add_collision_exception_with(node)
	for child in node.get_children():
		if child is Node:
			_recurse_add_exceptions(child)


func _on_body_entered(_body: Node) -> void:
	pass


func _on_body_exited(_body: Node) -> void:
	pass
