extends Node


var MAX_LOCAL_PLAYERS: int = 4
var _ss_viewport_res: PackedScene = preload("res://scenes/split_screen_viewport/split_screen_viewport.tscn")
var players: Array[PlayerData]
var player_count: int:
	set(value):
		value = clamp(value, 1, MAX_LOCAL_PLAYERS)
		player_count = value
		_manage_player_count(player_count)
var screen_manager := ScreenManager.new()


func _ready() -> void:
	get_tree().root.add_child.call_deferred(screen_manager)


func assign_pawn_to_player(pawn) -> PlayerData:
	var player = _get_next_unnasigned_player()
	if player == null:
		return null
	var player_controller: PlayerController = PlayerController.new(pawn, player)
	player.player_controller = player_controller
	return player


func _manage_player_count(count: int):
	players = [] # clear the array before any change
	for i in range(0, count):
		var plyr: PlayerData = PlayerData.new("", Input.get_connected_joypads()[i] - 1, _ss_viewport_res.instantiate(), null)
		players.append(plyr)
		screen_manager.add_child(players[i].subviewport)
	screen_manager.layout_viewports_grid(players)


func _get_next_unnasigned_player() -> PlayerData:
	for player in players:
		if player.player_controller == null:
			return player
	return null
