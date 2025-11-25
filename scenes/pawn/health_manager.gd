extends Node
class_name PawnHealthManager

signal pawn_died
@export var max_HP: float = 100
var HP: float = 100
var is_dead: bool = false
var pawn: Pawn


func _ready() -> void:
	if get_parent() is Pawn:
		pawn = get_parent()
	else:
		push_error("Direct parent must be a Pawn")


func manage_pawn_health(_delta):
	if HP < 0 and !is_dead:
		kill_pawn()


func damage_pawn_hp(damage: float, can_overheal: bool = false):
	if damage > 0:
		HP -= damage
		if HP > max_HP and can_overheal == false:
			HP = max_HP
	else: print("Damage must be greater than zero")


func heal_pawn_hp(restoration: float):
	if restoration > 0:
		HP += restoration
	else: print("Restoration must be greater than zero")


func kill_pawn():
	HP = 0
	is_dead = true
	pawn.input_enabled = false
	pawn_died.emit()
	get_tree().quit()
