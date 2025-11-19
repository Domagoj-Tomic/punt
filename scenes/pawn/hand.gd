extends Node3D
class_name Hand

@export var Weapons: Array[Gun]
@onready var socket : Marker3D = $GunSocket_Right
var PAWN : Pawn
var selectedGunIndex : int = -1
var Controls: Dictionary = {
	WEAPON1 = "select_weapon_1",
	WEAPON2 = "select_weapon_2",
	WEAPON3 = "select_weapon_3"
}


func _ready() -> void:
	PAWN = get_parent().get_parent()
	if !Weapons.is_empty():
		Weapons[0].equip(PAWN)
	var gun = load("res://scenes/gun/gun.tscn").instantiate()
	add_weapon(gun)
	equip_weapon(gun)


func _physics_process(_delta):
	if Input.is_action_just_pressed("fire"):
		Weapons[selectedGunIndex].fire_projectile()


func  add_weapon(weapon):
	if !Weapons.has(weapon):
		Weapons.append(weapon)


func equip_weapon(weapon : Gun = null):
	if weapon and Weapons.has(weapon):
		selectedGunIndex = Weapons.find(weapon)
		socket.add_child(Weapons[selectedGunIndex])
		weapon.notify_equipped(owner)
	else:
		return null

func equip_weapon_by_index(index : int = 0):
	if Weapons.get(index):
		selectedGunIndex = index
		socket.add_child(Weapons[selectedGunIndex])
	else:
		return null
		
func unequip_weapon():
	socket.remove_child(Weapons[selectedGunIndex])
	selectedGunIndex = -1
	
