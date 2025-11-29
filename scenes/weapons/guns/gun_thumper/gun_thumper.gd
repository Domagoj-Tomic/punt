extends Gun
class_name Thumper


@export var max_impulse: float = 100.0
@export var min_impulse: float = 50.0
@export_range(0, 2000, 100) var disable_air_control_milliseconds: int = 1000
@export_range(0, 3, 0.1) var precharge_time: float = 1.0
@export_range(0, 3, 0.1, "or_greater") var main_charge_time: float = 1.5
@export_range(0, 3, 0.1, "or_greater") var uncharge_factor: float = 1.0

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
			$ChargeBars/ChargeBar1.value = _precharge_perc
		elif _charge_perc < 1.0:
			_charge_perc = move_toward(_charge_perc, 1.0, delta / main_charge_time)
			$ChargeBars/ChargeBar2.value = _charge_perc
	elif _charge_perc == 0.0:
			_precharge_perc = move_toward(_precharge_perc, 0.0, delta * uncharge_factor / precharge_time)
			$ChargeBars/ChargeBar1.value = _precharge_perc





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
			if body is Pawn:
				body.movement_manager.disable_air_control(disable_air_control_milliseconds)
		elif aoe.get_collider(i) is RigidBody3D:
			var body: RigidBody3D = aoe.get_collider(i)
			body.apply_impulse(force * force_direction)

	_precharge_perc = 0
	_charge_perc = 0
	$ChargeBars/ChargeBar1.value = _precharge_perc
	$ChargeBars/ChargeBar2.value = _charge_perc
