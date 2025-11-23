extends Node
class_name Level


@export var player_starts: Array[PlayerStart]


func _ready() -> void:
	if player_starts.is_empty():
		player_starts = get_children(true).filter(func(child): return child is PlayerStart)

	player_starts.pick_random().spawn_player(self)
