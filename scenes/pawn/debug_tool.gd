extends Node
class_name  PawnDebugTool


var pawn: Pawn
var debug_panel: PanelContainer
var movement_manager: PawnMovementManager


func _ready() -> void:
	if self.get_parent() is Pawn:
		pawn = get_parent()
	else:
		push_error("Direct parent must be a Pawn")

	if pawn.get_node("UserInterface/DebugPanel"):
		debug_panel = pawn.get_node("UserInterface/DebugPanel")
	else:
		push_error("No DebugPanel found")

	movement_manager = pawn.get_node("MovementManager")




func update_debug_menu_per_tick():
	if pawn.has_node("UserInterface/DebugPanel"):
		debug_panel.add_property("Speed", snappedf(pawn.get_real_velocity().length(), 0.001), 1)
		debug_panel.add_property("Target speed", movement_manager._current_max_speed, 2)
		var cv : Vector3 = pawn.velocity
		var vd : Array[float] = [
			snappedf(cv.x, 0.001),
			snappedf(cv.y, 0.001),
			snappedf(cv.z, 0.001)
		]
		var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
		debug_panel.add_property("Velocity", readable_velocity, 3)


# Called by Controller to feed per-frame values (controller has Input)
func update_debug_menu_per_frame_from_controller(fps, status):
	debug_panel.add_property("FPS", fps, 0)
	debug_panel.add_property("State", status, 4)
