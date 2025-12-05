extends Projectile


@export_range(0, 5000, 100, "or_greater") var disable_air_control_milliseconds: int = 1000
@export var pawn_impulse_multiplier: float = 1.0


func _ready() -> void:
	super._ready()


func _on_body_entered(body: Node) -> void:
	if body is Pawn:
		_knock_back_pawn(body)


func _knock_back_pawn(pawn: Pawn):
	pawn.movement_manager.disable_air_control(disable_air_control_milliseconds)
	pawn.movement_manager.reduce_friction(0.2, 10000)
	pawn.velocity += previous_frame_velocity * pawn_impulse_multiplier
	if pawn.is_on_floor():
		pawn.velocity.y *= -1
