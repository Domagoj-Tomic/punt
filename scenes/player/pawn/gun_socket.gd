extends Node3D
class_name GunSocket


@export var Weapons: Array[Gun]

var NO_WEAPON: int = -1
var selectedGunIndex : int = -1
var input_fire_pressed : bool = false

@onready var pawn: Pawn = owner


func _ready() -> void:
	pawn.pawn_possessed.connect(_debug_add_weapon)

	if not Weapons.is_empty():
		Weapons[0].equip(owner)


func _physics_process(_delta):
	Weapons[selectedGunIndex].is_firing = input_fire_pressed


func  add_weapon(weapon):
	if !Weapons.has(weapon):
		Weapons.append(weapon)


func equip_weapon(weapon : Gun = null):
	unequip_weapon()
	if weapon and Weapons.has(weapon):
		selectedGunIndex = Weapons.find(weapon)
		add_child(Weapons[selectedGunIndex])
		weapon.notify_equipped(owner)
	else:
		return null


func equip_weapon_by_index(index : int = 0):
	if Weapons.get(index):
		unequip_weapon()
		selectedGunIndex = index
		add_child(Weapons[selectedGunIndex])
	else:
		return null


func unequip_weapon():
	if selectedGunIndex != NO_WEAPON:
		remove_child(Weapons[selectedGunIndex])
		selectedGunIndex = NO_WEAPON


func _debug_add_weapon(_controller):
	# Add a weapon for debugging
	var gun1 = load("res://scenes/weapons/guns/gun_cannon/gun_cannon.tscn").instantiate()
	var gun2 = load("res://scenes/weapons/guns/gun_thumper/gun_thumper.tscn").instantiate()
	add_weapon(gun1)
	equip_weapon(gun1)
	add_weapon(gun2)
	equip_weapon(gun2)
