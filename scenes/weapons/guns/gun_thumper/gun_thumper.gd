extends Gun
class_name Thumper


@export var max_impulse: float = 100
@export var min_impulse: float = 50
@export_range(0, 3, 0.1) var precharge_time: float = 1
@export_range(0, 3, 0.1, "or_greater") var main_charge_time: float = 1.5
@export_range(0, 3, 0.1, "or_greater") var uncharge_factor: float = 1

var _precharge_perc: float = 0
var _charge_perc: float = 0

@onready var aoe = $Mesh/Chamber/Muzzle/AreaOfEffect


func _ready() -> void:
	super._ready()
	if get_parent().owner is Pawn:
		aoe.add_exception(get_parent().owner)


func _physics_process(delta: float) -> void:
	if is_firing:
		if _precharge_perc < 1.0:
			_precharge_perc = move_toward(_precharge_perc, 1.0, delta / precharge_time)
			$Container/ChargeBar1.value = _precharge_perc
		elif _charge_perc < 1.0:
			_charge_perc = move_toward(_charge_perc, 1.0, delta / main_charge_time)
			$Container/ChargeBar2.value = _charge_perc
	else:
		if _charge_perc > 0.0:
			_charge_perc = move_toward(_charge_perc, 00., delta * uncharge_factor / main_charge_time)
			$Container/ChargeBar2.value = _charge_perc
		elif _precharge_perc > 0.0:
			_precharge_perc = move_toward(_precharge_perc, 0.0, delta * uncharge_factor / precharge_time)
			$Container/ChargeBar1.value = _precharge_perc





func _on_stop_firing() -> void:
	if _precharge_perc < 1:
		return

	var force: float = min_impulse + max_impulse * _charge_perc
	var force_direction: Vector3 = -global_transform.basis.z

	aoe.force_shapecast_update()
	for i in range(0, aoe.get_collision_count()):
		if aoe.get_collider(i) is CharacterBody3D:
			var body: CharacterBody3D = aoe.get_collider(i)
			body.velocity += force * force_direction
		elif aoe.get_collider(i) is RigidBody3D:
			var body: RigidBody3D = aoe.get_collider(i)
			body.apply_impulse(force * force_direction)

	_precharge_perc = 0
	_charge_perc = 0
	$Container/ChargeBar1.value = _precharge_perc
	$Container/ChargeBar2.value = _charge_perc
