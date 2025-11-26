extends Node3D
class_name GunSocket


@export var Weapons: Array[Gun]

var selectedGunIndex : int = -1
var input_fire_pressed : bool = false


func _ready() -> void:
	assert(owner is Pawn, "Owner of GunSocket must be a Pawn")

	if not Weapons.is_empty():
		Weapons[0].equip(owner)

	######## Add weapon for debugging ########
	#var gun = load("res://scenes/weapons/guns/gun_cannon/gun_cannon.tscn").instantiate()
	var gun = load("res://scenes/weapons/guns/gun_thumper/gun_thumper.tscn").instantiate()
	add_weapon(gun)
	equip_weapon(gun)
	##########################################


func _physics_process(_delta):
	Weapons[selectedGunIndex].is_firing = input_fire_pressed


func  add_weapon(weapon):
	if !Weapons.has(weapon):
		Weapons.append(weapon)


func equip_weapon(weapon : Gun = null):
	if weapon and Weapons.has(weapon):
		selectedGunIndex = Weapons.find(weapon)
		add_child(Weapons[selectedGunIndex])
		weapon.notify_equipped(owner)
	else:
		return null


func equip_weapon_by_index(index : int = 0):
	if Weapons.get(index):
		selectedGunIndex = index
		add_child(Weapons[selectedGunIndex])
	else:
		return null


func unequip_weapon():
	remove_child(Weapons[selectedGunIndex])
	selectedGunIndex = -1
