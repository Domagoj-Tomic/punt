@abstract extends Node
class_name Level


@export var player_starts: Array


func _ready() -> void:
	if player_starts.is_empty():
		player_starts = get_children(true).filter(func(child): return child is PlayerStart)

	for ps in player_starts:
		ps.spawn_player(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == 4194332: # F1
				player_starts.pick_random().spawn_player(self)
