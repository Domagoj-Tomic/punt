@abstract extends RigidBody3D
class_name Projectile


@export var lifespan: int = 10

var shooter: Pawn = null
var previous_frame_velocity: Vector3 = Vector3.ZERO


func initiate(shooter_node: Pawn, projectile_speed: float):
	shooter = shooter_node
	_recurse_add_exceptions(shooter)
	linear_velocity = projectile_speed * -global_transform.basis.z
	# workaround for bug with inital speed if already colliding with object
	await get_tree().physics_frame
	linear_velocity = projectile_speed * -global_transform.basis.z


func _ready() -> void:
	_start_kill_self_timer()


func _physics_process(_delta: float) -> void:
	previous_frame_velocity = linear_velocity


func _recurse_add_exceptions(node: Node) -> void:if node is CollisionObject3D:
	add_collision_exception_with(node)
	for child in node.get_children():
		if child is Node:
			_recurse_add_exceptions(child)


func _start_kill_self_timer():
	if lifespan > 0:
		await get_tree().create_timer(lifespan).timeout
		queue_free()
