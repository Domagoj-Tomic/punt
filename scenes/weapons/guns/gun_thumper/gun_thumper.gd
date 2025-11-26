extends Gun
class_name Thumper


@export var max_impulse: float = 20
@export var min_impulse: float = 10
@export var min_charge_perc: float = 0.5
@export var full_charge_time: float = 3
@export var full_uncharge_time: float = 1

var charge_perc: float = 0

@onready var aoe = $Mesh/Chamber/Muzzle/AreaOfEffect


func _ready() -> void:
	super._ready()
	if get_parent().owner is Pawn:
		aoe.add_exception(get_parent().owner)


func _physics_process(delta: float) -> void:
	if is_firing:
		charge_perc += delta / full_charge_time
	else:
		charge_perc -= delta / full_uncharge_time
	charge_perc = clamp(charge_perc, 0, 1)
	$TextureProgressBar.value = charge_perc


func _on_stop_firing() -> void:
	aoe.force_shapecast_update()
	for i in range(0, aoe.get_collision_count()):
		if aoe.get_collider(i) is CharacterBody3D:
			var body: CharacterBody3D = aoe.get_collider(i)
			body.velocity += global_transform.basis.x
		elif aoe.get_collider(i) is RigidBody3D:
			var body: RigidBody3D = aoe.get_collider(i)
			body.apply_impulse(-global_transform.basis.z * 100)
