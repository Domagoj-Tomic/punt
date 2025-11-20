extends BaseGun
class_name Cannon

# Projectile scene (weapon-specific)
var projectileInstance = preload("res://scenes/Weapons/projectile/projectile.tscn")

# Optional local ShapeCast (kept as a child node under Mesh/Chamber in the scene)
@onready var shapeCast: ShapeCast3D = get_node_or_null("Mesh/Chamber/ShapeCast3D") as ShapeCast3D

@export var projectileVelocity: float = 50.0
@export var resolve_overlap_with_shapecast: bool = true
@export var immediate_shapecast_update: bool = false

# When equipped, BaseGun.notify_equipped sets owning_character; call super to keep that behaviour.
func notify_equipped(equipper: CharacterBody3D) -> void:
	super.notify_equipped(equipper)

# Default behaviour on trigger start: fire once.
# Override this in subclasses for auto/burst behaviour (e.g. start a timer or enable physics_process).
func _on_start_firing() -> void:
	fire_projectile()

func fire_projectile() -> void:
	if projectileInstance == null:
		push_error("%s: projectileInstance is not set" % self)
		return

	var projectile: RigidBody3D = projectileInstance.instantiate() as RigidBody3D
	if projectile == null:
		push_error("%s: failed to instantiate projectileInstance" % self)
		return

	var chamber_pos: Vector3 = get_chamber_global_position()
	var muzzle_pos: Vector3 = get_muzzle_global_position()
	var aim_dir: Vector3 = (muzzle_pos - chamber_pos).normalized()

	# ShapeCast logic if present in the scene
	if shapeCast:
		shapeCast.clear_exceptions()
		if owning_character:
			shapeCast.add_exception(owning_character)
		shapeCast.target_position = shapeCast.to_local(muzzle_pos)

		if immediate_shapecast_update:
			shapeCast.force_shapecast_update()

	var spawn_pos: Vector3 = muzzle_pos
	if shapeCast and shapeCast.is_colliding():
		spawn_pos = shapeCast.get_collision_point(0)

	if resolve_overlap_with_shapecast:
		spawn_pos = _resolve_overlap(spawn_pos, aim_dir, projectile)

	add_child(projectile)
	projectile.global_position = spawn_pos
	if projectile.has_method("init"):
		projectile.init(owning_character)
	if projectile is RigidBody3D:
		projectile.linear_velocity = aim_dir * projectileVelocity


func _resolve_overlap(initial_pos: Vector3, aim_dir: Vector3, projectile_scene: RigidBody3D) -> Vector3:
	var proj_radius: float = _get_projectile_collision_radius(projectile_scene)
	if proj_radius <= 0.0:
		proj_radius = 0.2

	var max_back_distance: float = 1.0
	# if both chamber and muzzle exist, compute their distance for a reasonable max back distance
	if chamber and muzzle:
		max_back_distance = (muzzle.global_position - chamber.global_position).length()

	var step: float = max(proj_radius * 0.25, 0.01)
	var pos: Vector3 = initial_pos

	var dss = get_world_3d().direct_space_state
	var sphere = SphereShape3D.new()
	sphere.radius = proj_radius

	var collider_exclude: Array = []
	if owning_character:
		collider_exclude.append(owning_character)
	collider_exclude.append(self)

	var back_moved: float = 0.0
	while true:
		var params = PhysicsShapeQueryParameters3D.new()
		params.shape = sphere
		params.transform = Transform3D(Basis(), pos)
		params.exclude = collider_exclude
		var result: Array = dss.intersect_shape(params, 1)
		if result.size() == 0:
			break
		pos -= aim_dir * step
		back_moved += step
		if back_moved >= max_back_distance:
			break
	return pos


func _get_projectile_collision_radius(projectile_scene: RigidBody3D) -> float:
	for child in projectile_scene.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is SphereShape3D:
				return shape.radius
			if shape is CapsuleShape3D:
				return shape.radius
	return 0.0
