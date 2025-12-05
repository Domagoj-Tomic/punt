extends Gun
class_name Cannon


@export var projectileVelocity: float = 50.0
@export var immediate_shapecast_update: bool = false

var cannonball_instance = preload("res://scenes/weapons/projectiles/projectile_cannonball/projectile_cannonball.tscn")

@onready var shapecast: ShapeCast3D = get_node_or_null("Mesh/Muzzle/ShapeCast3D") as ShapeCast3D


func _on_start_firing() -> void:
	fire_projectile()


func fire_projectile() -> void:
	if cannonball_instance == null:
		push_error("%s: cannonball instance is not set" % self)
		return

	var cannonball: Projectile = cannonball_instance.instantiate() as Projectile
	if cannonball == null:
		push_error("%s: failed to instantiate cannonball instance" % self)
		return

	var muzzle_pos: Vector3 = get_muzzle_global_position()
	var aim_dir: Vector3 = -muzzle.global_transform.basis.z

	shapecast.clear_exceptions()
	if owning_character:
		shapecast.add_exception(owning_character)
	shapecast.target_position = shapecast.to_local(muzzle_pos)

	add_child(cannonball)
	cannonball.global_position = _resolve_overlap(aim_dir)
	cannonball.global_basis = global_basis
	cannonball.initiate(owning_character, projectileVelocity)


func _resolve_overlap(aim_dir: Vector3) -> Vector3:
	shapecast.force_shapecast_update()
	var muzzle_pos: Vector3 = get_muzzle_global_position()
	var safe_fraction: float = shapecast.get_closest_collision_safe_fraction()
	var max_back_dist: float = abs(shapecast.target_position.z)
	return muzzle_pos - aim_dir * ( 1 - safe_fraction) * max_back_dist


func _get_projectile_collision_radius(projectile_scene: RigidBody3D) -> float:
	for child in projectile_scene.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is SphereShape3D:
				return shape.radius
			if shape is CapsuleShape3D:
				return shape.radius
	return 0.0
