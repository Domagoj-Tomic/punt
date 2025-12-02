extends Resource
class_name PlayerData

var NO_DEVICE: int = -1

var player_name: String = ""
var device_id: int = NO_DEVICE
var subviewport: SubViewportContainer = null
var player_controller: PlayerController = null

func _init(name: String, dev_id: int, subvp: SubViewportContainer, pc: PlayerController) -> void:
	player_name = name
	device_id = dev_id
	subviewport = subvp
	player_controller = pc
