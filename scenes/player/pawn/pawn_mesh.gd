extends MeshInstance3D


var pawn: Pawn
var head: Node3D


func _ready() -> void:
	if owner is Pawn:
		pawn = owner
	else:
		push_error("Owner must be a Pawn")

	if pawn.get_node("Head"):
		head = pawn.get_node("Head")
	else:
		push_error("Pawn must have a Head")


# We go through the trouble of setting Mesh transform to be top-level and
# setting position and rotation here so we can animate it.
func _physics_process(_delta: float) -> void:
	position = get_parent().position + Vector3(0, 1, 0) # height offset
	rotation = head.rotation
