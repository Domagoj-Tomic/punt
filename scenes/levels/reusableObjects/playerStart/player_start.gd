extends Node
class_name PlayerStart


var pawn_res = load("res://scenes/pawn/pawn.tscn")
var player_controller_res = load("res://scenes/playerController/player_controller.tscn")


func _ready() -> void:
	$Sprite3D.visible = false


func spawn_player(level: Level) -> Pawn:
	var player: Pawn = pawn_res.instantiate()
	var player_controller: PlayerController = player_controller_res.instantiate()

	level.add_child(player)
	if not player.has_node("PlayerController"):
		player.add_child(player_controller)
	player.position = self.position
	return player
