extends Control
class_name ScreenManager


func _init() -> void:
	name = "ScreenContainer"


@warning_ignore_start("integer_division")
func layout_viewports_grid(viewports: Array[SplitScreenViewport]) -> void:
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
@warning_ignore_restore("integer_division")
