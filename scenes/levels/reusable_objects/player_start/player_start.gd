extends Node
class_name PlayerStart


var pawn_res: PackedScene = load("res://scenes/player/pawn/pawn.tscn")


func _ready() -> void:
	$Sprite3D.visible = false


func spawn_player(level: Level) -> Pawn:
	var pawn: Pawn = pawn_res.instantiate()
	level.add_child(pawn)
	PlayerManager.assign_pawn_to_player(pawn)
	pawn.position = self.position
	return pawn


func respawn_player(pawn: Pawn):
	pawn.position = self.position
	pawn.velocity = Vector3.ZERO
