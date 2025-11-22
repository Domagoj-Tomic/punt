extends Node


var current_level: Level
var requested_level_path: String
var loading_progress: Array[float] = [0]
var _is_loading: bool = false


func _process(_delta: float) -> void:
	if _is_loading:
		# If loading is finished
		if ResourceLoader.load_threaded_get_status(requested_level_path, loading_progress) == ResourceLoader.THREAD_LOAD_LOADED:
			var level_instance: Level = ResourceLoader.load_threaded_get(requested_level_path).instantiate()
			get_tree().root.add_child(level_instance)
			current_level = level_instance
			_is_loading = false


func load_level(level_path: String):
	requested_level_path = level_path
	close_current_level()
	ResourceLoader.load_threaded_request(level_path, "", true)
	_is_loading = true


func close_current_level():
	if current_level:
		current_level.queue_free()
		current_level = null
