extends Gun
class_name Thumper


@export var max_impulse: float = 100
@export var min_impulse: float = 50
@export var min_charge_percent: float = 0.5
@export var full_charge_time: float = 2.5
@export var full_uncharge_time: float = 1

var _charge_perc: float = 0

@onready var aoe = $Mesh/Chamber/Muzzle/AreaOfEffect


func _ready() -> void:
	super._ready()
	if get_parent().owner is Pawn:
		aoe.add_exception(get_parent().owner)


func _physics_process(delta: float) -> void:
	if is_firing:
		_charge_perc += delta / full_charge_time
	else:
		_charge_perc -= delta / full_uncharge_time
	_charge_perc = clamp(_charge_perc, 0, 1)
	$Container/TextureProgressBar.value = _charge_perc

	$Container/TextureProgressBar.tint_progress = Color(1, 1, 1, _charge_perc)
	$Container/TextureProgressBar.tint_under = Color(1, 1, 1, _charge_perc)


func _on_stop_firing() -> void:
	if _charge_perc < min_charge_percent:
		return

	var chrg: float = (_charge_perc - min_charge_percent) / (1 - min_charge_percent)
	var force: float = min_impulse + max_impulse * chrg
	var force_direction: Vector3 = -global_transform.basis.z

	aoe.force_shapecast_update()
	for i in range(0, aoe.get_collision_count()):
		if aoe.get_collider(i) is CharacterBody3D:
			var body: CharacterBody3D = aoe.get_collider(i)
			body.velocity += force * force_direction
		elif aoe.get_collider(i) is RigidBody3D:
			var body: RigidBody3D = aoe.get_collider(i)
			body.apply_impulse(force * force_direction)

	_charge_perc = 0
