@warning_ignore_start("integer_division")
extends Control
class_name ScreenManager

# Essentially a part of the PlayerManager singleton, parented to the root viewport
# in order to avoid errors pertaining to modifying nodes that aren't ready yet.


func _init() -> void:
	name = "ScreenContainer"


func layout_viewports_grid(players: Array[PlayerData]) -> void:
	var debug_panel: PackedScene = load("res://scenes/player/pawn/debug_panel.tscn")
	var viewports: Array[SplitScreenViewport] = []
	for player in players:
		viewports.append(player.subviewport)
	match viewports.size():
		0:
			return
		1:
			viewports[0].subviewport.size = get_tree().root.size
		2:
			viewports[0].subviewport.size.y = get_tree().root.size.y / 2
			viewports[1].subviewport.size.y = get_tree().root.size.y / 2
			viewports[0].subviewport.size.x = get_tree().root.size.x
			viewports[1].subviewport.size.x = get_tree().root.size.x
			viewports[1].position.y = get_tree().root.size.y / 2
		3:
			viewports[0].subviewport.size.y = get_tree().root.size.y / 2
			viewports[1].subviewport.size.y = get_tree().root.size.y / 2
			viewports[2].subviewport.size.y = get_tree().root.size.y / 2
			viewports[0].subviewport.size.x = get_tree().root.size.x / 2
			viewports[1].subviewport.size.x = get_tree().root.size.x / 2
			viewports[2].subviewport.size.x = get_tree().root.size.x
			viewports[1].position.x = get_tree().root.size.x / 2
			viewports[2].position.y = get_tree().root.size.y / 2
		4:
			viewports[0].subviewport.size = get_tree().root.size / 2
			viewports[1].subviewport.size = get_tree().root.size / 2
			viewports[2].subviewport.size = get_tree().root.size / 2
			viewports[3].subviewport.size = get_tree().root.size / 2
			viewports[1].position.x = get_tree().root.size.x / 2
			viewports[2].position.y = get_tree().root.size.y / 2
			viewports[3].position = get_tree().root.size / 2

	for vp in viewports:
		vp.add_child(debug_panel.instantiate())
