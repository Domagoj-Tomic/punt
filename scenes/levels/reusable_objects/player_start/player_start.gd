extends Node
class_name PlayerStart


var pawn_res: PackedScene = load("res://scenes/pawn/pawn.tscn")


func _ready() -> void:
	$Sprite3D.visible = false


func spawn_player(level: Level) -> Pawn:
	var pawn: Pawn = pawn_res.instantiate()
	level.add_child(pawn)
	if ViewportManager.get_viewports_remaining() > 0:
		var _player_controller: PlayerController = PlayerController.new(pawn)
	pawn.position = self.position
	return pawn
