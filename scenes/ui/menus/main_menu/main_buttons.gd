extends Control


func _ready() -> void:
	$StartGame.pressed.connect(_start_game)
	$Options.pressed.connect(_options)
	$Credits.pressed.connect(_credits)
	$Quit.pressed.connect(_quit)


func  _start_game():
	ViewportManager.viewport_count = 4
	LevelManager.load_level("res://scenes/levels/level_test/level_test.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	MenuManager.close_all_menus()



func  _options():
	pass


func  _credits():
	pass


func  _quit():
	get_tree().quit()
