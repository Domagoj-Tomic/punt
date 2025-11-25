extends Node


var _menu_stack: Array[Control]


func _ready() -> void:
	var menus: Array[Node] = get_tree().get_nodes_in_group("menu")
	for menu  in menus:
		if menu.name == "MainMenu":
			_menu_stack = [menu]
	return_to_main_menu()


func close_all_menus():
	for menu in get_tree().get_nodes_in_group("menu"):
		menu.queue_free()
	_menu_stack = []


func return_to_main_menu():
	close_all_menus()
	_menu_stack = [open_menu("res://scenes/ui/menus/main_menu/main_menu.tscn")]


func open_menu(path: String) -> Control:
	var loaded_menu = load(path)
	var instanced_menu = loaded_menu.instantiate()
	get_tree().root.add_child.call_deferred(instanced_menu)
	return instanced_menu
