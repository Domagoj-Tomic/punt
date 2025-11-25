@abstract extends RigidBody3D
class_name Projectile


@export var lifespan: int = 10

var shooter: Pawn = null


func init(shooter_node: Pawn):
	shooter = shooter_node
	_recurse_add_exceptions(shooter)


func _ready() -> void:
	_kill_self()


func _recurse_add_exceptions(node: Node) -> void:if node is CollisionObject3D:
	add_collision_exception_with(node)
	for child in node.get_children():
		if child is Node:
			_recurse_add_exceptions(child)


func _on_body_entered(_body: Node) -> void:
	pass


func _on_body_exited(_body: Node) -> void:
	pass


func _kill_self():
	if lifespan > 0:
		await get_tree().create_timer(lifespan).timeout
		queue_free()
