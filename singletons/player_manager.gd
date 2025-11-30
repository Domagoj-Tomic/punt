extends Node


# Players
var MAX_LOCAL_PLAYERS: int = 4
#var players:


# Viewports
var ss_viewport_res: PackedScene = preload("res://scenes/split_screen_viewport/split_screen_viewport.tscn")
var ss_viewports: Array[SplitScreenViewport]
var viewport_count: int:
	set(value):
		value = clamp(value, 1, MAX_LOCAL_PLAYERS)
		viewport_count = value
		_manage_viewport_count(viewport_count)
var screen_manager := ScreenManager.new()
var viewports_assigned: int = 0


func _ready() -> void:
	get_tree().root.add_child.call_deferred(screen_manager)


func _manage_viewport_count(count: int):
	ss_viewports = []
	#if count == 1:
		#return
	for i in range(0, count):
		ss_viewports.append(ss_viewport_res.instantiate())
		screen_manager.add_child(ss_viewports[i])
	screen_manager.layout_viewports_grid(ss_viewports)


func request_viewport() -> SplitScreenViewport:
	# !!!!!! Gotta make this more robust !!!!!!
	if ss_viewports.size() == 0:
		return null
	if get_viewports_remaining() <= 0:
		return null
	var vp = ss_viewports[viewports_assigned]
	viewports_assigned += 1
	return vp


func get_viewports_remaining() -> int:
	return ss_viewports.size() - viewports_assigned
