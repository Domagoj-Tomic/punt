extends Node


# Since the autoloads are the ones that actually handle startup,
# this serves as a dummy entry point.
func _enter_tree() -> void:
	queue_free()
